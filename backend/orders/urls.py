from django.urls import path
from .views import (
    OrderListCreateView,
    OrderDetailView,
    MyConsumerOrdersView,
    MySupplierOrdersView,
    SupplierConfirmOrderView,
    SupplierRejectOrderView,
    ConsumerCancelOrderView,
    ConsumerCompleteOrderView,
    OrderStatusHistoryListView,
)

urlpatterns = [
    path('orders/', OrderListCreateView.as_view(), name='order-list-create'),
    path('orders/<int:pk>/', OrderDetailView.as_view(), name='order-detail'),

    path('orders/my/consumer/', MyConsumerOrdersView.as_view(), name='my-consumer-orders'),
    path('orders/my/supplier/', MySupplierOrdersView.as_view(), name='my-supplier-orders'),

     # изменение статусов
    path('orders/<int:pk>/confirm/', SupplierConfirmOrderView.as_view(), name='order-confirm'),
    path('orders/<int:pk>/reject/', SupplierRejectOrderView.as_view(), name='order-reject'),
    path('<int:pk>/cancel/', ConsumerCancelOrderView.as_view(), name='consumer-cancel-order'),
    path('<int:pk>/complete/', ConsumerCompleteOrderView.as_view(), name='consumer-complete-order'),
    path('<int:order_id>/history/', OrderStatusHistoryListView.as_view(), name='order-status-history'),
]
