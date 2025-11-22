from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.views import APIView
from rest_framework.response import Response

from .models import Complaint, ComplaintNote, Incident
from .serializers import (
    ComplaintSerializer,
    ComplaintCreateSerializer,
    ComplaintNoteSerializer,
    IncidentSerializer,
)
from accounts.models import ConsumerProfile, SupplierStaff, SupplierProfile, ConsumerSupplierLink
from orders.models import Order


class ComplaintListCreateView(generics.ListCreateAPIView):
    """
    GET:
      - Consumer: their complaints
      - Supplier staff: complaints for their supplier
      - Superuser: all complaints
    POST:
      - Only consumer (user with ConsumerProfile)
    """
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user

        base_qs = Complaint.objects.select_related(
            'consumer', 'supplier', 'order', 
            'created_by', 'assigned_to', 'escalated_by', 'resolved_by'
        ).prefetch_related('notes').order_by('-created_at')

        # Superuser sees all
        if user.is_superuser:
            return base_qs

        # Supplier staff sees complaints for their supplier
        staff_links = SupplierStaff.objects.filter(user=user).values_list('supplier_id', flat=True)
        if staff_links:
            return base_qs.filter(supplier_id__in=staff_links)

        # Consumer sees their own complaints
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            return Complaint.objects.none()

        return base_qs.filter(consumer=consumer_profile)

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ComplaintCreateSerializer
        return ComplaintSerializer

    def perform_create(self, serializer):
        """
        Create complaint from consumer.
        Validates accepted link with supplier.
        Auto-assigns to sales representative if available.
        """
        user = self.request.user

        # Verify consumer profile exists
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            raise PermissionDenied("Only consumers can create complaints.")

        supplier = serializer.validated_data.get('supplier')
        order = serializer.validated_data.get('order')

        # If complaint is tied to an order, use supplier from order
        if order and not supplier:
            supplier = order.supplier

        if not supplier:
            raise ValidationError({"supplier": "Supplier must be specified."})

        # Verify accepted link exists
        has_link = ConsumerSupplierLink.objects.filter(
            consumer=consumer_profile,
            supplier=supplier,
            status='accepted',
        ).exists()

        if not has_link:
            raise PermissionDenied("No approved link with this supplier. Cannot create complaint.")

        # Find sales representative to auto-assign
        sales_rep = SupplierStaff.objects.filter(
            supplier=supplier,
            user__user_type='supplier_sales'
        ).first()

        complaint = serializer.save(
            consumer=consumer_profile,
            supplier=supplier,
            created_by=user,
            status='open',
            escalation_level='sales',
            assigned_to=sales_rep.user if sales_rep else None,
        )

        # Create initial note
        ComplaintNote.objects.create(
            complaint=complaint,
            note_type='comment',
            content=f"Complaint created by {user.email}",
            created_by=user,
            is_visible_to_consumer=True
        )


class ComplaintDetailView(generics.RetrieveAPIView):
    """
    Retrieve details of a single complaint.
    Access:
      - Consumer (only their own)
      - Supplier staff (complaints for their supplier)
      - Superuser
    """
    serializer_class = ComplaintSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = 'pk'

    def get_queryset(self):
        user = self.request.user
        base_qs = Complaint.objects.select_related(
            'consumer', 'supplier', 'order',
            'created_by', 'assigned_to', 'escalated_by', 'resolved_by'
        ).prefetch_related('notes')

        if user.is_superuser:
            return base_qs

        staff_links = SupplierStaff.objects.filter(user=user).values_list('supplier_id', flat=True)
        if staff_links:
            return base_qs.filter(supplier_id__in=staff_links)

        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            return Complaint.objects.none()

        return base_qs.filter(consumer=consumer_profile)


