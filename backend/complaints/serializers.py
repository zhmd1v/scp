from rest_framework import serializers
from .models import Complaint, Incident


class ComplaintSerializer(serializers.ModelSerializer):
    """
    Сериализатор для чтения/создания жалоб.
    """
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
            'created_by',
            'assigned_to',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'consumer',
            'status',
            'created_by',
            'assigned_to',
            'created_at',
            'updated_at',
        ]

class IncidentSerializer(serializers.ModelSerializer):
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
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'created_by',
            'status',
            'created_at',
            'updated_at',
        ]