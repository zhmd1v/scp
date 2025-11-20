from rest_framework import generics, permissions
from rest_framework.exceptions import PermissionDenied
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .models import Order, OrderItem, OrderStatusHistory
from .serializers import OrderSerializer

from accounts.models import (
    ConsumerProfile,
    SupplierStaff,
    ConsumerSupplierLink,
)
from catalog.models import Product



class OrderListCreateView(generics.ListCreateAPIView):
    """
    GET: список заказов текущего пользователя:
         - superuser: все заказы
         - supplier staff: заказы своего поставщика(ов)
         - consumer: только свои заказы
    POST: создать новый заказ (только consumer с accepted-линком к поставщику).
    """
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user

        base_qs = (
            Order.objects
            .select_related('consumer', 'supplier', 'delivery_option')
            .prefetch_related('items')
            .order_by('-created_at')
        )

        # 1) суперюзер видит всё
        if user.is_superuser:
            return base_qs

        # 2) staff поставщика
        staff_links = SupplierStaff.objects.filter(user=user).values_list('supplier_id', flat=True)
        if staff_links:
            return base_qs.filter(supplier_id__in=staff_links)

        # 3) consumer
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            # ни staff, ни consumer – ничего не видит
            return Order.objects.none()

        return base_qs.filter(consumer=consumer_profile)

    def perform_create(self, serializer):
        """
        Создать заказ от имени текущего consumer.
        Проверяем наличие accepted-линка к выбранному поставщику.
        """
        user = self.request.user

        # 1) проверяем, что у пользователя есть ConsumerProfile
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            raise PermissionDenied("Только пользователи с ConsumerProfile могут создавать заказы.")

        supplier = serializer.validated_data.get('supplier')

        if supplier is None:
            raise PermissionDenied("Не указан поставщик для заказа.")

        # 2) проверяем accepted-линк между consumer и этим поставщиком
        has_link = ConsumerSupplierLink.objects.filter(
            consumer=consumer_profile,
            supplier=supplier,
            status='accepted',
        ).exists()

        if not has_link:
            raise PermissionDenied("Нет одобренной связи с этим поставщиком. Сначала запросите линк.")

        # 3) сохраняем заказ, передаём consumer в serializer
        serializer.save(consumer=consumer_profile)


class OrderDetailView(generics.RetrieveAPIView):
    """
    Получить один заказ по id.
    """
    queryset = Order.objects.all().select_related('consumer', 'supplier', 'delivery_option').prefetch_related('items')
    serializer_class = OrderSerializer
    permission_classes = [permissions.AllowAny]
    lookup_field = 'pk'

class MyConsumerOrdersView(generics.ListAPIView):
    """
    Список заказов текущего пользователя как потребителя (ресторан/отель).
    URL: /api/orders/my/consumer/
    """
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return (
            Order.objects
            .filter(consumer__user=user)
            .select_related('consumer', 'supplier', 'delivery_option')
            .prefetch_related('items')
            .order_by('-created_at')
        )


class MySupplierOrdersView(generics.ListAPIView):
    """
    Список заказов для поставщика, с которым связан текущий пользователь (через SupplierStaff).
    URL: /api/orders/my/supplier/
    """
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user

        staff_links = SupplierStaff.objects.filter(user=user).select_related('supplier')
        supplier_ids = [s.supplier_id for s in staff_links]

        return (
            Order.objects
            .filter(supplier_id__in=supplier_ids)
            .select_related('consumer', 'supplier', 'delivery_option')
            .prefetch_related('items')
            .order_by('-created_at')
        )

class BaseOrderStatusView(APIView):
    """
    Базовый класс для изменения статуса заказа.
    Потом от него наследуются confirm/reject/cancel.
    """
    permission_classes = [permissions.IsAuthenticated]
    new_status = None  # переопределяем в наследниках

    def post(self, request, pk):
        # ищем заказ
        try:
            order = Order.objects.select_related('supplier', 'consumer').prefetch_related('items').get(pk=pk)
        except Order.DoesNotExist:
            return Response({"detail": "Order not found."}, status=status.HTTP_404_NOT_FOUND)

        if self.new_status is None:
            return Response({"detail": "Invalid action."}, status=status.HTTP_400_BAD_REQUEST)

        # вызываем конкретную логику в наследнике
        return self.handle_order(request, order)

    def handle_order(self, request, order):
        raise NotImplementedError("handle_order must be implemented in subclasses")
    

