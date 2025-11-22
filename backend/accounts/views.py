from django.shortcuts import render
from django.contrib.auth import get_user_model
from rest_framework import generics, permissions, status
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.decorators import api_view, permission_classes
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import ConsumerProfile, ConsumerSupplierLink, SupplierProfile, SupplierStaff
from .serializers import (
    ConsumerProfileSerializer,
    ConsumerRegisterSerializer,
    ConsumerSupplierLinkSerializer,
    SupplierProfileSerializer,
    UserSerializer,
)


# Create your views here.
@api_view(['GET'])
def api_health(request):
    """
    Простой endpoint, чтобы проверить, что API работает.
    """
    return Response({
        "status": "ok",
        "message": "SCP backend API is running"
    })

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def me(request):
    """
    Вернуть информацию о текущем залогиненном пользователе.
    """
    serializer = UserSerializer(request.user)
    return Response(serializer.data)


class SupplierListView(generics.ListAPIView):
    """
    Список всех верифицированных поставщиков.
    Для теста: ты будешь создавать SupplierProfile через админку.
    """
    queryset = SupplierProfile.objects.filter(is_verified=True)
    serializer_class = SupplierProfileSerializer
    permission_classes = [permissions.AllowAny]  # пока открыто всем

class ConsumerSupplierLinkListCreateView(generics.ListCreateAPIView):
    """
    GET: список линков текущего пользователя.
    POST: создать запрос на линк (consumer -> supplier).
    URL: /api/accounts/links/
    """
    serializer_class = ConsumerSupplierLinkSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user

        # если пользователь — consumer
        if hasattr(user, 'consumer_profile'):
            return ConsumerSupplierLink.objects.filter(
                consumer=user.consumer_profile
            ).select_related('consumer', 'supplier')

        # если пользователь — сотрудник поставщика (Owner/Manager/Sales)
        staff_links = SupplierStaff.objects.filter(user=user).select_related('supplier')
        supplier_ids = [s.supplier_id for s in staff_links]
        if supplier_ids:
            return ConsumerSupplierLink.objects.filter(
                supplier_id__in=supplier_ids
            ).select_related('consumer', 'supplier')

        # если суперюзер / админ — можно всё
        if user.is_superuser:
            return ConsumerSupplierLink.objects.all().select_related('consumer', 'supplier')

        # по умолчанию — пусто
        return ConsumerSupplierLink.objects.none()

    def perform_create(self, serializer):
        user = self.request.user

        # 1) ищем ConsumerProfile по user
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            raise ValidationError("У текущего пользователя нет ConsumerProfile, он не может создавать запросы.")

        # 2) можно дополнительно проверить, что это именно consumer
        # если в User есть поле user_type:
        # if user.user_type != 'consumer':
        #     raise ValidationError("Только потребители могут отправлять запрос на линк.")

        supplier = serializer.validated_data.get('supplier')

        # 3) проверяем, нет ли уже активного/ожидающего линка
        existing = ConsumerSupplierLink.objects.filter(
            consumer=consumer_profile,
            supplier=supplier
        ).exclude(status='rejected')  # rejected считаем “историей”

        if existing.exists():
            raise ValidationError("Линк между этим потребителем и поставщиком уже существует или в ожидании.")

        # 4) создаём линк со статусом по умолчанию (обычно pending)
        serializer.save(consumer=consumer_profile)

class BaseLinkActionView(APIView):
    """
    Базовый класс для действий над линком (approve/reject/block).
    Проверяет, что текущий пользователь связан с поставщиком.
    """
    permission_classes = [permissions.IsAuthenticated]
    new_status = None  # переопределяется в наследниках

    def post(self, request, pk):
        # 1) ищем линк
        try:
            link = ConsumerSupplierLink.objects.select_related('supplier').get(pk=pk)
        except ConsumerSupplierLink.DoesNotExist:
            return Response({"detail": "Link not found."}, status=status.HTTP_404_NOT_FOUND)

        user = request.user

        # 2) проверяем, что пользователь — staff этого поставщика
        staff_links = SupplierStaff.objects.filter(user=user, supplier=link.supplier)
        if not staff_links.exists() and not user.is_superuser:
            return Response(
                {"detail": "Вы не связаны с этим поставщиком и не можете менять статус линка."},
                status=status.HTTP_403_FORBIDDEN
            )

        # 3) меняем статус
        if self.new_status is None:
            return Response({"detail": "Invalid action."}, status=status.HTTP_400_BAD_REQUEST)

        old_status = link.status
        link.status = self.new_status
        link.save()

        return Response(
            {
                "id": link.id,
                "old_status": old_status,
                "new_status": link.status,
                "consumer": link.consumer_id,
                "supplier": link.supplier_id,
            },
            status=status.HTTP_200_OK
        )


class ApproveLinkView(BaseLinkActionView):
    """
    Поставщик одобряет линк (consumer получает доступ к каталогу).
    """
    new_status = 'accepted'

    def post(self, request, pk):
        response = super().post(request, pk)
        if response.status_code == status.HTTP_200_OK:
            # Auto-assign sales rep if not already assigned
            try:
                link = ConsumerSupplierLink.objects.get(pk=pk)
                if not link.assigned_sales_rep:
                    from django.db.models import Count
                    # Find sales rep with least assigned consumers, then least conversations
                    sales_reps = SupplierStaff.objects.filter(
                        supplier=link.supplier,
                        user__user_type='supplier_sales'
                    ).annotate(
                        num_consumers=Count('assigned_consumers'),
                        num_conversations=Count('assigned_conversations')
                    ).order_by('num_consumers', 'num_conversations')

                    best_rep = sales_reps.first()
                    if best_rep:
                        link.assigned_sales_rep = best_rep
                        link.save()
            except Exception as e:
                # Log error but don't fail the request
                print(f"Error assigning sales rep: {e}")
        return response


