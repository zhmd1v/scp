from django.db import models
from django.conf import settings

from accounts.models import ConsumerProfile, SupplierProfile


class Complaint(models.Model):
    """
    Complaint from consumer to supplier (often tied to an order).
    Escalation workflow: Sales Representative → Manager → Owner
    
    According to SRS:
    - Sales handles first-line complaints
    - Manager handles escalated complaints
    - Owner has oversight
    """
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('in_progress', 'In progress'),
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

    # Basic Info
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
        'orders.Order',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='complaints'
    )

    title = models.CharField(max_length=200)
    description = models.TextField()

    # Classification
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
        max_length=20,
        choices=STATUS_CHOICES,
        default='open'
    )

    # Escalation Management
    escalation_level = models.CharField(
        max_length=20,
        choices=ESCALATION_LEVEL_CHOICES,
        default='sales',
        help_text='Current escalation level: sales → manager → owner'
    )
    escalation_reason = models.TextField(
        blank=True,
        null=True,
        help_text='Reason for escalation to higher level'
    )

    # Assignment & Tracking
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
        help_text='Current staff member handling this complaint'
    )
    escalated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='escalated_complaints',
        help_text='Staff member who escalated this complaint'
    )

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    escalated_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the complaint was last escalated'
    )

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['supplier', 'status']),
            models.Index(fields=['consumer', 'status']),
            models.Index(fields=['escalation_level', 'status']),
        ]

    def __str__(self):
        return f"Complaint #{self.id} - {self.title} ({self.status} - {self.escalation_level})"

    def can_escalate(self):
        """Check if complaint can be escalated to next level"""
        escalation_order = ['sales', 'manager', 'owner']
        current_index = escalation_order.index(self.escalation_level)
        return current_index < len(escalation_order) - 1

    def get_next_escalation_level(self):
        """Get the next escalation level"""
        escalation_order = ['sales', 'manager', 'owner']
        current_index = escalation_order.index(self.escalation_level)
        if current_index < len(escalation_order) - 1:
            return escalation_order[current_index + 1]
        return None


class ComplaintResponse(models.Model):
    """
    Response/comment on a complaint by supplier staff.
    Tracks the conversation history and escalation decisions.
    """
    complaint = models.ForeignKey(
        Complaint,
        on_delete=models.CASCADE,
        related_name='responses'
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='complaint_responses'
    )
    message = models.TextField()
    is_internal = models.BooleanField(
        default=False,
        help_text='Internal note not visible to consumer'
    )
    
    # Attachments support
    attachment = models.FileField(
        upload_to='complaint_responses/',
        blank=True,
        null=True
    )
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f"Response to Complaint #{self.complaint.id} by {self.user}"


class ComplaintEscalation(models.Model):
    """
    Log of escalation events for audit trail.
    """
    ESCALATION_LEVEL_CHOICES = [
        ('sales', 'Sales Representative'),
        ('manager', 'Manager'),
        ('owner', 'Owner'),
    ]
    
    complaint = models.ForeignKey(
        Complaint,
        on_delete=models.CASCADE,
        related_name='escalation_history'
    )
    from_level = models.CharField(
        max_length=20,
        choices=ESCALATION_LEVEL_CHOICES  # ← ADD THIS
    )
    to_level = models.CharField(
        max_length=20,
        choices=ESCALATION_LEVEL_CHOICES  # ← ADD THIS
    )
    reason = models.TextField()
    escalated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='escalations_performed'
    )
    escalated_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-escalated_at']
    
    def __str__(self):
        return f"Escalation #{self.id}: {self.from_level} → {self.to_level}"


class Incident(models.Model):
    """
    Incident related to supplier/order/complaint.
    Usually created by supplier Manager based on complaints or
    serious issues with order fulfillment.
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
        'orders.Order',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='incidents'
    )
    complaint = models.ForeignKey(
        Complaint,
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

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Incident #{self.id} - {self.title} ({self.status})"
