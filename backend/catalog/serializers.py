from rest_framework import serializers
from .models import (
    Category,
    Product,
    ProductImage,
    ProductDiscount,
    Catalog,
    CatalogProduct,
    DeliveryOption,
)


class CategorySerializer(serializers.ModelSerializer):
    parent_id = serializers.IntegerField(source="parent.id", read_only=True)
    parent_name = serializers.CharField(source="parent.name", read_only=True)

    class Meta:
        model = Category
        fields = [
            "id",
            "name",
            "description",
            "parent",       # writable
            "parent_id",    # read-only
            "parent_name",  # read-only
            "created_at"
        ]

class ProductSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)
    
    class Meta:
        model = Product
        fields = '__all__'


class DeliveryOptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeliveryOption
        fields = '__all__'


class CatalogProductSerializer(serializers.ModelSerializer):
    """
    Для связи 'каталог–товар' (если нужно будет отдельно).
    """
    class Meta:
        model = CatalogProduct
        fields = '__all__'


class CatalogWithProductsSerializer(serializers.ModelSerializer):
    """
    Каталог + вложенный список продуктов.
    """
    products = serializers.SerializerMethodField()

    class Meta:
        model = Catalog
        fields = ['id', 'name', 'supplier', 'is_active', 'created_at', 'products']

    def get_products(self, obj):
        # берём все записи CatalogProduct для данного каталога
        catalog_products = CatalogProduct.objects.select_related('product').filter(catalog=obj)
        products = [cp.product for cp in catalog_products]
        return ProductSerializer(products, many=True).data
