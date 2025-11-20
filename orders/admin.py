from django.contrib import admin
from .models import Order, OrderItem, OrderStatusHistory


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 1


class OrderStatusHistoryInline(admin.TabularInline):
    model = OrderStatusHistory
    extra = 0
    readonly_fields = ['old_status', 'new_status', 'changed_at', 'changed_by']


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ['id', 'consumer', 'supplier', 'status', 'total_amount', 'created_at']
    list_filter = ['status', 'supplier', 'created_at']
    search_fields = ['id', 'consumer__business_name', 'supplier__company_name']
    inlines = [OrderItemInline, OrderStatusHistoryInline]


@admin.register(OrderItem)
class OrderItemAdmin(admin.ModelAdmin):
    list_display = ['order', 'product', 'quantity', 'unit_price', 'line_total']
    search_fields = ['product__name', 'order__id']


@admin.register(OrderStatusHistory)
class OrderStatusHistoryAdmin(admin.ModelAdmin):
    list_display = ['order', 'old_status', 'new_status', 'changed_at', 'changed_by']
    list_filter = ['new_status', 'changed_at']
