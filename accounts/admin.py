from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, ConsumerProfile, SupplierProfile, SupplierStaff, ConsumerSupplierLink

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ['username', 'email', 'user_type', 'is_verified', 'is_active']
    list_filter = ['user_type', 'is_verified', 'is_active']
    fieldsets = UserAdmin.fieldsets + (
        ('Additional Info', {'fields': ('user_type', 'phone', 'is_verified')}),
    )

@admin.register(ConsumerProfile)
class ConsumerProfileAdmin(admin.ModelAdmin):
    list_display = ['business_name', 'business_type', 'city', 'user']
    search_fields = ['business_name', 'city']

@admin.register(SupplierProfile)
class SupplierProfileAdmin(admin.ModelAdmin):
    list_display = ['company_name', 'city', 'is_verified', 'created_at']
    list_filter = ['is_verified', 'city']
    search_fields = ['company_name']

@admin.register(SupplierStaff)
class SupplierStaffAdmin(admin.ModelAdmin):
    list_display = ['user', 'supplier', 'position']
    search_fields = ['user__username', 'supplier__company_name']

@admin.register(ConsumerSupplierLink)
class ConsumerSupplierLinkAdmin(admin.ModelAdmin):
    list_display = ['consumer', 'supplier', 'status', 'requested_at']
    list_filter = ['status']
    search_fields = ['consumer__business_name', 'supplier__company_name']