from rest_framework import serializers
from .models import Complaint, ComplaintResponse, ComplaintEscalation, Incident


class ComplaintResponseSerializer(serializers.ModelSerializer):
    """Serializer for complaint responses"""
    user_email = serializers.EmailField(source='user.email', read_only=True)
    user_type = serializers.CharField(source='user.user_type', read_only=True)
    
    class Meta:
        model = ComplaintResponse
        fields = [
            'id',
            'complaint',
            'user',
            'user_email',
            'user_type',
            'message',
            'is_internal',
            'attachment',
            'created_at',
        ]
        read_only_fields = ['user', 'created_at']


class ComplaintEscalationSerializer(serializers.ModelSerializer):
    """Serializer for escalation history"""
    escalated_by_email = serializers.EmailField(source='escalated_by.email', read_only=True)
    
    class Meta:
        model = ComplaintEscalation
        fields = [
            'id',
            'complaint',
            'from_level',
            'to_level',
            'reason',
            'escalated_by',
            'escalated_by_email',
            'escalated_at',
        ]
        read_only_fields = ['escalated_by', 'escalated_at']


class ComplaintSerializer(serializers.ModelSerializer):
    """
    Serializer for reading/creating complaints with escalation support.
    """
    consumer_name = serializers.CharField(source='consumer.business_name', read_only=True)
    supplier_name = serializers.CharField(source='supplier.company_name', read_only=True)
    created_by_email = serializers.EmailField(source='created_by.email', read_only=True)
    assigned_to_email = serializers.EmailField(source='assigned_to.email', read_only=True)
    escalated_by_email = serializers.EmailField(source='escalated_by.email', read_only=True)
    
    # Nested data for detailed view
    responses = ComplaintResponseSerializer(many=True, read_only=True)
    escalation_history = ComplaintEscalationSerializer(many=True, read_only=True)
    
    # Helper fields
    can_escalate = serializers.SerializerMethodField()
    next_escalation_level = serializers.SerializerMethodField()
    
    class Meta:
        model = Complaint
        fields = [
            'id',
            'consumer',
            'consumer_name',
            'supplier',
            'supplier_name',
            'order',
            'title',
            'description',
            'complaint_type',
            'severity',
            'status',
            'escalation_level',
            'escalation_reason',
            'created_by',
            'created_by_email',
            'assigned_to',
            'assigned_to_email',
            'escalated_by',
            'escalated_by_email',
            'created_at',
            'updated_at',
            'escalated_at',
            'can_escalate',
            'next_escalation_level',
            'responses',
            'escalation_history',
        ]
        read_only_fields = [
            'consumer',
            'status',
            'escalation_level',
            'created_by',
            'assigned_to',
            'escalated_by',
            'created_at',
            'updated_at',
            'escalated_at',
        ]
    
    def get_can_escalate(self, obj):
        """Check if complaint can be escalated"""
        return obj.can_escalate()
    
    def get_next_escalation_level(self, obj):
        """Get next escalation level if available"""
        return obj.get_next_escalation_level()


class ComplaintListSerializer(serializers.ModelSerializer):
    """
    Lightweight serializer for listing complaints (without nested data).
    """
    consumer_name = serializers.CharField(source='consumer.business_name', read_only=True)
    supplier_name = serializers.CharField(source='supplier.company_name', read_only=True)
    assigned_to_email = serializers.EmailField(source='assigned_to.email', read_only=True)
    can_escalate = serializers.SerializerMethodField()
    
    class Meta:
        model = Complaint
        fields = [
            'id',
            'consumer_name',
            'supplier_name',
            'order',
            'title',
            'complaint_type',
            'severity',
            'status',
            'escalation_level',
            'assigned_to_email',
            'created_at',
            'updated_at',
            'can_escalate',
        ]
    
    def get_can_escalate(self, obj):
        return obj.can_escalate()


class ComplaintEscalateSerializer(serializers.Serializer):
    """Serializer for escalating a complaint"""
    reason = serializers.CharField(
        required=True,
        help_text='Reason for escalation'
    )


class ComplaintStatusUpdateSerializer(serializers.Serializer):
    """Serializer for updating complaint status"""
    status = serializers.ChoiceField(
        choices=['open', 'in_progress', 'resolved', 'closed'],
        required=True
    )
    internal_note = serializers.CharField(
        required=False,
        allow_blank=True,
        help_text='Optional internal note about status change'
    )


class IncidentSerializer(serializers.ModelSerializer):
    """Serializer for incidents"""
    supplier_name = serializers.CharField(source='supplier.company_name', read_only=True)
    created_by_email = serializers.EmailField(source='created_by.email', read_only=True)
    complaint_title = serializers.CharField(source='complaint.title', read_only=True)
    
    class Meta:
        model = Incident
        fields = [
            'id',
            'supplier',
            'supplier_name',
            'order',
            'complaint',
            'complaint_title',
            'title',
            'description',
            'severity',
            'status',
            'created_by',
            'created_by_email',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'created_by',
            'status',
            'created_at',
            'updated_at',
        ]


class IncidentStatusUpdateSerializer(serializers.Serializer):
    """Serializer for updating incident status"""
    status = serializers.ChoiceField(
        choices=['open', 'investigating', 'mitigated', 'closed'],
        required=True
    )
