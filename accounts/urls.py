from django.urls import path
from .views import (
    api_health,
    me,
    SupplierListView,
    ConsumerSupplierLinkListCreateView,
    ApproveLinkView,
    RejectLinkView,
    BlockLinkView,
)

urlpatterns = [
    path('health/', api_health, name='api-health'),
    path('me/', me, name='api-me'),
    path('suppliers/', SupplierListView.as_view(), name='supplier-list'),
    path('links/', ConsumerSupplierLinkListCreateView.as_view(), name='consumer-supplier-links'),

    # действия над линком (для поставщика)
    path('links/<int:pk>/approve/', ApproveLinkView.as_view(), name='link-approve'),
    path('links/<int:pk>/reject/', RejectLinkView.as_view(), name='link-reject'),
    path('links/<int:pk>/block/', BlockLinkView.as_view(), name='link-block'),

]
