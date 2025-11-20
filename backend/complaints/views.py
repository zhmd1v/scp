from rest_framework import generics, permissions
from rest_framework.exceptions import PermissionDenied
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import Complaint, Incident
from .serializers import ComplaintSerializer, IncidentSerializer
from accounts.models import ConsumerProfile, SupplierStaff, SupplierProfile
from accounts.models import ConsumerSupplierLink  # если его нет тут, добавь импорт из accounts.models
from orders.models import Order


class ComplaintListCreateView(generics.ListCreateAPIView):
    """
    GET:
      - consumer: свои жалобы
      - supplier staff: жалобы на своего поставщика
      - superuser: все жалобы
    POST:
      - только consumer (user с ConsumerProfile)
    """
    serializer_class = ComplaintSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user

        base_qs = Complaint.objects.select_related(
            'consumer', 'supplier', 'order'
        ).order_by('-created_at')

        # суперюзер
        if user.is_superuser:
            return base_qs

        # staff поставщика
        staff_links = SupplierStaff.objects.filter(user=user).values_list('supplier_id', flat=True)
        if staff_links:
            return base_qs.filter(supplier_id__in=staff_links)

        # consumer
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            # не consumer и не staff — ничего не видит
            return Complaint.objects.none()

        return base_qs.filter(consumer=consumer_profile)

    def perform_create(self, serializer):
        """
        Создать жалобу от имени текущего consumer.
        Проверяем наличие accepted-линка, если указан supplier или order.
        """
        user = self.request.user

        # 1) проверяем, что есть ConsumerProfile
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            raise PermissionDenied("Только потребители могут создавать жалобы.")

        supplier = serializer.validated_data.get('supplier')
        order = serializer.validated_data.get('order')

        # если жалоба привязана к заказу — берем supplier из заказа
        if order and not supplier:
            supplier = order.supplier

        if not supplier:
            raise PermissionDenied("Не указан поставщик для жалобы.")

        # 2) проверяем, есть ли accepted-линк между consumer и этим поставщиком
        from accounts.models import ConsumerSupplierLink  # локальный импорт, чтобы избежать циклов

        has_link = ConsumerSupplierLink.objects.filter(
            consumer=consumer_profile,
            supplier=supplier,
            status='accepted',
        ).exists()

        if not has_link:
            raise PermissionDenied("Нет одобренной связи с этим поставщиком, жалоба не может быть создана.")

        serializer.save(
            consumer=consumer_profile,
            supplier=supplier,
            created_by=user,
            status='open',
        )


class ComplaintDetailView(generics.RetrieveAPIView):
    """
    Детали одной жалобы.
    Доступ:
      - consumer (только свои)
      - staff поставщика (жалобы на своего поставщика)
      - superuser
    """
    serializer_class = ComplaintSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = 'pk'

    def get_queryset(self):
        user = self.request.user
        base_qs = Complaint.objects.select_related('consumer', 'supplier', 'order')

        if user.is_superuser:
            return base_qs

        staff_links = SupplierStaff.objects.filter(user=user).values_list('supplier_id', flat=True)
        if staff_links:
            return base_qs.filter(supplier_id__in=staff_links)

        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            return Complaint.objects.none()

        return base_qs.filter(consumer=consumer_profile)


