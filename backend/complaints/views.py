from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.views import APIView
from rest_framework.response import Response

from .models import Complaint, ComplaintResponse, ComplaintEscalation, Incident
from .serializers import (
    ComplaintSerializer,
    ComplaintListSerializer,
    ComplaintResponseSerializer,
    ComplaintEscalateSerializer,
    ComplaintStatusUpdateSerializer,
    IncidentSerializer,
    IncidentStatusUpdateSerializer,
)
from accounts.models import ConsumerProfile, SupplierStaff, SupplierProfile, ConsumerSupplierLink


def get_user_role(user, supplier):
    """
    Determine user's role in the supplier organization.
    Returns: 'owner', 'manager', 'sales', or None
    """
    if user.user_type == 'supplier_owner':
        try:
            staff = SupplierStaff.objects.get(user=user, supplier=supplier)
            return 'owner'
        except SupplierStaff.DoesNotExist:
            return None
    elif user.user_type == 'supplier_manager':
        try:
            staff = SupplierStaff.objects.get(user=user, supplier=supplier)
            return 'manager'
        except SupplierStaff.DoesNotExist:
            return None
    elif user.user_type == 'supplier_sales':
        try:
            staff = SupplierStaff.objects.get(user=user, supplier=supplier)
            return 'sales'
        except SupplierStaff.DoesNotExist:
            return None
    return None


def can_user_handle_complaint(user, complaint):
    """
    Check if user can handle complaint at its current escalation level.
    
    Rules:
    - Sales can handle 'sales' level complaints
    - Manager can handle 'sales' and 'manager' level complaints
    - Owner can handle all levels
    """
    role = get_user_role(user, complaint.supplier)
    
    if not role:
        return False
    
    if role == 'owner':
        return True  # Owner can handle all levels
    elif role == 'manager':
        return complaint.escalation_level in ['sales', 'manager']
    elif role == 'sales':
        return complaint.escalation_level == 'sales'
    
    return False


class ComplaintListCreateView(generics.ListCreateAPIView):
    """
    GET:
      - consumer: their own complaints
      - supplier staff: complaints for their supplier
      - superuser: all complaints
    POST:
      - only consumer (user with ConsumerProfile)
    """
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user

        base_qs = Complaint.objects.select_related(
            'consumer', 'supplier', 'order', 'assigned_to', 'escalated_by'
        ).prefetch_related('responses', 'escalation_history').order_by('-created_at')

        # Superuser sees all
        if user.is_superuser:
            return base_qs

        # Supplier staff sees complaints for their supplier
        staff_links = SupplierStaff.objects.filter(user=user).values_list('supplier_id', flat=True)
        if staff_links:
            queryset = base_qs.filter(supplier_id__in=staff_links)
            
            # Filter based on role and escalation level
            role = user.user_type
            if role == 'supplier_sales':
                # Sales only sees sales-level complaints
                queryset = queryset.filter(escalation_level='sales')
            elif role == 'supplier_manager':
                # Manager sees sales and manager level
                queryset = queryset.filter(escalation_level__in=['sales', 'manager'])
            # Owner sees all (no additional filter)
            
            return queryset

        # Consumer sees their own complaints
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            return Complaint.objects.none()

        return base_qs.filter(consumer=consumer_profile)
    
    def get_serializer_class(self):
        if self.request.method == 'GET':
            return ComplaintListSerializer
        return ComplaintSerializer

    def perform_create(self, serializer):
        """
        Create complaint from consumer.
        Automatically assigns to sales representative if available.
        """
        user = self.request.user

        # Check that user has ConsumerProfile
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            raise PermissionDenied("Only consumers can create complaints.")

        supplier = serializer.validated_data.get('supplier')
        order = serializer.validated_data.get('order')

        # If complaint is tied to order, get supplier from order
        if order and not supplier:
            supplier = order.supplier

        if not supplier:
            raise PermissionDenied("Supplier must be specified.")

        # Check for accepted link between consumer and supplier
        has_link = ConsumerSupplierLink.objects.filter(
            consumer=consumer_profile,
            supplier=supplier,
            status='accepted',
        ).exists()

        if not has_link:
            raise PermissionDenied("No approved link with this supplier. Complaint cannot be created.")

        # Try to auto-assign to sales rep
        assigned_to = None
        try:
            link = ConsumerSupplierLink.objects.get(
                consumer=consumer_profile,
                supplier=supplier,
                status='accepted'
            )
            if link.assigned_sales_rep:
                assigned_to = link.assigned_sales_rep.user
        except ConsumerSupplierLink.DoesNotExist:
            pass

        serializer.save(
            consumer=consumer_profile,
            supplier=supplier,
            created_by=user,
            status='open',
            escalation_level='sales',  # Always start at sales level
            assigned_to=assigned_to,
        )


