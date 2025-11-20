from django.urls import path
from .views import (
    ComplaintListCreateView,
    ComplaintDetailView,
    ComplaintStatusUpdateView,
    IncidentListCreateView,
    IncidentDetailView,
    IncidentStatusUpdateView,
)

urlpatterns = [
    path('complaints/', ComplaintListCreateView.as_view(), name='complaint-list-create'),
    path('complaints/<int:pk>/', ComplaintDetailView.as_view(), name='complaint-detail'),
    path('complaints/<int:pk>/status/', ComplaintStatusUpdateView.as_view(), name='complaint-status'),

    path('incidents/', IncidentListCreateView.as_view(), name='incident-list-create'),
    path('incidents/<int:pk>/', IncidentDetailView.as_view(), name='incident-detail'),
    path('incidents/<int:pk>/status/', IncidentStatusUpdateView.as_view(), name='incident-status'),

]
