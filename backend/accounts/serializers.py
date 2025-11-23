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



class StaffCreateSerializer(serializers.Serializer):
    # USER fields
    username = serializers.CharField()
    email = serializers.EmailField(required=False)
    password = serializers.CharField(write_only=True)
    first_name = serializers.CharField(required=False, allow_blank=True)
    last_name = serializers.CharField(required=False, allow_blank=True)
    phone = serializers.CharField(required=False, allow_blank=True)
    user_type = serializers.CharField()

    # STAFF fields
    position = serializers.CharField()
    supplier_id = serializers.IntegerField()

    def create(self, validated_data):
        # Extract user fields
        user_fields = {
            "username": validated_data["username"],
            "email": validated_data.get("email", ""),
            "first_name": validated_data.get("first_name", ""),
            "last_name": validated_data.get("last_name", ""),
            "phone": validated_data.get("phone", ""),
            "user_type": validated_data["user_type"],
        }

        password = validated_data["password"]

        # 1. Create user
        user = User(**user_fields)
        user.set_password(password)
        user.save()

        # 2. Create staff
        staff = SupplierStaff.objects.create(
            user=user,
            supplier_id=validated_data["supplier_id"],
            position=validated_data["position"]
        )

        return {
            "user": user,
            "staff": staff
        }


class UserCreateSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "email",
            "first_name",
            "last_name",
            "phone",
            "user_type",
            "password",
            "is_active",
            "is_verified",
        ]

    def create(self, validated_data):
        password = validated_data.pop("password")
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user


class UserUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "email",
            "first_name",
            "last_name",
            "is_active",
        ]
        read_only_fields = ["id"]

    def update(self, instance, validated_data):
        # No password here — only profile fields.
        return super().update(instance, validated_data)


class UserMiniSerializer(serializers.ModelSerializer):
    """Minimal user details returned with staff."""
    
    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "email",
            "first_name",
            "last_name",
            "user_type",
            "is_active",
        ]


class SupplierStaffSerializer(serializers.ModelSerializer):
    """Staff entry with nested user + nested supplier."""
    
    user = UserMiniSerializer(read_only=True)
    user_id = serializers.IntegerField(write_only=True, required=False)
    supplier = SupplierProfileSerializer(read_only=True)

    class Meta:
        model = SupplierStaff
        fields = [
            "id",
            "user",
            "user_id",
            "supplier",
            "supplier_id",
            "position",
        ]
        read_only_fields = ["id", "supplier", "supplier_id"]

    def create(self, validated_data):
        user_id = validated_data.pop("user_id", None)
        if not user_id:
            raise serializers.ValidationError({"user_id": "user_id is required"})

        user = User.objects.get(id=user_id)

        request = self.context.get("request")
        # Handle case where request might not be present or user might not have supplier_owner
        # But based on views usage, this is for owner/manager creating staff
        if request and hasattr(request.user, 'supplier_owner'):
             supplier = request.user.supplier_owner.supplier
        elif request and hasattr(request.user, 'supplier_staff'):
             supplier = request.user.supplier_staff.supplier
        else:
            # Fallback or error if context is missing
             supplier_id = validated_data.get('supplier_id')
             if not supplier_id:
                 raise serializers.ValidationError("Supplier context missing.")
             return SupplierStaff.objects.create(user=user, **validated_data)

        return SupplierStaff.objects.create(
            user=user,
            supplier=supplier,
            **validated_data
        )


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