from django.db import models
from django.conf import settings

from accounts.models import ConsumerProfile, SupplierProfile
from orders.models import Order


class Complaint(models.Model):
    """
    Complaint from consumer to supplier (often tied to an order).
    Supports escalation flow: Sales → Manager → Owner
    """
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('in_progress', 'In Progress'),
        ('escalated_to_manager', 'Escalated to Manager'),
        ('escalated_to_owner', 'Escalated to Owner'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
    ]

    SEVERITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('critical', 'Critical'),
    ]

    TYPE_CHOICES = [
        ('product', 'Product quality'),
        ('delivery', 'Delivery issue'),
        ('billing', 'Billing/price'),
        ('service', 'Service/communication'),
        ('other', 'Other'),
    ]

    ESCALATION_LEVEL_CHOICES = [
        ('sales', 'Sales Representative'),
        ('manager', 'Manager'),
        ('owner', 'Owner'),
    ]

    consumer = models.ForeignKey(
        ConsumerProfile,
        on_delete=models.CASCADE,
        related_name='complaints'
    )
    supplier = models.ForeignKey(
        SupplierProfile,
        on_delete=models.CASCADE,
        related_name='complaints'
    )
    order = models.ForeignKey(
        Order,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='complaints'
    )

    title = models.CharField(max_length=200)
    description = models.TextField()

    complaint_type = models.CharField(
        max_length=20,
        choices=TYPE_CHOICES,
        default='other'
    )
    severity = models.CharField(
        max_length=10,
        choices=SEVERITY_CHOICES,
        default='medium'
    )
    status = models.CharField(
        max_length=30,
        choices=STATUS_CHOICES,
        default='open'
    )

    # Escalation tracking
    escalation_level = models.CharField(
        max_length=20,
        choices=ESCALATION_LEVEL_CHOICES,
        default='sales',
        help_text='Current escalation level of the complaint'
    )
    escalated_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='Timestamp of last escalation'
    )
    escalated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='escalated_complaints',
        help_text='User who escalated the complaint'
    )

    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_complaints'
    )
    assigned_to = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_complaints',
        help_text='Currently assigned staff member'
    )

    # Resolution tracking
    resolution_notes = models.TextField(
        blank=True,
        null=True,
        help_text='Final resolution notes'
    )
    resolved_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='Timestamp when complaint was resolved'
    )
    resolved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='resolved_complaints',
        help_text='User who resolved the complaint'
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'complaints'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'escalation_level']),
            models.Index(fields=['supplier', 'status']),
            models.Index(fields=['consumer', 'created_at']),
        ]

    def __str__(self):
        return f"Complaint #{self.id} - {self.title} ({self.status})"

    def can_escalate(self):
        """Check if complaint can be escalated further"""
        return self.escalation_level in ['sales', 'manager'] and self.status not in ['resolved', 'closed']


class ComplaintNote(models.Model):
    """
    Notes/comments on complaints for tracking resolution progress
    """
    NOTE_TYPE_CHOICES = [
        ('comment', 'Comment'),
        ('escalation', 'Escalation'),
        ('status_change', 'Status Change'),
        ('resolution', 'Resolution'),
        ('internal', 'Internal Note'),
    ]

    complaint = models.ForeignKey(
        Complaint,
        on_delete=models.CASCADE,
        related_name='notes'
    )
    note_type = models.CharField(
        max_length=20,
        choices=NOTE_TYPE_CHOICES,
        default='comment'
    )
    content = models.TextField()
    
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='complaint_notes'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    # Track what changed (for status_change and escalation types)
    previous_value = models.CharField(max_length=50, blank=True, null=True)
    new_value = models.CharField(max_length=50, blank=True, null=True)

    is_visible_to_consumer = models.BooleanField(
        default=True,
        help_text='Whether this note is visible to the consumer'
    )

    class Meta:
        db_table = 'complaint_notes'
        ordering = ['created_at']

    def __str__(self):
        return f"Note on Complaint #{self.complaint_id} by {self.created_by}"


class Incident(models.Model):
    """
    Инцидент, связанный с поставщиком / заказом / жалобой.
    Обычно создаётся менеджером поставщика на основе жалобы или
    серьёзной проблемы с выполнением заказа.
    """
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('investigating', 'Investigating'),
        ('mitigated', 'Mitigated'),
        ('closed', 'Closed'),
    ]

    SEVERITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('critical', 'Critical'),
    ]

    supplier = models.ForeignKey(
        SupplierProfile,
        on_delete=models.CASCADE,
        related_name='incidents'
    )
    order = models.ForeignKey(
        Order,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='incidents'
    )
    complaint = models.ForeignKey(
        'Complaint',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='incidents'
    )

    title = models.CharField(max_length=200)
    description = models.TextField()

    severity = models.CharField(
        max_length=10,
        choices=SEVERITY_CHOICES,
        default='medium'
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='open'
    )

    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_incidents'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Incident #{self.id} - {self.title} ({self.status})"