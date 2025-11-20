from django.db import models
from accounts.models import SupplierProfile

class Category(models.Model):
    """
    Product categories (e.g., Vegetables, Meat, Dairy, etc.)
    """
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)
    parent = models.ForeignKey('self', on_delete=models.CASCADE, null=True, blank=True, related_name='subcategories')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'categories'
        verbose_name_plural = 'Categories'
        
    def __str__(self):
        return self.name


class Product(models.Model):
    """
    Products offered by suppliers
    """
    UNIT_CHOICES = [
        ('kg', 'Kilogram'),
        ('g', 'Gram'),
        ('l', 'Liter'),
        ('ml', 'Milliliter'),
        ('pcs', 'Pieces'),
        ('box', 'Box'),
        ('pack', 'Pack'),
    ]
    
    supplier = models.ForeignKey(SupplierProfile, on_delete=models.CASCADE, related_name='products')
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, related_name='products')
    
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    sku = models.CharField(max_length=100, blank=True, null=True)  # Stock Keeping Unit
    
    unit = models.CharField(max_length=10, choices=UNIT_CHOICES, default='kg')
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    
    # Stock management
    stock_quantity = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    minimum_order_quantity = models.DecimalField(max_digits=10, decimal_places=2, default=1)
    is_available = models.BooleanField(default=True)
    
    # Images
    image = models.ImageField(upload_to='products/', blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'products'
        
    def __str__(self):
        return f"{self.name} - {self.supplier.company_name}"


class ProductImage(models.Model):
    """
    Additional images for products (multiple images per product)
    """
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='additional_images')
    image = models.ImageField(upload_to='products/additional/')
    uploaded_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'product_images'
        
    def __str__(self):
        return f"Image for {self.product.name}"


class ProductDiscount(models.Model):
    """
    Discounts/special pricing for products
    """
    DISCOUNT_TYPE_CHOICES = [
        ('percentage', 'Percentage'),
        ('fixed', 'Fixed Amount'),
    ]
    
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='discounts')
    discount_type = models.CharField(max_length=20, choices=DISCOUNT_TYPE_CHOICES)
    value = models.DecimalField(max_digits=10, decimal_places=2)
    
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    
    is_active = models.BooleanField(default=True)
    description = models.CharField(max_length=255, blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'product_discounts'
        
    def __str__(self):
        return f"{self.product.name} - {self.value}{' %' if self.discount_type == 'percentage' else ' ₸'}"


class Catalog(models.Model):
    """
    A catalog is a collection of products that a supplier offers
    Suppliers can have multiple catalogs (e.g., Winter Menu, Summer Menu)
    """
    supplier = models.ForeignKey(SupplierProfile, on_delete=models.CASCADE, related_name='catalogs')
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'catalogs'
        
    def __str__(self):
        return f"{self.supplier.company_name} - {self.name}"


class CatalogProduct(models.Model):
    """
    Links products to catalogs (many-to-many relationship)
    Allows same product to be in multiple catalogs with different settings
    """
    catalog = models.ForeignKey(Catalog, on_delete=models.CASCADE, related_name='catalog_products')
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='catalog_entries')
    
    # Catalog-specific overrides
    display_order = models.IntegerField(default=0)
    is_featured = models.BooleanField(default=False)
    
    added_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'catalog_products'
        unique_together = ['catalog', 'product']
        ordering = ['display_order', 'added_at']
        
    def __str__(self):
        return f"{self.catalog.name} - {self.product.name}"


class DeliveryOption(models.Model):
    """
    Delivery/pickup options offered by suppliers
    """
    DELIVERY_TYPE_CHOICES = [
        ('delivery', 'Delivery'),
        ('pickup', 'Pickup'),
        ('both', 'Both'),
    ]
    
    supplier = models.ForeignKey(SupplierProfile, on_delete=models.CASCADE, related_name='delivery_options')
    delivery_type = models.CharField(max_length=20, choices=DELIVERY_TYPE_CHOICES)
    
    # Delivery details
    delivery_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    minimum_order_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    delivery_time_hours = models.IntegerField(help_text="Lead time in hours")
    
    # Delivery areas (if applicable)
    delivery_areas = models.TextField(blank=True, null=True, help_text="Comma-separated list of areas")
    
    is_active = models.BooleanField(default=True)
    
    class Meta:
        db_table = 'delivery_options'
        
    def __str__(self):
        return f"{self.supplier.company_name} - {self.get_delivery_type_display()}"