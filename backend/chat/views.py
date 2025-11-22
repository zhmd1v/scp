from rest_framework import generics, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.exceptions import PermissionDenied

from .models import Conversation, Message
from .serializers import ConversationSerializer, MessageSerializer
from accounts.models import ConsumerProfile, SupplierStaff, SupplierProfile
from accounts.models import ConsumerSupplierLink
from orders.models import Order


class ConversationListCreateView(generics.ListCreateAPIView):
    """
    GET:
      - consumer: диалоги, где он участник
      - supplier staff: диалоги своего поставщика
      - superuser: все
    POST:
      - consumer: создаёт диалог с поставщиком
      - supplier staff: может создать диалог с consumer или внутренний
    """
    serializer_class = ConversationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        base_qs = Conversation.objects.select_related(
            'supplier', 'consumer', 'order'
        ).order_by('-updated_at')

        if user.is_superuser:
            return base_qs

        # staff поставщика
        staff_supplier_ids = SupplierStaff.objects.filter(
            user=user
        ).values_list('supplier_id', flat=True)
        
        if staff_supplier_ids:
            qs = base_qs.filter(supplier_id__in=staff_supplier_ids)
            
            # If user is sales rep, only show assigned conversations
            if user.user_type == 'supplier_sales':
                qs = qs.filter(assigned_staff__user=user)
                
            return qs

        # consumer
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            return Conversation.objects.none()

        return base_qs.filter(consumer=consumer_profile)

    def perform_create(self, serializer):
        user = self.request.user

        # consumer?
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            consumer_profile = None

        # staff?
        staff_links = SupplierStaff.objects.filter(user=user)
        is_staff = staff_links.exists()

        supplier = serializer.validated_data.get('supplier')
        conversation_type = serializer.validated_data.get('conversation_type', 'supplier_consumer')
        order = serializer.validated_data.get('order')

        if not supplier:
            raise PermissionDenied("Нужно указать supplier для диалога.")

        # если указан order – проверяем, что он от этого supplier
        if order and order.supplier != supplier:
            raise PermissionDenied("Поставщик диалога должен совпадать с поставщиком заказа.")

        # consumer создаёт supplier_consumer диалог
        if consumer_profile and not is_staff:
            # проверяем accepted-линк
            has_link = ConsumerSupplierLink.objects.filter(
                consumer=consumer_profile,
                supplier=supplier,
                status='accepted',
            ).exists()
            if not has_link:
                raise PermissionDenied("Нет одобренной связи с этим поставщиком, нельзя открыть чат.")

            # Routing logic: Assign to sales rep
            # 1. Check if Consumer is assigned to a specific rep
            assigned_staff = None
            try:
                link = ConsumerSupplierLink.objects.get(
                    consumer=consumer_profile,
                    supplier=supplier,
                    status='accepted'
                )
                if link.assigned_sales_rep:
                    assigned_staff = link.assigned_sales_rep
            except ConsumerSupplierLink.DoesNotExist:
                pass # Should be caught by has_link check above, but safe to ignore here

            # 2. If no assigned rep, fallback to load balancing (least active chats)
            if not assigned_staff:
                from django.db.models import Count
                sales_reps = SupplierStaff.objects.filter(
                    supplier=supplier,
                    user__user_type='supplier_sales'
                ).annotate(
                    active_chats=Count('assigned_conversations')
                ).order_by('active_chats')
                assigned_staff = sales_reps.first()

            serializer.save(
                consumer=consumer_profile,
                conversation_type='supplier_consumer',
                created_by=user,
                assigned_staff=assigned_staff
            )
            return

        # staff поставщика
        if is_staff:
            # если тип supplier_consumer – нужен consumer
            consumer = serializer.validated_data.get('consumer', None)
            if conversation_type == 'supplier_consumer':
                if not consumer:
                    raise PermissionDenied("Для supplier_consumer диалога нужно указать consumer.")
            serializer.save(created_by=user)
            return

        raise PermissionDenied("Этот пользователь не может создавать диалоги.")

class MessageListCreateView(generics.ListCreateAPIView):
    """
    GET /api/chat/conversations/<conversation_id>/messages/:
        все сообщения в диалоге (если пользователь – участник)
    POST:
        отправить новое сообщение в диалог
    """
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_conversation(self):
        conv_id = self.kwargs.get('conversation_id')
        try:
            conv = Conversation.objects.select_related('supplier', 'consumer').get(pk=conv_id)
        except Conversation.DoesNotExist:
            raise PermissionDenied("Conversation not found.")
        return conv

    def check_participant(self, user, conv: Conversation):
        if user.is_superuser:
            return

        # staff поставщика
        if SupplierStaff.objects.filter(user=user, supplier=conv.supplier).exists():
            return

        # consumer
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            raise PermissionDenied("Вы не участник этого диалога.")

        if conv.consumer != consumer_profile:
            raise PermissionDenied("Вы не участник этого диалога.")

    def get_queryset(self):
        user = self.request.user
        conv = self.get_conversation()
        self.check_participant(user, conv)
        return conv.messages.select_related('sender').order_by('sent_at')

    def perform_create(self, serializer):
        user = self.request.user
        conv = self.get_conversation()
        self.check_participant(user, conv)

        serializer.save(
            conversation=conv,
            sender=user,
        )
        # обновляем updated_at у диалога
        conv.save()

class MarkConversationReadView(APIView):
    """
    Пометить все входящие сообщения в диалоге как прочитанные для текущего пользователя.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, conversation_id):
        user = request.user
        try:
            conv = Conversation.objects.select_related('supplier', 'consumer').get(pk=conversation_id)
        except Conversation.DoesNotExist:
            return Response({"detail": "Conversation not found."}, status=status.HTTP_404_NOT_FOUND)

        # проверяем участие (та же логика, что выше)
        # переиспользуем кусочек из MessageListCreateView
        if not user.is_superuser:
            if SupplierStaff.objects.filter(user=user, supplier=conv.supplier).exists():
                pass
            else:
                try:
                    consumer_profile = ConsumerProfile.objects.get(user=user)
                except ConsumerProfile.DoesNotExist:
                    return Response({"detail": "Вы не участник этого диалога."},
                                    status=status.HTTP_403_FORBIDDEN)
                if conv.consumer != consumer_profile:
                    return Response({"detail": "Вы не участник этого диалога."},
                                    status=status.HTTP_403_FORBIDDEN)

        # помечаем сообщения других пользователей как прочитанные
        updated = Message.objects.filter(
            conversation=conv,
            is_read=False
        ).exclude(sender=user).update(is_read=True)

        return Response(
            {"detail": f"{updated} messages marked as read."},
            status=status.HTTP_200_OK
        )
