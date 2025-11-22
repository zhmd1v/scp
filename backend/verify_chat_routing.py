import os
import django
from django.conf import settings

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
            'django.contrib.admin',
            'django.contrib.messages',
            'django.contrib.sessions',
            'django.contrib.auth',
            'django.contrib.contenttypes',
            'accounts',
            'catalog',
            'orders',
            'chat',
            'complaints',
        ],
        SECRET_KEY='dummy',
        TIME_ZONE='UTC',
        USE_TZ=True,
        MIDDLEWARE=[
            'django.contrib.sessions.middleware.SessionMiddleware',
            'django.contrib.auth.middleware.AuthenticationMiddleware',
            'django.contrib.messages.middleware.MessageMiddleware',
        ],
        AUTH_USER_MODEL='accounts.User',
        ROOT_URLCONF='scp_project.urls',
    )
    django.setup()

from django.core.management import call_command
from django.test import RequestFactory
from accounts.models import User, SupplierProfile, SupplierStaff, ConsumerProfile, ConsumerSupplierLink
from chat.models import Conversation
from chat.views import ConversationListCreateView
from chat.serializers import ConversationSerializer
from rest_framework.test import APIClient

def run_test():
    print("Setting up test environment...")
    call_command('migrate', verbosity=0)
    
    # Create Users
    print("Creating users...")
    supplier_user = User.objects.create_user(email='supplier@test.com', username='supplier', password='password', user_type='supplier_owner')
    sales_rep_1 = User.objects.create_user(email='sales1@test.com', username='sales1', password='password', user_type='supplier_sales')
    sales_rep_2 = User.objects.create_user(email='sales2@test.com', username='sales2', password='password', user_type='supplier_sales')
    consumer_user = User.objects.create_user(email='consumer@test.com', username='consumer', password='password', user_type='consumer')
    
    # Create Profiles
    supplier_profile = SupplierProfile.objects.create(company_name='Test Supplier', registration_number='123', address='Addr', city='City')
    consumer_profile = ConsumerProfile.objects.create(user=consumer_user, business_name='Test Consumer', business_type='restaurant', address='Addr', city='City')
    
    # Link Staff
    SupplierStaff.objects.create(user=supplier_user, supplier=supplier_profile, position='Owner')
    staff1 = SupplierStaff.objects.create(user=sales_rep_1, supplier=supplier_profile, position='Sales 1')
    staff2 = SupplierStaff.objects.create(user=sales_rep_2, supplier=supplier_profile, position='Sales 2')
    
    # Link Consumer-Supplier (Pending initially)
    ConsumerSupplierLink.objects.create(consumer=consumer_profile, supplier=supplier_profile, status='pending')
    
    print("Users and profiles created.")

    # Helper to create conversation via View
    def create_conversation(consumer_u):
        client = APIClient()
        client.force_authenticate(user=consumer_u)
        data = {'supplier': supplier_profile.id}
        response = client.post('/api/chat/conversations/', data)
        return response

    # Test 1: Approve Link and Check Assignment
    print("\n--- Test 1: Link Approval & Assignment ---")
    # We need to simulate the approval request
    # But first, let's just manually trigger the logic or use the view if possible.
    # Since we are using APIClient, we can call the approve endpoint.
    # We need the link ID.
    link = ConsumerSupplierLink.objects.get(consumer=consumer_profile, supplier=supplier_profile)
    print(f"Link before approval: status={link.status}, assigned={link.assigned_sales_rep}")
    
    # Approve it via API (as supplier owner)
    client = APIClient()
    client.force_authenticate(user=supplier_user)
    response = client.post(f'/api/accounts/links/{link.id}/approve/')
    
    if response.status_code == 200:
        link.refresh_from_db()
        print(f"Link after approval: status={link.status}, assigned={link.assigned_sales_rep}")
        if link.assigned_sales_rep:
            print("SUCCESS: Sales rep assigned on approval!")
            assigned_rep_1 = link.assigned_sales_rep
        else:
            print("FAILURE: No sales rep assigned.")
            return
    else:
        print(f"Failed to approve link: {response.data}")
        return

    # Test 2: Chat Creation uses Assigned Rep
    print("\n--- Test 2: Chat Creation ---")
    response1 = create_conversation(consumer_user)
    if response1.status_code == 201:
        conv1 = Conversation.objects.get(id=response1.data['id'])
        print(f"Conversation created. Assigned to: {conv1.assigned_staff}")
        if conv1.assigned_staff == assigned_rep_1:
             print("SUCCESS: Chat routed to assigned rep.")
        else:
             print(f"FAILURE: Chat routed to {conv1.assigned_staff}, expected {assigned_rep_1}")

    # Test 3: Second Consumer (Load Balancing for Assignment)
    print("\n--- Test 3: Second Consumer Assignment ---")
    consumer_user2 = User.objects.create_user(email='consumer2@test.com', username='consumer2', password='password', user_type='consumer')
    consumer_profile2 = ConsumerProfile.objects.create(user=consumer_user2, business_name='Test Consumer 2', business_type='restaurant', address='Addr', city='City')
    link2 = ConsumerSupplierLink.objects.create(consumer=consumer_profile2, supplier=supplier_profile, status='pending')
    
    # Approve link 2
    response = client.post(f'/api/accounts/links/{link2.id}/approve/')
    
    link2.refresh_from_db()
    print(f"Link 2 assigned to: {link2.assigned_sales_rep}")
    
    if link2.assigned_sales_rep and link2.assigned_sales_rep != assigned_rep_1:
        print("SUCCESS: Second consumer assigned to DIFFERENT rep (load balancing).")
    else:
        print("FAILURE: Load balancing check failed (or random chance if counts equal).")
        print(f"Rep 1 consumers: {ConsumerSupplierLink.objects.filter(assigned_sales_rep=staff1).count()}")
        print(f"Rep 2 consumers: {ConsumerSupplierLink.objects.filter(assigned_sales_rep=staff2).count()}")

if __name__ == "__main__":
    run_test()
