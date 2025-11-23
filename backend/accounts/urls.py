from django.urls import path
from .views import (
    api_health,
    me,
    SupplierListView,
    ConsumerSupplierLinkListCreateView,
    ApproveLinkView,
    RejectLinkView,
    BlockLinkView,
    CancelLinkRequestView,
    ConsumerRegisterView,
    ConsumerProfileUpdateView,
    UserProfileUpdateView,
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
    path('links/<int:pk>/cancel/', CancelLinkRequestView.as_view(), name='link-cancel'),
    path('register/', ConsumerRegisterView.as_view(), name='consumer-register'),
    
    # profile update
    path('profile/consumer/', ConsumerProfileUpdateView.as_view(), name='consumer-profile-update'),
    path('profile/user/', UserProfileUpdateView.as_view(), name='user-profile-update'),
]
