from django.contrib import admin
from .models import Complaint, ComplaintResponse, ComplaintEscalation, Incident


class ComplaintResponseInline(admin.TabularInline):
    model = ComplaintResponse
    extra = 0
    readonly_fields = ['created_at']
    fields = ['user', 'message', 'is_internal', 'created_at']


class ComplaintEscalationInline(admin.TabularInline):
    model = ComplaintEscalation
    extra = 0
    readonly_fields = ['escalated_at']
    fields = ['from_level', 'to_level', 'reason', 'escalated_by', 'escalated_at']


@admin.register(Complaint)
class ComplaintAdmin(admin.ModelAdmin):
    list_display = [
        'id',
        'title',
        'consumer',
        'supplier',
        'status',
        'severity',
        'escalation_level',
        'assigned_to',
        'created_at',
    ]
    list_filter = [
        'status',
        'severity',
        'escalation_level',
        'complaint_type',
        'supplier',
        'created_at',
    ]
    search_fields = [
        'title',
        'description',
        'consumer__business_name',
        'supplier__company_name',
        'order__id',
    ]
    readonly_fields = [
        'created_at',
        'updated_at',
        'escalated_at',
    ]
    
    fieldsets = (
        ('Basic Information', {
            'fields': (
                'consumer',
                'supplier',
                'order',
                'title',
                'description',
            )
        }),
        ('Classification', {
            'fields': (
                'complaint_type',
                'severity',
                'status',
            )
        }),
        ('Escalation', {
            'fields': (
                'escalation_level',
                'escalation_reason',
                'escalated_by',
                'escalated_at',
            )
        }),
        ('Assignment', {
            'fields': (
                'created_by',
                'assigned_to',
            )
        }),
        ('Timestamps', {
            'fields': (
                'created_at',
                'updated_at',
            )
        }),
    )
    
    inlines = [ComplaintResponseInline, ComplaintEscalationInline]


@admin.register(ComplaintResponse)
class ComplaintResponseAdmin(admin.ModelAdmin):
    list_display = [
        'id',
        'complaint',
        'user',
        'is_internal',
        'created_at',
    ]
    list_filter = [
        'is_internal',
        'created_at',
    ]
    search_fields = [
        'message',
        'complaint__title',
        'user__email',
    ]
    readonly_fields = ['created_at']


@admin.register(ComplaintEscalation)
class ComplaintEscalationAdmin(admin.ModelAdmin):
    list_display = [
        'id',
        'complaint',
        'from_level',
        'to_level',
        'escalated_by',
        'escalated_at',
    ]
    list_filter = [
        'from_level',
        'to_level',
        'escalated_at',
    ]
    search_fields = [
        'complaint__title',
        'reason',
        'escalated_by__email',
    ]
    readonly_fields = ['escalated_at']


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
    list_filter = [
        'status',
        'severity',
        'supplier',
        'created_at',
    ]
    search_fields = [
        'title',
        'description',
        'supplier__company_name',
    ]
    readonly_fields = [
        'created_at',
        'updated_at',
    ]
    
    fieldsets = (
        ('Basic Information', {
            'fields': (
                'supplier',
                'order',
                'complaint',
                'title',
                'description',
            )
        }),
        ('Classification', {
            'fields': (
                'severity',
                'status',
            )
        }),
        ('Tracking', {
            'fields': (
                'created_by',
                'created_at',
                'updated_at',
            )
        }),
    )