from django.contrib import admin
from .models import Complaint, ComplaintNote, Incident


class ComplaintNoteInline(admin.TabularInline):
    """Inline display of complaint notes in complaint admin"""
    model = ComplaintNote
    extra = 0
    readonly_fields = ('created_at', 'created_by')
    fields = ('note_type', 'content', 'created_by', 'created_at', 'is_visible_to_consumer')
    
    def has_delete_permission(self, request, obj=None):
        return False  # Prevent deletion of notes to maintain audit trail


@admin.register(Complaint)
class ComplaintAdmin(admin.ModelAdmin):
    """Enhanced admin for Complaint model"""
    list_display = (
        'id',
        'title',
        'consumer',
        'supplier',
        'complaint_type',
        'severity',
        'status',
        'escalation_level',
        'assigned_to',
        'created_at',
    )
    list_filter = (
        'status',
        'escalation_level',
        'severity',
        'complaint_type',
        'created_at',
    )
    search_fields = (
        'title',
        'description',
        'consumer__business_name',
        'supplier__company_name',
        'order__id',
    )
    readonly_fields = (
        'created_by',
        'created_at',
        'updated_at',
        'escalated_by',
        'escalated_at',
        'resolved_by',
        'resolved_at',
    )
    
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
            )
        }),
        ('Status & Assignment', {
            'fields': (
                'status',
                'escalation_level',
                'assigned_to',
            )
        }),
        ('Escalation Tracking', {
            'fields': (
                'escalated_by',
                'escalated_at',
            ),
            'classes': ('collapse',),
        }),
        ('Resolution', {
            'fields': (
                'resolution_notes',
                'resolved_by',
                'resolved_at',
            ),
            'classes': ('collapse',),
        }),
        ('Audit', {
            'fields': (
                'created_by',
                'created_at',
                'updated_at',
            ),
            'classes': ('collapse',),
        }),
    )
    
    inlines = [ComplaintNoteInline]
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        return qs.select_related(
            'consumer',
            'supplier',
            'order',
            'created_by',
            'assigned_to',
            'escalated_by',
            'resolved_by',
        )


@admin.register(ComplaintNote)
class ComplaintNoteAdmin(admin.ModelAdmin):
    """Admin for ComplaintNote model"""
    list_display = (
        'id',
        'complaint',
        'note_type',
        'created_by',
        'created_at',
        'is_visible_to_consumer',
    )
    list_filter = (
        'note_type',
        'is_visible_to_consumer',
        'created_at',
    )
    search_fields = (
        'content',
        'complaint__title',
    )
    readonly_fields = ('created_at', 'created_by')
    
    fieldsets = (
        (None, {
            'fields': (
                'complaint',
                'note_type',
                'content',
                'is_visible_to_consumer',
            )
        }),
        ('Change Tracking', {
            'fields': (
                'previous_value',
                'new_value',
            ),
            'classes': ('collapse',),
        }),
        ('Audit', {
            'fields': (
                'created_by',
                'created_at',
            ),
            'classes': ('collapse',),
        }),
    )
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        return qs.select_related('complaint', 'created_by')
    
    def has_delete_permission(self, request, obj=None):
        # Only superusers can delete notes to maintain audit trail
        return request.user.is_superuser


@admin.register(Incident)
class IncidentAdmin(admin.ModelAdmin):
    """Admin for Incident model"""
    list_display = (
        'id',
        'title',
        'supplier',
        'severity',
        'status',
        'created_by',
        'created_at',
    )
    list_filter = (
        'status',
        'severity',
        'created_at',
    )
    search_fields = (
        'title',
        'description',
        'supplier__company_name',
    )
    readonly_fields = ('created_by', 'created_at', 'updated_at')
    
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
        ('Audit', {
            'fields': (
                'created_by',
                'created_at',
                'updated_at',
            ),
            'classes': ('collapse',),
        }),
    )
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        return qs.select_related('supplier', 'order', 'complaint', 'created_by')
