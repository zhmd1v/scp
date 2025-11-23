from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.exceptions import PermissionDenied
from rest_framework.generics import CreateAPIView, UpdateAPIView, DestroyAPIView
from rest_framework.permissions import BasePermission
from rest_framework import viewsets, permissions
from .models import Category
from .serializers import CategorySerializer

from .models import Product, Catalog, Category
from .serializers import (
    ProductSerializer,
    CatalogWithProductsSerializer,
    CategorySerializer,
)

from accounts.models import (
    SupplierProfile,
    SupplierStaff,
    ConsumerProfile,
    ConsumerSupplierLink,
)



class SupplierProductListView(generics.ListAPIView):
    """
    Список всех продуктов конкретного поставщика.
    Доступ:
      - superuser
      - staff этого поставщика
      - consumer с accepted-линком к этому поставщику
    """
    serializer_class = ProductSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        supplier_id = self.kwargs.get('supplier_id')
        user = self.request.user

        base_qs = Product.objects.filter(supplier_id=supplier_id).select_related('category')

        # 1) суперюзер видит всё
        if user.is_superuser:
            return base_qs

        # 2) staff этого поставщика
        if SupplierStaff.objects.filter(user=user, supplier_id=supplier_id).exists():
            return base_qs

        # 3) consumer с accepted-линком
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            raise PermissionDenied("У вас нет доступа к каталогу этого поставщика (нет ConsumerProfile).")

        has_link = ConsumerSupplierLink.objects.filter(
            consumer=consumer_profile,
            supplier_id=supplier_id,
            status='accepted',
        ).exists()

        if not has_link:
            raise PermissionDenied("Нет одобренной связи с этим поставщиком.")

        return base_qs


class SupplierCatalogListView(generics.ListAPIView):
    """
    Список всех активных каталогов конкретного поставщика.
    Те же правила доступа, что и к продуктам.
    """
    serializer_class = CatalogWithProductsSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        supplier_id = self.kwargs.get('supplier_id')
        user = self.request.user

        base_qs = Catalog.objects.filter(supplier_id=supplier_id, is_active=True)

        # 1) суперюзер
        if user.is_superuser:
            return base_qs

        # 2) staff этого поставщика
        if SupplierStaff.objects.filter(user=user, supplier_id=supplier_id).exists():
            return base_qs

        # 3) consumer с accepted-линком
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            raise PermissionDenied("У вас нет доступа к каталогам этого поставщика (нет ConsumerProfile).")

        has_link = ConsumerSupplierLink.objects.filter(
            consumer=consumer_profile,
            supplier_id=supplier_id,
            status='accepted',
        ).exists()

        if not has_link:
            raise PermissionDenied("Нет одобренной связи с этим поставщиком.")

        return base_qs



class CatalogDetailView(generics.RetrieveAPIView):
    """
    Один каталог + вложенные продукты.
    Доступ только если пользователь имеет право видеть каталоги этого поставщика.
    """
    serializer_class = CatalogWithProductsSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = 'pk'

    def get_queryset(self):
        user = self.request.user
        base_qs = Catalog.objects.all().select_related('supplier')

        # 1) суперюзер
        if user.is_superuser:
            return base_qs

        # 2) staff: собираем supplier_id для этого пользователя
        staff_supplier_ids = SupplierStaff.objects.filter(
            user=user
        ).values_list('supplier_id', flat=True)

        if staff_supplier_ids:
            return base_qs.filter(supplier_id__in=staff_supplier_ids)

        # 3) consumer: собираем поставщиков, с которыми есть accepted-линк
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            # вообще ничего не видит
            return Catalog.objects.none()

        accepted_supplier_ids = ConsumerSupplierLink.objects.filter(
            consumer=consumer_profile,
            status='accepted',
        ).values_list('supplier_id', flat=True)

        return base_qs.filter(supplier_id__in=accepted_supplier_ids, is_active=True)


class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all().order_by("name")
    serializer_class = CategorySerializer
    permission_classes = [permissions.IsAuthenticated]


class IsSupplierManagerOrOwner(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and (
            request.user.user_type in ['supplier_manager', 'supplier_owner'] or request.user.is_superuser
        )

class ProductCreateView(CreateAPIView):
    serializer_class = ProductSerializer
    permission_classes = [IsSupplierManagerOrOwner]

    def perform_create(self, serializer):
        user = self.request.user
        supplier_id = self.request.data.get('supplier')
        # Only allow managers/owners to add products for their supplier
        if not user.is_superuser and not SupplierStaff.objects.filter(user=user, supplier_id=supplier_id).exists():
            raise PermissionDenied('You can only add products for your own supplier.')
        serializer.save()

class ProductUpdateView(UpdateAPIView):
    serializer_class = ProductSerializer
    permission_classes = [IsSupplierManagerOrOwner]
    queryset = Product.objects.all()

    def get_object(self):
        obj = super().get_object()
        user = self.request.user
        if not user.is_superuser and not SupplierStaff.objects.filter(user=user, supplier=obj.supplier).exists():
            raise PermissionDenied('You can only edit products for your own supplier.')
        return obj

class ProductDeleteView(DestroyAPIView):
    serializer_class = ProductSerializer
    permission_classes = [IsSupplierManagerOrOwner]
    queryset = Product.objects.all()

    def get_object(self):
        obj = super().get_object()
        user = self.request.user
        if not user.is_superuser and not SupplierStaff.objects.filter(user=user, supplier=obj.supplier).exists():
            raise PermissionDenied('You can only delete products for your own supplier.')
        return obj
