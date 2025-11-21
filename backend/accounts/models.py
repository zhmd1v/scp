from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models


class UserManager(BaseUserManager):
    """
    Custom user manager where email is the unique identifier for authentication.
    """
    def create_user(self, email, username, password=None, **extra_fields):
        """
        Create and save a User with the given email, username and password.
        """
        if not email:
            raise ValueError('The Email field must be set')
        email = self.normalize_email(email)
        user = self.model(email=email, username=username, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, username, password=None, **extra_fields):
        """
        Create and save a SuperUser with the given email, username and password.
        """
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)
        extra_fields.setdefault('user_type', 'platform_admin')

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(email, username, password, **extra_fields)


class User(AbstractUser):
    """
    Custom User model extending Django's AbstractUser
    Serves as base for all user types in the system
    """
    USER_TYPE_CHOICES = [
        ('consumer', 'Consumer'),
        ('supplier_owner', 'Supplier Owner'),
        ('supplier_manager', 'Supplier Manager'),
        ('supplier_sales', 'Supplier Sales Representative'),
        ('platform_admin', 'Platform Admin'),  # Optional for future
    ]
    
    # Override email to make it unique and required
    email = models.EmailField(unique=True)
    
    user_type = models.CharField(max_length=20, choices=USER_TYPE_CHOICES)
    phone = models.CharField(max_length=20, blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    objects = UserManager()
    
    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ['username']  # username is still required but email is used for login
    
    class Meta:
        db_table = 'users'
        
    def __str__(self):
        return f"{self.email} ({self.get_user_type_display()})"


class ConsumerProfile(models.Model):
    """
    Profile for Consumers (Restaurants/Hotels)
    """
    BUSINESS_TYPE_CHOICES = [
        ('restaurant', 'Restaurant'),
        ('hotel', 'Hotel'),
        ('cafe', 'Cafe'),
        ('other', 'Other'),
    ]
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='consumer_profile')
    business_name = models.CharField(max_length=255)
    business_type = models.CharField(max_length=20, choices=BUSINESS_TYPE_CHOICES)
    address = models.TextField()
    city = models.CharField(max_length=100)
    registration_number = models.CharField(max_length=100, blank=True, null=True)
    
    class Meta:
        db_table = 'consumer_profiles'
        
    def __str__(self):
        return self.business_name


class SupplierProfile(models.Model):
    """
    Profile for Supplier companies
    """
    company_name = models.CharField(max_length=255)
    registration_number = models.CharField(max_length=100)
    address = models.TextField()
    city = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)
    logo = models.ImageField(upload_to='supplier_logos/', blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'supplier_profiles'
        
    def __str__(self):
        return self.company_name


class SupplierStaff(models.Model):
    """
    Links supplier staff (Owner, Manager, Sales) to their company
    """
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='supplier_staff')
    supplier = models.ForeignKey(SupplierProfile, on_delete=models.CASCADE, related_name='staff_members')
    position = models.CharField(max_length=100, blank=True, null=True)
    
    class Meta:
        db_table = 'supplier_staff'
        verbose_name_plural = 'Supplier Staff'
        
    def __str__(self):
        return f"{self.user.username} - {self.supplier.company_name}"


class ConsumerSupplierLink(models.Model):
    """
    Represents the link/relationship between a consumer and supplier
    Consumer must be approved before accessing supplier's catalog
    """
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('blocked', 'Blocked'),
    ]
    
    consumer = models.ForeignKey(ConsumerProfile, on_delete=models.CASCADE, related_name='supplier_links')
    supplier = models.ForeignKey(SupplierProfile, on_delete=models.CASCADE, related_name='consumer_links')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    requested_at = models.DateTimeField(auto_now_add=True)
    approved_at = models.DateTimeField(blank=True, null=True)
    approved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='approved_links')
    notes = models.TextField(blank=True, null=True)
    
    class Meta:
        db_table = 'consumer_supplier_links'
        unique_together = ['consumer', 'supplier']
        
    def __str__(self):
        return f"{self.consumer.business_name} -> {self.supplier.company_name} ({self.status})"