class ComplaintDetailView(generics.RetrieveAPIView):
    """
    Details of a single complaint.
    Access:
      - consumer (only their own)
      - supplier staff (complaints for their supplier, based on role)
      - superuser
    """
    serializer_class = ComplaintSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = 'pk'

    def get_queryset(self):
        user = self.request.user
        base_qs = Complaint.objects.select_related(
            'consumer', 'supplier', 'order', 'assigned_to', 'escalated_by'
        ).prefetch_related('responses', 'escalation_history')

        if user.is_superuser:
            return base_qs

        staff_links = SupplierStaff.objects.filter(user=user).values_list('supplier_id', flat=True)
        if staff_links:
            queryset = base_qs.filter(supplier_id__in=staff_links)
            
            # Apply role-based filtering
            role = user.user_type
            if role == 'supplier_sales':
                queryset = queryset.filter(escalation_level='sales')
            elif role == 'supplier_manager':
                queryset = queryset.filter(escalation_level__in=['sales', 'manager'])
            
            return queryset

        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            return Complaint.objects.none()

        return base_qs.filter(consumer=consumer_profile)


class ComplaintStatusUpdateView(APIView):
    """
    Update complaint status by supplier staff (based on role permissions).
    
    Permissions:
    - Sales can update sales-level complaints
    - Manager can update sales and manager-level complaints
    - Owner can update all complaints
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        user = request.user
        serializer = ComplaintStatusUpdateSerializer(data=request.data)
        
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            complaint = Complaint.objects.select_related('supplier').get(pk=pk)
        except Complaint.DoesNotExist:
            return Response({"detail": "Complaint not found."}, status=status.HTTP_404_NOT_FOUND)

        # Check if user can handle this complaint
        if not user.is_superuser and not can_user_handle_complaint(user, complaint):
            return Response(
                {"detail": "You do not have permission to update this complaint."},
                status=status.HTTP_403_FORBIDDEN
            )

        old_status = complaint.status
        new_status = serializer.validated_data['status']
        new_severity = serializer.validated_data.get('severity')
        internal_note = serializer.validated_data.get('internal_note', '')

        complaint.status = new_status
        if new_severity:
            complaint.severity = new_severity
        complaint.assigned_to = user
        complaint.save()

        # Create internal response if note provided
        if internal_note:
            ComplaintResponse.objects.create(
                complaint=complaint,
                user=user,
                message=internal_note,
                is_internal=True
            )

        return Response(
            {
                "id": complaint.id,
                "old_status": old_status,
                "new_status": complaint.status,
                "escalation_level": complaint.escalation_level,
            },
            status=status.HTTP_200_OK
        )


class ComplaintEscalateView(APIView):
    """
    Escalate complaint to next level.
    
    Permissions:
    - Sales can escalate sales-level complaints to manager
    - Manager can escalate manager-level complaints to owner
    - Owner cannot escalate further
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        user = request.user
        serializer = ComplaintEscalateSerializer(data=request.data)
        
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            complaint = Complaint.objects.select_related('supplier').get(pk=pk)
        except Complaint.DoesNotExist:
            return Response({"detail": "Complaint not found."}, status=status.HTTP_404_NOT_FOUND)

        # Check if user can handle this complaint at current level
        if not user.is_superuser and not can_user_handle_complaint(user, complaint):
            return Response(
                {"detail": "You do not have permission to escalate this complaint."},
                status=status.HTTP_403_FORBIDDEN
            )

        # Check if complaint can be escalated
        if not complaint.can_escalate():
            return Response(
                {"detail": "Complaint is already at the highest escalation level."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Perform escalation
        old_level = complaint.escalation_level
        new_level = complaint.get_next_escalation_level()
        escalation_reason = serializer.validated_data['reason']

        complaint.escalation_level = new_level
        complaint.escalation_reason = escalation_reason
        complaint.escalated_by = user
        complaint.escalated_at = timezone.now()
        complaint.assigned_to = None  # Clear assignment for new level
        complaint.save()

        # Log escalation
        ComplaintEscalation.objects.create(
            complaint=complaint,
            from_level=old_level,
            to_level=new_level,
            reason=escalation_reason,
            escalated_by=user
        )

        # Create internal response
        ComplaintResponse.objects.create(
            complaint=complaint,
            user=user,
            message=f"Complaint escalated from {old_level} to {new_level}. Reason: {escalation_reason}",
            is_internal=True
        )

        return Response(
            {
                "id": complaint.id,
                "old_level": old_level,
                "new_level": new_level,
                "reason": escalation_reason,
                "escalated_at": complaint.escalated_at,
            },
            status=status.HTTP_200_OK
        )


class ComplaintResponseCreateView(generics.CreateAPIView):
    """
    Add a response to a complaint.
    
    Permissions:
    - Supplier staff can add responses to complaints they can handle
    - Consumer can add responses to their own complaints
    """
    serializer_class = ComplaintResponseSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        user = self.request.user
        complaint_id = self.kwargs.get('complaint_id')

        try:
            complaint = Complaint.objects.select_related('consumer', 'supplier').get(pk=complaint_id)
        except Complaint.DoesNotExist:
            raise ValidationError("Complaint not found.")

        # Check permissions
        is_consumer = False
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
            is_consumer = complaint.consumer == consumer_profile
        except ConsumerProfile.DoesNotExist:
            pass

        is_supplier_staff = False
        if not is_consumer:
            is_supplier_staff = can_user_handle_complaint(user, complaint)

        if not user.is_superuser and not is_consumer and not is_supplier_staff:
            raise PermissionDenied("You do not have permission to respond to this complaint.")

        # Consumers cannot add internal notes
        is_internal = serializer.validated_data.get('is_internal', False)
        if is_consumer and is_internal:
            raise PermissionDenied("Consumers cannot add internal notes.")

        serializer.save(
            complaint=complaint,
            user=user
        )


class ComplaintResponseListView(generics.ListAPIView):
    """
    List responses for a complaint.
    
    Permissions:
    - Consumer sees non-internal responses
    - Supplier staff sees all responses (based on role)
    - Superuser sees all responses
    """
    serializer_class = ComplaintResponseSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        complaint_id = self.kwargs.get('complaint_id')

        try:
            complaint = Complaint.objects.select_related('consumer', 'supplier').get(pk=complaint_id)
        except Complaint.DoesNotExist:
            return ComplaintResponse.objects.none()

        base_qs = ComplaintResponse.objects.filter(complaint=complaint).select_related('user')

        # Superuser sees all
        if user.is_superuser:
            return base_qs

        # Consumer sees only non-internal responses
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
            if complaint.consumer == consumer_profile:
                return base_qs.filter(is_internal=False)
        except ConsumerProfile.DoesNotExist:
            pass

        # Supplier staff sees all if they have permission
        if can_user_handle_complaint(user, complaint):
            return base_qs

        return ComplaintResponse.objects.none()


# ============= INCIDENT VIEWS =============

class IncidentListCreateView(generics.ListCreateAPIView):
    """
    GET:
      - supplier staff: incidents for their supplier
      - superuser: all incidents
      - consumer: incidents related to their orders (optional transparency)
    POST:
      - only supplier staff (Manager/Owner) or superuser
    """
    serializer_class = IncidentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        base_qs = Incident.objects.select_related(
            'supplier', 'order', 'complaint', 'created_by'
        ).order_by('-created_at')

        if user.is_superuser:
            return base_qs

        # Supplier staff
        staff_supplier_ids = SupplierStaff.objects.filter(
            user=user
        ).values_list('supplier_id', flat=True)
        if staff_supplier_ids:
            return base_qs.filter(supplier_id__in=staff_supplier_ids)

        # Consumer – incidents related to their orders
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            return Incident.objects.none()

        return base_qs.filter(order__consumer=consumer_profile)

    def perform_create(self, serializer):
        user = self.request.user

        # Only Manager, Owner, or superuser can create incidents
        if not user.is_superuser:
            if user.user_type not in ['supplier_manager', 'supplier_owner']:
                raise PermissionDenied("Only Managers and Owners can create incidents.")

        staff_links = SupplierStaff.objects.filter(user=user)
        if not staff_links.exists() and not user.is_superuser:
            raise PermissionDenied("Only supplier staff or admin can create incidents.")

        supplier = serializer.validated_data.get('supplier')
        order = serializer.validated_data.get('order')

        # Validate supplier matches order
        if order and supplier and order.supplier != supplier:
            raise ValidationError("Incident supplier must match order supplier.")

        if order and not supplier:
            supplier = order.supplier

        if not supplier:
            raise ValidationError("Supplier must be specified.")

        serializer.save(
            supplier=supplier,
            created_by=user,
            status='open',
        )


class IncidentDetailView(generics.RetrieveAPIView):
    """
    Details of a single incident.
    Same access rules as list.
    """
    serializer_class = IncidentSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = 'pk'

    def get_queryset(self):
        user = self.request.user
        base_qs = Incident.objects.select_related('supplier', 'order', 'complaint', 'created_by')

        if user.is_superuser:
            return base_qs

        staff_supplier_ids = SupplierStaff.objects.filter(
            user=user
        ).values_list('supplier_id', flat=True)
        if staff_supplier_ids:
            return base_qs.filter(supplier_id__in=staff_supplier_ids)

        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            return Incident.objects.none()

        return base_qs.filter(order__consumer=consumer_profile)


class IncidentStatusUpdateView(APIView):
    """
    Update incident status (supplier staff or superuser).
    Only Manager and Owner can update incidents.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        user = request.user
        serializer = IncidentStatusUpdateSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            incident = Incident.objects.select_related('supplier').get(pk=pk)
        except Incident.DoesNotExist:
            return Response({"detail": "Incident not found."}, status=status.HTTP_404_NOT_FOUND)

        # Check permissions - only Manager, Owner, or superuser
        if not user.is_superuser:
            if user.user_type not in ['supplier_manager', 'supplier_owner']:
                return Response(
                    {"detail": "Only Managers and Owners can update incidents."},
                    status=status.HTTP_403_FORBIDDEN
                )

            staff_links = SupplierStaff.objects.filter(user=user, supplier=incident.supplier)
            if not staff_links.exists():
                return Response(
                    {"detail": "You cannot update incidents for this supplier."},
                    status=status.HTTP_403_FORBIDDEN
                )

        old_status = incident.status
        new_status = serializer.validated_data['status']

        incident.status = new_status
        incident.save()

        return Response(
            {
                "id": incident.id,
                "old_status": old_status,
                "new_status": incident.status,
            },
            status=status.HTTP_200_OK
        )
