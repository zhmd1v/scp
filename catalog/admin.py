from django.contrib import admin
from .models import (
    Category, Product, ProductImage, ProductDiscount, 
    Catalog, CatalogProduct, DeliveryOption
)

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'parent', 'created_at']
    search_fields = ['name']

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ['name', 'supplier', 'category', 'unit_price', 'stock_quantity', 'is_available']
    list_filter = ['is_available', 'category', 'supplier']
    search_fields = ['name', 'sku']

@admin.register(ProductImage)
class ProductImageAdmin(admin.ModelAdmin):
    list_display = ['product', 'uploaded_at']

@admin.register(ProductDiscount)
class ProductDiscountAdmin(admin.ModelAdmin):
    list_display = ['product', 'discount_type', 'value', 'start_date', 'end_date', 'is_active']
    list_filter = ['discount_type', 'is_active']

@admin.register(Catalog)
class CatalogAdmin(admin.ModelAdmin):
    list_display = ['name', 'supplier', 'is_active', 'created_at']
    list_filter = ['is_active', 'supplier']

@admin.register(CatalogProduct)
class CatalogProductAdmin(admin.ModelAdmin):
    list_display = ['catalog', 'product', 'display_order', 'is_featured']
    list_filter = ['is_featured', 'catalog']

@admin.register(DeliveryOption)
class DeliveryOptionAdmin(admin.ModelAdmin):
    list_display = ['supplier', 'delivery_type', 'delivery_fee', 'minimum_order_amount', 'is_active']
    list_filter = ['delivery_type', 'is_active']