class SupplierConfirmOrderView(BaseOrderStatusView):
    """
    Подтверждение заказа поставщиком.
    - Доступ: только staff этого поставщика или superuser.
    - Проверяет статус (например, должен быть 'pending').
    - Обновляет склад: вычитает quantity из Product.stock_quantity.
    """
    new_status = 'confirmed'

    def handle_order(self, request, order):
        user = request.user

        # проверяем, что user привязан к этому supplier
        staff_links = SupplierStaff.objects.filter(user=user, supplier=order.supplier)
        if not staff_links.exists() and not user.is_superuser:
            return Response(
                {"detail": "Вы не можете подтверждать заказы для этого поставщика."},
                status=status.HTTP_403_FORBIDDEN
            )

        # допускаем подтверждение только из 'pending'
        if order.status != 'pending':
            return Response(
                {"detail": f"Нельзя подтвердить заказ в статусе '{order.status}'."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # проверяем наличие товаров на складе
        items = order.items.all()
        insufficient = []
        for item in items:
            product = item.product
            if product.stock_quantity is not None and product.stock_quantity < item.quantity:
                insufficient.append({
                    "product_id": product.id,
                    "name": product.name,
                    "available": str(product.stock_quantity),
                    "required": str(item.quantity),
                })

        if insufficient:
            return Response(
                {
                    "detail": "Недостаточно товара на складе для некоторых позиций.",
                    "items": insufficient,
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        # всё ок – вычитаем количество из склада
        for item in items:
            product = item.product
            if product.stock_quantity is not None:
                product.stock_quantity = product.stock_quantity - item.quantity
                product.save()

        old_status = order.status
        order.status = self.new_status
        order.save()

        OrderStatusHistory.objects.create(
            order=order,
            old_status=old_status,
            new_status=order.status,
            changed_by=user,
            comment='Order confirmed by supplier via API',
        )

        return Response(
            {
                "id": order.id,
                "old_status": old_status,
                "new_status": order.status,
            },
            status=status.HTTP_200_OK
        )

class SupplierRejectOrderView(BaseOrderStatusView):
    """
    Отклонение заказа поставщиком.
    """
    new_status = 'rejected'

    def handle_order(self, request, order):
        user = request.user

        staff_links = SupplierStaff.objects.filter(user=user, supplier=order.supplier)
        if not staff_links.exists() and not user.is_superuser:
            return Response(
                {"detail": "Вы не можете отклонять заказы для этого поставщика."},
                status=status.HTTP_403_FORBIDDEN
            )

        if order.status != 'pending':
            return Response(
                {"detail": f"Нельзя отклонить заказ в статусе '{order.status}'."},
                status=status.HTTP_400_BAD_REQUEST
            )

        old_status = order.status
        order.status = self.new_status
        order.save()

        OrderStatusHistory.objects.create(
            order=order,
            old_status=old_status,
            new_status=order.status,
            changed_by=user,
            comment='Order rejected by supplier via API',
        )

        return Response(
            {
                "id": order.id,
                "old_status": old_status,
                "new_status": order.status,
            },
            status=status.HTTP_200_OK
        )

class ConsumerCancelOrderView(BaseOrderStatusView):
    """
    Отмена заказа потребителем.
    Можно отменить только свой заказ и только пока он 'pending'.
    """
    new_status = 'cancelled'

    def handle_order(self, request, order):
        user = request.user

        # ищем consumer-профиль
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            return Response(
                {"detail": "Только потребитель может отменять заказ."},
                status=status.HTTP_403_FORBIDDEN
            )

        if order.consumer != consumer_profile and not user.is_superuser:
            return Response(
                {"detail": "Вы не можете отменять чужой заказ."},
                status=status.HTTP_403_FORBIDDEN
            )

        if order.status != 'pending':
            return Response(
                {"detail": f"Нельзя отменить заказ в статусе '{order.status}'."},
                status=status.HTTP_400_BAD_REQUEST
            )

        old_status = order.status
        order.status = self.new_status
        order.save()

        OrderStatusHistory.objects.create(
            order=order,
            old_status=old_status,
            new_status=order.status,
            changed_by=user,
            comment='Order cancelled by consumer via API',
        )

        return Response(
            {
                "id": order.id,
                "old_status": old_status,
                "new_status": order.status,
            },
            status=status.HTTP_200_OK
        )