class ComplaintEscalateView(APIView):
    """
    Escalate complaint to next level: Sales → Manager → Owner
    POST /api/complaints/<id>/escalate/
    Body: { "reason": "explanation why escalating" }
    
    Permissions:
    - Sales can escalate to Manager
    - Manager can escalate to Owner
    - Consumer cannot escalate directly (must work through sales/manager)
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        user = request.user

        try:
            complaint = Complaint.objects.select_related('supplier').get(pk=pk)
        except Complaint.DoesNotExist:
            return Response(
                {"detail": "Complaint not found."},
                status=status.HTTP_404_NOT_FOUND
            )

        # Verify user is staff of this supplier
        try:
            staff = SupplierStaff.objects.get(user=user, supplier=complaint.supplier)
        except SupplierStaff.DoesNotExist:
            if not user.is_superuser:
                return Response(
                    {"detail": "You do not have permission to escalate this complaint."},
                    status=status.HTTP_403_FORBIDDEN
                )

        # Check if complaint can be escalated
        if not complaint.can_escalate():
            return Response(
                {"detail": "Complaint cannot be escalated (already at highest level or resolved/closed)."},
                status=status.HTTP_400_BAD_REQUEST
            )

        reason = request.data.get('reason', '')

        # Determine escalation path
        escalation_map = {
            'sales': {
                'next_level': 'manager',
                'new_status': 'escalated_to_manager',
                'target_user_type': 'supplier_manager'
            },
            'manager': {
                'next_level': 'owner',
                'new_status': 'escalated_to_owner',
                'target_user_type': 'supplier_owner'
            }
        }

        current_level = complaint.escalation_level
        
        if current_level not in escalation_map:
            return Response(
                {"detail": "Cannot escalate further."},
                status=status.HTTP_400_BAD_REQUEST
            )

        escalation_info = escalation_map[current_level]
        
        # Find target user to assign to
        target_staff = SupplierStaff.objects.filter(
            supplier=complaint.supplier,
            user__user_type=escalation_info['target_user_type']
        ).first()

        # Update complaint
        old_level = complaint.escalation_level
        old_status = complaint.status
        old_assigned = complaint.assigned_to

        complaint.escalation_level = escalation_info['next_level']
        complaint.status = escalation_info['new_status']
        complaint.escalated_at = timezone.now()
        complaint.escalated_by = user
        complaint.assigned_to = target_staff.user if target_staff else None
        complaint.save()

        # Create escalation note
        note_content = f"Escalated from {old_level} to {escalation_info['next_level']}"
        if reason:
            note_content += f"\nReason: {reason}"

        ComplaintNote.objects.create(
            complaint=complaint,
            note_type='escalation',
            content=note_content,
            created_by=user,
            previous_value=old_level,
            new_value=escalation_info['next_level'],
            is_visible_to_consumer=True
        )

        return Response(
            {
                "id": complaint.id,
                "message": "Complaint escalated successfully",
                "old_level": old_level,
                "new_level": complaint.escalation_level,
                "old_status": old_status,
                "new_status": complaint.status,
                "assigned_to": complaint.assigned_to.email if complaint.assigned_to else None,
            },
            status=status.HTTP_200_OK
        )


class ComplaintStatusUpdateView(APIView):
    """
    Update complaint status.
    POST /api/complaints/<id>/status/
    Body: { "status": "in_progress|resolved|closed", "notes": "optional notes" }
    
    Permissions:
    - Supplier staff (assigned to complaint or higher role)
    - Superuser
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        user = request.user

        try:
            complaint = Complaint.objects.select_related('supplier').get(pk=pk)
        except Complaint.DoesNotExist:
            return Response(
                {"detail": "Complaint not found."},
                status=status.HTTP_404_NOT_FOUND
            )

        # Verify permission
        staff_links = SupplierStaff.objects.filter(user=user, supplier=complaint.supplier)
        if not staff_links.exists() and not user.is_superuser:
            return Response(
                {"detail": "You cannot update this complaint's status."},
                status=status.HTTP_403_FORBIDDEN
            )

        new_status = request.data.get('status')
        notes = request.data.get('notes', '')
        resolution_notes = request.data.get('resolution_notes', '')

        allowed_statuses = ['open', 'in_progress', 'escalated_to_manager', 
                           'escalated_to_owner', 'resolved', 'closed']

        if new_status not in allowed_statuses:
            return Response(
                {"detail": f"Invalid status. Allowed: {allowed_statuses}"},
                status=status.HTTP_400_BAD_REQUEST
            )

        old_status = complaint.status
        complaint.status = new_status

        # If resolving, update resolution fields
        if new_status == 'resolved':
            complaint.resolved_at = timezone.now()
            complaint.resolved_by = user
            if resolution_notes:
                complaint.resolution_notes = resolution_notes

        complaint.save()

        # Create status change note
        note_content = notes if notes else f"Status changed from {old_status} to {new_status}"
        
        ComplaintNote.objects.create(
            complaint=complaint,
            note_type='status_change' if new_status != 'resolved' else 'resolution',
            content=note_content,
            created_by=user,
            previous_value=old_status,
            new_value=new_status,
            is_visible_to_consumer=True
        )

        return Response(
            {
                "id": complaint.id,
                "old_status": old_status,
                "new_status": complaint.status,
                "resolved_at": complaint.resolved_at,
                "resolved_by": complaint.resolved_by.email if complaint.resolved_by else None,
            },
            status=status.HTTP_200_OK
        )


