from django.urls import path
from .views_enhanced import (
    ComplaintListCreateView,
    ComplaintDetailView,
    ComplaintEscalateView,
    ComplaintStatusUpdateView,
    ComplaintNoteCreateView,
    ComplaintNoteListView,
    IncidentListCreateView,
    IncidentDetailView,
    IncidentStatusUpdateView,
)

urlpatterns = [
    # Complaint endpoints
    path('complaints/', ComplaintListCreateView.as_view(), name='complaint-list-create'),
    path('complaints/<int:pk>/', ComplaintDetailView.as_view(), name='complaint-detail'),
    path('complaints/<int:pk>/escalate/', ComplaintEscalateView.as_view(), name='complaint-escalate'),
    path('complaints/<int:pk>/status/', ComplaintStatusUpdateView.as_view(), name='complaint-status'),
    
    # Complaint notes endpoints
    path('complaints/<int:complaint_id>/notes/', ComplaintNoteListView.as_view(), name='complaint-notes-list'),
    path('complaints/<int:complaint_id>/notes/create/', ComplaintNoteCreateView.as_view(), name='complaint-note-create'),

    # Incident endpoints
    path('incidents/', IncidentListCreateView.as_view(), name='incident-list-create'),
    path('incidents/<int:pk>/', IncidentDetailView.as_view(), name='incident-detail'),
    path('incidents/<int:pk>/status/', IncidentStatusUpdateView.as_view(), name='incident-status'),
]
