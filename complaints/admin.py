from django.contrib import admin
from .models import Complaint, Incident


@admin.register(Complaint)
class ComplaintAdmin(admin.ModelAdmin):
    list_display = [
        'id',
        'title',
        'consumer',
        'supplier',
        'status',
        'severity',
        'created_at',
    ]
    list_filter = ['status', 'severity', 'supplier']
    search_fields = ['title', 'description', 'consumer__business_name', 'supplier__company_name']


@admin.register(Incident)
class IncidentAdmin(admin.ModelAdmin):
    list_display = [
        'id',
        'title',
        'supplier',
        'status',
        'severity',
        'created_at',
    ]
    list_filter = ['status', 'severity', 'supplier']
    search_fields = ['title', 'description']