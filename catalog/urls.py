from django.urls import path
from .views import (
    SupplierProductListView,
    SupplierCatalogListView,
    CatalogDetailView,
)

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
]
