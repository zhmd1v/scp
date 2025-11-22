import os
import django
from decimal import Decimal

import os
import django
from django.conf import settings
from decimal import Decimal

# Configure settings manually to use SQLite
if not settings.configured:
    settings.configure(
        DATABASES={
            'default': {
                'ENGINE': 'django.db.backends.sqlite3',
                'NAME': ':memory:',
            }
        },
        INSTALLED_APPS=[
            'django.contrib.auth',
            'django.contrib.contenttypes',
            'accounts',
            'catalog',
            'orders',
        ],
        SECRET_KEY='dummy',
        TIME_ZONE='UTC',
        USE_TZ=True,
        AUTH_USER_MODEL='accounts.User',
    )
django.setup()

# Now we can import models
from django.core.management import call_command
# Create tables
call_command('migrate', verbosity=0)

from orders.serializers import OrderSerializer
from accounts.models import SupplierProfile, ConsumerProfile
from catalog.models import Product
from django.contrib.auth import get_user_model

User = get_user_model()

def run():
    print("Setting up test data...")
    
    # Create users directly (DB is empty)
    user_s = User.objects.create_user(email='supplier@test.debug', username='supplier_test_debug', password='password')
    user_c = User.objects.create_user(email='consumer@test.debug', username='consumer_test_debug', password='password')
    print(f"Type of user_c: {type(user_c)}")
    print(f"Value of user_c: {user_c}")
    
    # Create or get profiles
    # SupplierProfile does not have a user field directly
    supplier, _ = SupplierProfile.objects.get_or_create(
        company_name='Supplier Test Debug',
        defaults={
            'registration_number': '123',
            'address': 'Addr',
            'city': 'City'
        }
    )
    consumer, _ = ConsumerProfile.objects.get_or_create(user=user_c, defaults={'business_name': 'Consumer Test Debug', 'business_type': 'restaurant', 'address': 'Addr', 'city': 'City'})
    
    # Create or get product
    product, _ = Product.objects.get_or_create(
        supplier=supplier, 
        name='Product Test Debug', 
        defaults={'unit_price': 100, 'stock_quantity': 100}
    )

    print(f"Supplier ID: {supplier.id}")
    print(f"Product ID: {product.id}")

    # Payload mimicking Flutter
    data = {
        "supplier_id": supplier.id,
        "delivery_address": "Some address",
        # "requested_delivery_date": "2023-10-27", # Optional
        "notes": "Some notes",
        "items": [
            {
                # "product_id": product.id, # Test if this triggers "This field is required"
                "quantity": 5.0,
                "unit_price": 100.0,
                "remark": "Some remark"
            }
        ]
    }

    print("Validating data:", data)

    # We need to pass context with request if the serializer uses it (e.g. for user)
    # But OrderSerializer.create uses request.user for history. 
    # Validation might not need it unless there is a validator relying on it.
    # OrderSerializer doesn't seem to use request in validate(), only in create().
    
    serializer = OrderSerializer(data=data)
    
    if not serializer.is_valid():
        print("\n!!! VALIDATION ERRORS !!!")
        print(serializer.errors)
    else:
        print("\nValidation Successful!")
        # We can try to save to see if create() fails
        try:
            # We need to mock request in context for create()
            from unittest.mock import Mock
            request = Mock()
            request.user = user_c
            serializer.context['request'] = request
            
            # We also need to set consumer manually as perform_create does
            serializer.save(consumer=consumer)
            print("Order created successfully!")
        except Exception as e:
            print(f"Creation failed: {e}")

if __name__ == "__main__":
    run()