class ComplaintNoteCreateView(generics.CreateAPIView):
    """
    Add a note/comment to a complaint.
    POST /api/complaints/<complaint_id>/notes/
    Body: { "content": "note text", "is_visible_to_consumer": true/false }
    """
    serializer_class = ComplaintNoteSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        user = self.request.user
        complaint_id = self.kwargs.get('complaint_id')

        try:
            complaint = Complaint.objects.select_related('supplier', 'consumer').get(pk=complaint_id)
        except Complaint.DoesNotExist:
            raise ValidationError({"complaint": "Complaint not found."})

        # Check permission - supplier staff or consumer or superuser
        is_staff = SupplierStaff.objects.filter(user=user, supplier=complaint.supplier).exists()
        is_consumer = hasattr(user, 'consumer_profile') and user.consumer_profile == complaint.consumer
        
        if not (is_staff or is_consumer or user.is_superuser):
            raise PermissionDenied("You do not have permission to add notes to this complaint.")

        # Consumers can only add visible comments
        if is_consumer:
            serializer.save(
                complaint=complaint,
                created_by=user,
                note_type='comment',
                is_visible_to_consumer=True
            )
        else:
            serializer.save(
                complaint=complaint,
                created_by=user,
            )


class ComplaintNoteListView(generics.ListAPIView):
    """
    List all notes for a complaint.
    GET /api/complaints/<complaint_id>/notes/
    
    Filters:
    - Consumer sees only visible notes
    - Supplier staff sees all notes
    """
    serializer_class = ComplaintNoteSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        complaint_id = self.kwargs.get('complaint_id')

        try:
            complaint = Complaint.objects.select_related('supplier', 'consumer').get(pk=complaint_id)
        except Complaint.DoesNotExist:
            return ComplaintNote.objects.none()

        # Check access
        is_staff = SupplierStaff.objects.filter(user=user, supplier=complaint.supplier).exists()
        is_consumer = hasattr(user, 'consumer_profile') and user.consumer_profile == complaint.consumer
        
        if not (is_staff or is_consumer or user.is_superuser):
            return ComplaintNote.objects.none()

        notes = ComplaintNote.objects.filter(complaint_id=complaint_id).select_related('created_by')

        # Filter for consumers - only visible notes
        if is_consumer and not is_staff:
            notes = notes.filter(is_visible_to_consumer=True)

        return notes.order_by('created_at')


# ===== Incident Views (keeping existing functionality) =====

class IncidentListCreateView(generics.ListCreateAPIView):
    """
    GET:
      - Supplier staff: incidents for their supplier
      - Superuser: all incidents
      - Consumer: incidents related to their orders (optional transparency)
    POST:
      - Only supplier staff or superuser
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

        # Consumer - incidents related to their orders
        try:
            consumer_profile = ConsumerProfile.objects.get(user=user)
        except ConsumerProfile.DoesNotExist:
            return Incident.objects.none()

        return base_qs.filter(order__consumer=consumer_profile)

    def perform_create(self, serializer):
        user = self.request.user

        # Only staff or superuser can create incidents
        staff_links = SupplierStaff.objects.filter(user=user)
        if not staff_links.exists() and not user.is_superuser:
            raise PermissionDenied("Only supplier staff or admin can create incidents.")

        supplier = serializer.validated_data.get('supplier')
        order = serializer.validated_data.get('order')

        # Validate supplier-order consistency
        if order and supplier and order.supplier != supplier:
            raise ValidationError({"supplier": "Supplier must match the order's supplier."})

        if order and not supplier:
            supplier = order.supplier

        if not supplier:
            raise ValidationError({"supplier": "Supplier must be specified."})

        serializer.save(
            supplier=supplier,
            created_by=user,
            status='open',
        )


class IncidentDetailView(generics.RetrieveAPIView):
    """
    Retrieve details of a single incident.
    Same access rules as list view.
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
    POST /api/incidents/<id>/status/
    Body: { "status": "investigating|mitigated|closed|open" }
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        user = request.user

        try:
            incident = Incident.objects.select_related('supplier').get(pk=pk)
        except Incident.DoesNotExist:
            return Response(
                {"detail": "Incident not found."},
                status=status.HTTP_404_NOT_FOUND
            )

        staff_links = SupplierStaff.objects.filter(user=user, supplier=incident.supplier)
        if not staff_links.exists() and not user.is_superuser:
            return Response(
                {"detail": "You cannot update this incident's status."},
                status=status.HTTP_403_FORBIDDEN
            )

        new_status = request.data.get('status')
        allowed_statuses = ['open', 'investigating', 'mitigated', 'closed']

        if new_status not in allowed_statuses:
            return Response(
                {"detail": f"Invalid status. Allowed: {allowed_statuses}"},
                status=status.HTTP_400_BAD_REQUEST
            )

        old_status = incident.status
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