class ComplaintStatusUpdateView(APIView):
    """
    Обновление статуса жалобы поставщиком (или суперюзером).
    Ожидает в теле { "status": "in_progress" / "resolved" / "closed" }.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        user = request.user

        try:
            complaint = Complaint.objects.select_related('supplier').get(pk=pk)
        except Complaint.DoesNotExist:
            return Response({"detail": "Complaint not found."}, status=status.HTTP_404_NOT_FOUND)

        # проверяем, что user — staff этого поставщика или суперюзер
        from accounts.models import SupplierStaff

        staff_links = SupplierStaff.objects.filter(user=user, supplier=complaint.supplier)
        if not staff_links.exists() and not user.is_superuser:
            return Response(
                {"detail": "Вы не можете менять статус жалобы для этого поставщика."},
                status=status.HTTP_403_FORBIDDEN
            )

        new_status = request.data.get('status')
        allowed_statuses = ['open', 'in_progress', 'resolved', 'closed']

        if new_status not in allowed_statuses:
            return Response(
                {"detail": f"Недопустимый статус. Разрешены: {allowed_statuses}"},
                status=status.HTTP_400_BAD_REQUEST
            )

        old_status = complaint.status
        complaint.status = new_status
        complaint.assigned_to = user  # можно считать, что тот, кто меняет статус, "ведёт" жалобу
        complaint.save()

        return Response(
            {
                "id": complaint.id,
                "old_status": old_status,
                "new_status": complaint.status,
            },
            status=status.HTTP_200_OK
        )

class IncidentListCreateView(generics.ListCreateAPIView):
    """
    GET:
      - staff поставщика: инциденты своего поставщика
      - superuser: все
      - consumer: инциденты по его заказам (опционально, для прозрачности)
    POST:
      - только staff поставщика / superuser
    """
    serializer_class = IncidentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        base_qs = Incident.objects.select_related('supplier', 'order', 'complaint').order_by('-created_at')

        if user.is_superuser:
            return base_qs

        # staff поставщика
        staff_supplier_ids = SupplierStaff.objects.filter(
            user=user
        ).values_list('supplier_id', flat=True)
        if staff_supplier_ids:
            return base_qs.filter(supplier_id__in=staff_supplier_ids)

        # consumer – инциденты по его заказам
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            return Incident.objects.none()

        return base_qs.filter(order__consumer=consumer_profile)

    def perform_create(self, serializer):
        user = self.request.user

        # только staff или суперюзер
        staff_links = SupplierStaff.objects.filter(user=user)
        if not staff_links.exists() and not user.is_superuser:
            raise PermissionDenied("Только сотрудники поставщика или админ могут создавать инциденты.")

        supplier = serializer.validated_data.get('supplier')
        order = serializer.validated_data.get('order')

        # если есть order, то supplier должен совпадать
        if order and supplier and order.supplier != supplier:
            raise PermissionDenied("Поставщик инцидента должен совпадать с поставщиком заказа.")

        if order and not supplier:
            supplier = order.supplier

        if not supplier:
            raise PermissionDenied("Не указан поставщик для инцидента.")

        serializer.save(
            supplier=supplier,
            created_by=user,
            status='open',
        )

class IncidentDetailView(generics.RetrieveAPIView):
    """
    Детали одного инцидента.
    Те же правила доступа, что и в списке.
    """
    serializer_class = IncidentSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = 'pk'

    def get_queryset(self):
        user = self.request.user
        base_qs = Incident.objects.select_related('supplier', 'order', 'complaint')

        if user.is_superuser:
            return base_qs

        staff_supplier_ids = SupplierStaff.objects.filter(
            user=user
        ).values_list('supplier_id', flat=True)
        if staff_supplier_ids:
            return base_qs.filter(supplier_id__in=staff_supplier_ids)

        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            return Incident.objects.none()

        return base_qs.filter(order__consumer=consumer_profile)

class IncidentStatusUpdateView(APIView):
    """
    Обновление статуса инцидента (staff поставщика или superuser).
    Ожидает { "status": "investigating" / "mitigated" / "closed" / "open" }.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        user = request.user

        try:
            incident = Incident.objects.select_related('supplier').get(pk=pk)
        except Incident.DoesNotExist:
            return Response({"detail": "Incident not found."}, status=status.HTTP_404_NOT_FOUND)

        staff_links = SupplierStaff.objects.filter(user=user, supplier=incident.supplier)
        if not staff_links.exists() and not user.is_superuser:
            return Response(
                {"detail": "Вы не можете менять статус инцидента для этого поставщика."},
                status=status.HTTP_403_FORBIDDEN
            )

        new_status = request.data.get('status')
        allowed_statuses = ['open', 'investigating', 'mitigated', 'closed']

        if new_status not in allowed_statuses:
            return Response(
                {"detail": f"Недопустимый статус. Разрешены: {allowed_statuses}"},
                status=status.HTTP_400_BAD_REQUEST
            )

        old_status = incident.status
        incident.status = new_status
        incident.save()

        return Response(
            {
                "id": incident.id,
                "old_status": old_status,
                "new_status": incident.status,
            },
            status=status.HTTP_200_OK
        )
