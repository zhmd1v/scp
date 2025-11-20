from django.db import models
from django.conf import settings

from accounts.models import ConsumerProfile, SupplierProfile
from catalog.models import Product, DeliveryOption


class Order(models.Model):
    """
    Заказ от конкретного потребителя (ресторана/отеля) конкретному поставщику.
    """
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('pending', 'Pending approval'),
        ('confirmed', 'Confirmed'),
        ('rejected', 'Rejected'),
        ('in_delivery', 'In delivery'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]

    consumer = models.ForeignKey(
        ConsumerProfile,
        on_delete=models.CASCADE,
        related_name='orders'
    )
    supplier = models.ForeignKey(
        SupplierProfile,
        on_delete=models.CASCADE,
        related_name='orders'
    )

    delivery_option = models.ForeignKey(
        DeliveryOption,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='orders'
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='pending'
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    requested_delivery_date = models.DateField(null=True, blank=True)
    delivery_address = models.TextField(blank=True)

    total_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0
    )

    notes = models.TextField(blank=True)

    def __str__(self):
        return f"Order #{self.id} - {self.consumer.business_name} → {self.supplier.company_name}"


class OrderItem(models.Model):
    """
    Строка заказа: конкретный товар, количество, цена.
    """
    order = models.ForeignKey(
        Order,
        on_delete=models.CASCADE,
        related_name='items'
    )
    product = models.ForeignKey(
        Product,
        on_delete=models.PROTECT,
        related_name='order_items'
    )

    quantity = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Quantity in product units (e.g. kg, pieces)'
    )
    unit_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text='Price per unit at the time of order'
    )
    line_total = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        help_text='quantity × unit_price'
    )

    remark = models.CharField(
        max_length=255,
        blank=True,
        help_text='Optional note for this line (e.g. ripeness, cut type)'
    )

    def __str__(self):
        return f"{self.product.name} x {self.quantity} for Order #{self.order.id}"


class OrderStatusHistory(models.Model):
    """
    История изменения статусов заказа.
    Чтобы можно было видеть, кто и когда изменял статус.
    """
    order = models.ForeignKey(
        Order,
        on_delete=models.CASCADE,
        related_name='status_history'
    )

    old_status = models.CharField(max_length=20, blank=True)
    new_status = models.CharField(max_length=20)

    changed_at = models.DateTimeField(auto_now_add=True)
    changed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='order_status_changes'
    )

    comment = models.TextField(blank=True)

    def __str__(self):
        return f"Order #{self.order.id}: {self.old_status} → {self.new_status}"
