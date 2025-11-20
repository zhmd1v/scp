from rest_framework import serializers
from .models import User, ConsumerProfile, SupplierProfile, ConsumerSupplierLink



class UserSerializer(serializers.ModelSerializer):
    """
    Базовая информация о пользователе.
    """
    class Meta:
        model = User
        fields = [
            'id',
            'username',
            'email',
            'first_name',
            'last_name',
            'user_type',   # consumer / supplier / staff / admin (как мы делали в модели)
            'is_verified',
        ]


class SupplierProfileSerializer(serializers.ModelSerializer):
    """
    Карточка поставщика (компания).
    """
    class Meta:
        model = SupplierProfile
        fields = [
            'id',
            'company_name',
            'city',
            'is_verified',
            'created_at',
        ]


class ConsumerProfileSerializer(serializers.ModelSerializer):
    """
    Карточка потребителя (ресторан/отель).
    """
    class Meta:
        model = ConsumerProfile
        fields = [
            'id',
            'business_name',
            'business_type',
            'city',
        ]

class ConsumerSupplierLinkSerializer(serializers.ModelSerializer):
    """
    Линк между потребителем и поставщиком.
    Используем для списка и создания запросов.
    """

    class Meta:
        model = ConsumerSupplierLink
        fields = [
            'id',
            'consumer',
            'supplier',
            'status',
            'requested_at',
        ]
        read_only_fields = ['consumer', 'status', 'requested_at']
