from rest_framework import serializers
from .models import Complaint, ComplaintNote, Incident
from accounts.models import User


class UserBasicSerializer(serializers.ModelSerializer):
    """Basic user info for nested serialization"""
    class Meta:
        model = User
        fields = ['id', 'email', 'username', 'user_type']
        read_only_fields = fields


class ComplaintNoteSerializer(serializers.ModelSerializer):
    """Serializer for complaint notes/comments"""
    created_by_info = UserBasicSerializer(source='created_by', read_only=True)
    
    class Meta:
        model = ComplaintNote
        fields = [
            'id',
            'complaint',
            'note_type',
            'content',
            'created_by',
            'created_by_info',
            'created_at',
            'previous_value',
            'new_value',
            'is_visible_to_consumer',
        ]
        read_only_fields = [
            'created_by',
            'created_by_info',
            'created_at',
        ]


class ComplaintSerializer(serializers.ModelSerializer):
    """
    Serializer for reading/creating complaints with escalation support
    """
    notes = ComplaintNoteSerializer(many=True, read_only=True)
    created_by_info = UserBasicSerializer(source='created_by', read_only=True)
    assigned_to_info = UserBasicSerializer(source='assigned_to', read_only=True)
    escalated_by_info = UserBasicSerializer(source='escalated_by', read_only=True)
    resolved_by_info = UserBasicSerializer(source='resolved_by', read_only=True)
    can_escalate = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = Complaint
        fields = [
            'id',
            'consumer',
            'supplier',
            'order',
            'title',
            'description',
            'complaint_type',
            'severity',
            'status',
            'escalation_level',
            'escalated_at',
            'escalated_by',
            'escalated_by_info',
            'created_by',
            'created_by_info',
            'assigned_to',
            'assigned_to_info',
            'resolution_notes',
            'resolved_at',
            'resolved_by',
            'resolved_by_info',
            'created_at',
            'updated_at',
            'notes',
            'can_escalate',
        ]
        read_only_fields = [
            'consumer',
            'status',
            'escalation_level',
            'escalated_at',
            'escalated_by',
            'escalated_by_info',
            'created_by',
            'created_by_info',
            'assigned_to',
            'assigned_to_info',
            'resolved_at',
            'resolved_by',
            'resolved_by_info',
            'created_at',
            'updated_at',
            'can_escalate',
        ]


class ComplaintCreateSerializer(serializers.ModelSerializer):
    """Simplified serializer for creating complaints"""
    class Meta:
        model = Complaint
        fields = [
            'supplier',
            'order',
            'title',
            'description',
            'complaint_type',
            'severity',
        ]


class IncidentSerializer(serializers.ModelSerializer):
    created_by_info = UserBasicSerializer(source='created_by', read_only=True)
    
    class Meta:
        model = Incident
        fields = [
            'id',
            'supplier',
            'order',
            'complaint',
            'title',
            'description',
            'severity',
            'status',
            'created_by',
            'created_by_info',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'created_by',
            'created_by_info',
            'status',
            'created_at',
            'updated_at',
        ]