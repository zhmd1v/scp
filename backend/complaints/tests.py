from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model
from .models import Complaint
from accounts.models import ConsumerProfile, SupplierProfile, SupplierStaff

User = get_user_model()

class ComplaintSeverityUpdateTest(TestCase):
    def setUp(self):
        self.client = APIClient()
        
        # Create Supplier
        self.supplier_profile = SupplierProfile.objects.create(
            company_name="Test Supplier",
            city="Test City",
            address="Test Address",
            registration_number="12345"
        )
        
        # Create Manager User
        self.user = User.objects.create_user(username='testuser', email='test@example.com', password='password', user_type='supplier_manager')
        
        # Link Manager to Supplier
        SupplierStaff.objects.create(user=self.user, supplier=self.supplier_profile, position="Manager")
        
        self.client.force_authenticate(user=self.user)
        
        # Create Consumer
        self.consumer_user = User.objects.create_user(username='consumer', email='consumer@example.com', password='password', user_type='consumer')
        self.consumer_profile = ConsumerProfile.objects.create(
            user=self.consumer_user,
            business_name="Test Consumer",
            business_type="restaurant",
            address="Test Address",
            city="Test City"
        )

        self.complaint = Complaint.objects.create(
            title="Test Complaint",
            description="Test Description",
            status="open",
            severity="low",
            created_by=self.user,
            consumer=self.consumer_profile,
            supplier=self.supplier_profile
        )
        self.url = reverse('complaint-status', args=[self.complaint.id])

    def test_update_severity(self):
        data = {
            'status': 'in_progress',
            'severity': 'high'
        }
        response = self.client.post(self.url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        self.complaint.refresh_from_db()
        self.assertEqual(self.complaint.status, 'in_progress')
        self.assertEqual(self.complaint.severity, 'high')
