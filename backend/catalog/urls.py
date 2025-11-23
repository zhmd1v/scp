from django.urls import path
from .views import (
    SupplierProductListView,
    SupplierCatalogListView,
    CatalogDetailView,
    ProductCreateView,
    ProductUpdateView,
    ProductDeleteView,
    CategoryViewSet,
)
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register(r'categories', CategoryViewSet, basename='category')

urlpatterns = [
    path(
        'suppliers/<int:supplier_id>/products/',
        SupplierProductListView.as_view(),
        name='supplier-products'
    ),
    path(
        'suppliers/<int:supplier_id>/catalogs/',
        SupplierCatalogListView.as_view(),
        name='supplier-catalogs'
    ),
    path(
        'catalogs/<int:pk>/',
        CatalogDetailView.as_view(),
        name='catalog-detail'
    ),
    # Product CRUD
    path('products/create/', ProductCreateView.as_view(), name='product-create'),
    path('products/<int:pk>/update/', ProductUpdateView.as_view(), name='product-update'),
    path('products/<int:pk>/delete/', ProductDeleteView.as_view(), name='product-delete'),
] + router.urls
