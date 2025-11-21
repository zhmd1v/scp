from decimal import Decimal

from rest_framework import serializers

from .models import Order, OrderItem, OrderStatusHistory
from catalog.models import Product
from catalog.serializers import ProductSerializer
from accounts.serializers import SupplierProfileSerializer


class OrderItemSerializer(serializers.ModelSerializer):
    """
    Строка заказа (для чтения + создания).
    """
    product_id = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.all(),
        source='product',
        write_only=True
    )
    product = ProductSerializer(read_only=True)

    line_total = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        read_only=True
    )

    class Meta:
        model = OrderItem
        fields = [
            'id',
            'product',
            'product_id',
            'quantity',
            'unit_price',
            'line_total',
            'remark',
        ]


class OrderSerializer(serializers.ModelSerializer):
    """
    Основной сериализатор заказа + вложенные items.
    """
    items = OrderItemSerializer(many=True)
    supplier = SupplierProfileSerializer(read_only=True)

    class Meta:
        model = Order
        fields = [
            'id',
            'consumer',
            'supplier',
            'delivery_option',
            'status',
            'created_at',
            'updated_at',
            'requested_delivery_date',
            'delivery_address',
            'total_amount',
            'notes',
            'items',
        ]
        read_only_fields = ['status', 'created_at', 'updated_at', 'total_amount']

    def create(self, validated_data):
        items_data = validated_data.pop('items', [])

        # создаём сам заказ
        order = Order.objects.create(**validated_data)

        total = Decimal('0')

        for item_data in items_data:
            product = item_data['product']
            quantity = item_data['quantity']
            unit_price = item_data['unit_price']

            line_total = quantity * unit_price

            OrderItem.objects.create(
                order=order,
                product=product,
                quantity=quantity,
                unit_price=unit_price,
                line_total=line_total,
                remark=item_data.get('remark', '')
            )

            total += line_total

        # сохраняем итоговую сумму
        order.total_amount = total
        order.save()

        # создаём запись в истории статусов
        request = self.context.get('request')
        changed_by = request.user if request and request.user.is_authenticated else None

        OrderStatusHistory.objects.create(
            order=order,
            old_status='',
            new_status=order.status,
            changed_by=changed_by,
            comment='Order created via API'
        )

        return order
