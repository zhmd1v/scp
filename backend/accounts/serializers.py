from rest_framework import serializers
from .models import User, ConsumerProfile, SupplierProfile, ConsumerSupplierLink, SupplierStaff

from django.db import transaction


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
            'address',
            'city',
            'registration_number',
        ]
        read_only_fields = ['id']


class SupplierStaffSerializer(serializers.ModelSerializer):
    """
    Краткая информация о сотруднике поставщика + его компании.
    """
    supplier = SupplierProfileSerializer(read_only=True)

    class Meta:
        model = SupplierStaff
        fields = [
            'id',
            'supplier_id',
            'supplier',
            'position',
        ]


class UserSerializer(serializers.ModelSerializer):
    """
    Базовая информация о пользователе + связанные профили.
    """
    supplier_staff = SupplierStaffSerializer(read_only=True)
    consumer_profile = ConsumerProfileSerializer(read_only=True)

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
            'supplier_staff',
            'consumer_profile',
        ]

class ConsumerSupplierLinkSerializer(serializers.ModelSerializer):
    """
    Линк между потребителем и поставщиком.
    Используем для списка и создания запросов.
    """
    supplier = SupplierProfileSerializer(read_only=True)
    consumer = ConsumerProfileSerializer(read_only=True)
    supplier_id = serializers.PrimaryKeyRelatedField(
        queryset=SupplierProfile.objects.all(),
        source='supplier',
        write_only=True
    )

    class Meta:
        model = ConsumerSupplierLink
        fields = [
            'id',
            'consumer',
            'supplier',
            'supplier_id',
            'status',
            'requested_at',
        ]
        read_only_fields = ['consumer', 'status', 'requested_at']


class ConsumerRegisterSerializer(serializers.Serializer):
    """
    Регистрация consumer-пользователя + его ConsumerProfile.
    """
    username = serializers.CharField(max_length=150)
    password = serializers.CharField(write_only=True, min_length=6)
    email = serializers.EmailField(required=True)  # Email is now required since it's USERNAME_FIELD
    phone = serializers.CharField(required=False, allow_blank=True)

    business_name = serializers.CharField(max_length=255)
    business_type = serializers.CharField(max_length=255, required=False, allow_blank=True)
    city = serializers.CharField(max_length=255, required=False, allow_blank=True)
    address = serializers.CharField(max_length=255, required=False, allow_blank=True)

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("This username is already taken.")
        return value
    
    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("This email is already registered.")
        return value

    @transaction.atomic
    def create(self, validated_data):
        password = validated_data.pop('password')

        user = User(
            username=validated_data.pop('username'),
            email=validated_data.pop('email'),
            phone=validated_data.pop('phone', ''),
            user_type='consumer',   # важно: чтобы помечать как consumer
            is_active=True,
        )
        user.set_password(password)
        user.save()

        # создаём ConsumerProfile
        ConsumerProfile.objects.create(
            user=user,
            business_name=validated_data.get('business_name'),
            business_type=validated_data.get('business_type', ''),
            city=validated_data.get('city', ''),
            address=validated_data.get('address', ''),
        )

        return user