class RejectLinkView(BaseLinkActionView):
    """
    Поставщик отклоняет запрос.
    """
    new_status = 'rejected'


class BlockLinkView(BaseLinkActionView):
    """
    Поставщик блокирует потребителя (например, после инцидентов).
    """
    new_status = 'blocked'


class ConsumerRegisterView(generics.CreateAPIView):
    """
    POST /api/accounts/register/
    Регистрация нового consumer-пользователя (ресторан/отель).
    Возвращает user + token + consumer_profile.
    """
    serializer_class = ConsumerRegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # создаём или берём существующий токен
        token, _ = Token.objects.get_or_create(user=user)

        consumer_profile = ConsumerProfile.objects.get(user=user)

        data = {
            "user_id": user.id,
            "username": user.username,
            "email": user.email,
            "token": token.key,
            "consumer_profile": {
                "id": consumer_profile.id,
                "business_name": consumer_profile.business_name,
                "business_type": consumer_profile.business_type,
                "city": consumer_profile.city,
                "address": getattr(consumer_profile, "address", ""),
            },
        }

        return Response(data, status=status.HTTP_201_CREATED)


class EmailOrUsernameAuthTokenView(ObtainAuthToken):
    """
    Custom token view that lets users authenticate with either username or email.
    Since our User model uses email as USERNAME_FIELD, this view properly handles authentication.
    """

    def post(self, request, *args, **kwargs):
        identifier = request.data.get("username") or request.data.get("email")
        password = request.data.get("password")

        if not identifier or not password:
            return Response(
                {"detail": "Both username/email and password are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        UserModel = get_user_model()
        user = None

        # Try matching by email first (this is our USERNAME_FIELD)
        if "@" in identifier:
            try:
                user = UserModel.objects.get(email__iexact=identifier.strip())
            except UserModel.DoesNotExist:
                pass
        
        # Fall back to username lookup
        if user is None:
            try:
                user = UserModel.objects.get(username__iexact=identifier.strip())
            except UserModel.DoesNotExist:
                return Response(
                    {"detail": "Unable to log in with provided credentials."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        # Check password
        if not user.check_password(password):
            return Response(
                {"detail": "Unable to log in with provided credentials."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # User authenticated successfully, return token
        token, _ = Token.objects.get_or_create(user=user)
        
        return Response({
            "token": token.key,
            "user_id": user.id,
            "email": user.email,
            "username": user.username,
            "user_type": user.user_type,
        })


class ConsumerProfileUpdateView(generics.UpdateAPIView):
    """
    Update consumer profile information.
    """
    serializer_class = ConsumerProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        try:
            return ConsumerProfile.objects.get(user=self.request.user)
        except ConsumerProfile.DoesNotExist:
            raise ValidationError("Consumer profile not found for current user.")

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        
        # Also update user fields if provided
        user = request.user
        user_updated = False
        if 'username' in request.data:
            user.username = request.data['username']
            user_updated = True
        if 'phone' in request.data:
            user.phone = request.data['phone']
            user_updated = True
        if user_updated:
            user.save()
        
        return Response(serializer.data)


class UserProfileUpdateView(APIView):
    """
    Update user information (username, phone, etc.)
    """
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request):
        user = request.user
        updated = False
        
        if 'username' in request.data:
            user.username = request.data['username']
            updated = True
        if 'phone' in request.data:
            user.phone = request.data['phone']
            updated = True
        if 'first_name' in request.data:
            user.first_name = request.data['first_name']
            updated = True
        if 'last_name' in request.data:
            user.last_name = request.data['last_name']
            updated = True
            
        if updated:
            user.save()
            
        return Response({
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "phone": user.phone,
            "first_name": user.first_name,
            "last_name": user.last_name,
        })


class BackfillAssignmentsView(APIView):
    """
    Temporary endpoint to backfill assigned_sales_rep for existing links.
    """
    permission_classes = [permissions.AllowAny] # For ease of use, but should be secured in prod

    def get(self, request):
        from django.db.models import Count
        links = ConsumerSupplierLink.objects.filter(status='accepted', assigned_sales_rep__isnull=True)
        count = 0
        log = []
        
        for link in links:
            # Find sales reps for this supplier
            sales_reps = SupplierStaff.objects.filter(
                supplier=link.supplier,
                user__user_type='supplier_sales'
            ).annotate(
                num_consumers=Count('assigned_consumers'),
                num_conversations=Count('assigned_conversations')
            ).order_by('num_consumers', 'num_conversations')
            
            best_rep = sales_reps.first()
            if best_rep:
                link.assigned_sales_rep = best_rep
                link.save()
                count += 1
                log.append(f"Assigned {link.consumer} to {best_rep.user.username}")
            else:
                log.append(f"No sales rep found for supplier {link.supplier}")
                
        return Response({
            "status": "ok",
            "updated_count": count,
            "log": log
        })