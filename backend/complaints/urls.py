from django.urls import path
from .views import (
    ComplaintListCreateView,
    ComplaintDetailView,
    ComplaintStatusUpdateView,
    ComplaintEscalateView,
    ComplaintResponseCreateView,
    ComplaintResponseListView,
    IncidentListCreateView,
    IncidentDetailView,
    IncidentStatusUpdateView,
)

urlpatterns = [
    # Complaint endpoints
    path('complaints/', ComplaintListCreateView.as_view(), name='complaint-list-create'),
    path('complaints/<int:pk>/', ComplaintDetailView.as_view(), name='complaint-detail'),
    path('complaints/<int:pk>/status/', ComplaintStatusUpdateView.as_view(), name='complaint-status'),
    path('complaints/<int:pk>/escalate/', ComplaintEscalateView.as_view(), name='complaint-escalate'),
    
    # Complaint response endpoints
    path('complaints/<int:complaint_id>/responses/', ComplaintResponseListView.as_view(), name='complaint-response-list'),
    path('complaints/<int:complaint_id>/responses/create/', ComplaintResponseCreateView.as_view(), name='complaint-response-create'),

    # Incident endpoints
    path('incidents/', IncidentListCreateView.as_view(), name='incident-list-create'),
    path('incidents/<int:pk>/', IncidentDetailView.as_view(), name='incident-detail'),
    path('incidents/<int:pk>/status/', IncidentStatusUpdateView.as_view(), name='incident-status'),
]
