# Enhanced Complaints System Documentation

## Overview

The enhanced complaints system implements the escalation workflow defined in the SRS:
**Sales Representative → Manager → Owner**

This system provides structured complaint handling with role-based permissions, automatic assignment, escalation tracking, and comprehensive audit trails.

---

## Key Features

### 1. **Escalation Workflow**
- **First Line (Sales)**: Sales Representatives handle initial complaints
- **Second Line (Manager)**: Escalated for complex issues requiring management oversight
- **Third Line (Owner)**: Final escalation for critical or unresolved complaints

### 2. **Role-Based Permissions**
- **Consumers**: Create complaints, view their own complaints, add comments
- **Sales Representatives**: Handle first-line complaints, escalate to managers
- **Managers**: Handle escalated complaints, escalate to owners
- **Owners**: Handle final-level complaints, full oversight
- **Superusers**: Full access to all complaints

### 3. **Automatic Assignment**
- Complaints automatically assigned to sales representatives when created
- Reassigned to managers/owners when escalated

### 4. **Comprehensive Tracking**
- Status tracking (open, in_progress, escalated, resolved, closed)
- Escalation level tracking (sales, manager, owner)
- Full audit trail via ComplaintNote model
- Resolution tracking with timestamps and responsible users

### 5. **Communication System**
- Notes and comments on complaints
- Visibility control (internal vs consumer-visible notes)
- Automatic notes for status changes and escalations

---

## Database Models

### Complaint Model

```python
class Complaint(models.Model):
    # Relations
    consumer = ForeignKey(ConsumerProfile)
    supplier = ForeignKey(SupplierProfile)
    order = ForeignKey(Order, optional)
    
    # Basic Info
    title = CharField(max_length=200)
    description = TextField()
    complaint_type = CharField(choices=TYPE_CHOICES)
    severity = CharField(choices=SEVERITY_CHOICES)
    
    # Status Tracking
    status = CharField(choices=STATUS_CHOICES)
    escalation_level = CharField(choices=['sales', 'manager', 'owner'])
    
    # Escalation Tracking
    escalated_at = DateTimeField(optional)
    escalated_by = ForeignKey(User, optional)
    
    # Assignment
    created_by = ForeignKey(User)
    assigned_to = ForeignKey(User, optional)
    
    # Resolution
    resolution_notes = TextField(optional)
    resolved_at = DateTimeField(optional)
    resolved_by = ForeignKey(User, optional)
    
    # Timestamps
    created_at = DateTimeField(auto_now_add)
    updated_at = DateTimeField(auto_now)
```

**Status Choices**:
- `open`: Newly created complaint
- `in_progress`: Being actively worked on
- `escalated_to_manager`: Escalated from sales to manager
- `escalated_to_owner`: Escalated from manager to owner
- `resolved`: Issue resolved
- `closed`: Complaint closed

**Severity Choices**: low, medium, high, critical

**Type Choices**: product, delivery, billing, service, other

### ComplaintNote Model

```python
class ComplaintNote(models.Model):
    complaint = ForeignKey(Complaint)
    note_type = CharField(choices=NOTE_TYPE_CHOICES)
    content = TextField()
    created_by = ForeignKey(User)
    created_at = DateTimeField(auto_now_add)
    
    # Change tracking
    previous_value = CharField(optional)
    new_value = CharField(optional)
    
    # Visibility
    is_visible_to_consumer = BooleanField(default=True)
```

**Note Types**:
- `comment`: General comment
- `escalation`: Escalation action
- `status_change`: Status update
- `resolution`: Resolution note
- `internal`: Internal note (not visible to consumer)

---

## API Endpoints

### Complaint Management

#### 1. List/Create Complaints
**GET/POST** `/api/complaints/`

**GET Response**:
```json
[
  {
    "id": 1,
    "consumer": 1,
    "supplier": 2,
    "order": 10,
    "title": "Product quality issue",
    "description": "Received damaged goods",
    "complaint_type": "product",
    "severity": "high",
    "status": "open",
    "escalation_level": "sales",
    "escalated_at": null,
    "escalated_by": null,
    "escalated_by_info": null,
    "created_by": 5,
    "created_by_info": {
      "id": 5,
      "email": "consumer@example.com",
      "username": "consumer1",
      "user_type": "consumer"
    },
    "assigned_to": 7,
    "assigned_to_info": {
      "id": 7,
      "email": "sales@supplier.com",
      "username": "sales_rep",
      "user_type": "supplier_sales"
    },
    "resolution_notes": null,
    "resolved_at": null,
    "resolved_by": null,
    "resolved_by_info": null,
    "created_at": "2025-11-22T10:30:00Z",
    "updated_at": "2025-11-22T10:30:00Z",
    "notes": [
      {
        "id": 1,
        "note_type": "comment",
        "content": "Complaint created",
        "created_by_info": {...},
        "created_at": "2025-11-22T10:30:00Z",
        "is_visible_to_consumer": true
      }
    ],
    "can_escalate": true
  }
]
```

**POST Request** (Consumer only):
```json
{
  "supplier": 2,
  "order": 10,  // optional
  "title": "Product quality issue",
  "description": "Received damaged goods",
  "complaint_type": "product",
  "severity": "high"
}
```

**POST Response**: Created complaint object (201 Created)

**Permissions**:
- GET: Consumer (own complaints), Supplier Staff (supplier's complaints), Superuser (all)
- POST: Consumer only

---

#### 2. Complaint Details
**GET** `/api/complaints/<id>/`

**Response**: Single complaint object with nested notes

**Permissions**: Consumer (own), Supplier Staff (supplier's), Superuser (all)

---

#### 3. Escalate Complaint
**POST** `/api/complaints/<id>/escalate/`

**Request**:
```json
{
  "reason": "Unable to resolve at sales level, requires manager attention"
}
```

**Response**:
```json
{
  "id": 1,
  "message": "Complaint escalated successfully",
  "old_level": "sales",
  "new_level": "manager",
  "old_status": "in_progress",
  "new_status": "escalated_to_manager",
  "assigned_to": "manager@supplier.com"
}
```

**Escalation Rules**:
- Sales → Manager: Changes `escalation_level` to "manager", status to "escalated_to_manager"
- Manager → Owner: Changes `escalation_level` to "owner", status to "escalated_to_owner"
- Automatically reassigns to appropriate role
- Creates escalation note in audit trail

**Permissions**: Supplier staff at current escalation level or superuser

---

#### 4. Update Complaint Status
**POST** `/api/complaints/<id>/status/`

**Request**:
```json
{
  "status": "resolved",
  "notes": "Replaced damaged items and issued partial refund",
  "resolution_notes": "Final resolution: Replaced all damaged goods with fresh products. Issued 10% discount on next order as compensation."
}
```

**Response**:
```json
{
  "id": 1,
  "old_status": "in_progress",
  "new_status": "resolved",
  "resolved_at": "2025-11-22T15:45:00Z",
  "resolved_by": "sales@supplier.com"
}
```

**Allowed Statuses**: open, in_progress, escalated_to_manager, escalated_to_owner, resolved, closed

**Special Behavior**:
- Setting status to "resolved" automatically sets `resolved_at` and `resolved_by`
- Creates status change note in audit trail

**Permissions**: Supplier staff assigned to complaint or higher role, superuser

---

### Complaint Notes

#### 5. List Complaint Notes
**GET** `/api/complaints/<complaint_id>/notes/`

**Response**:
```json
[
  {
    "id": 1,
    "complaint": 1,
    "note_type": "comment",
    "content": "Complaint created by consumer@example.com",
    "created_by": 5,
    "created_by_info": {
      "id": 5,
      "email": "consumer@example.com",
      "username": "consumer1",
      "user_type": "consumer"
    },
    "created_at": "2025-11-22T10:30:00Z",
    "previous_value": null,
    "new_value": null,
    "is_visible_to_consumer": true
  },
  {
    "id": 2,
    "note_type": "escalation",
    "content": "Escalated from sales to manager\nReason: Complex issue requiring management oversight",
    "created_by": 7,
    "created_by_info": {...},
    "created_at": "2025-11-22T12:15:00Z",
    "previous_value": "sales",
    "new_value": "manager",
    "is_visible_to_consumer": true
  }
]
```

**Filtering**:
- Consumers see only notes where `is_visible_to_consumer=true`
- Supplier staff see all notes

**Permissions**: Consumer (visible notes only), Supplier Staff (all notes), Superuser (all)

---

#### 6. Create Complaint Note
**POST** `/api/complaints/<complaint_id>/notes/create/`

**Request**:
```json
{
  "content": "Customer called to follow up on the issue",
  "note_type": "comment",
  "is_visible_to_consumer": false  // optional, for internal notes
}
```

**Response**: Created note object (201 Created)

**Note**: Consumers can only create visible comments (type=comment, is_visible_to_consumer=true)

**Permissions**: Consumer (complaint creator), Supplier Staff, Superuser

---

### Incidents (Unchanged)

#### 7. List/Create Incidents
**GET/POST** `/api/incidents/`

Similar to complaints but for internal incident tracking. Used by supplier staff to log systemic issues.

---

#### 8. Incident Details
**GET** `/api/incidents/<id>/`

---

#### 9. Update Incident Status
**POST** `/api/incidents/<id>/status/`

**Request**:
```json
{
  "status": "investigating"  // open, investigating, mitigated, closed
}
```

---

## Implementation Guide

### 1. **Migration**

Run the migration to add new fields:

```bash
python manage.py makemigrations complaints
python manage.py migrate complaints
```

### 2. **URL Configuration**

Update your main `urls.py` to use the enhanced URLs:

```python
# scp_project/urls.py
from django.urls import path, include

urlpatterns = [
    # ... other patterns
    path('api/', include('complaints.urls_enhanced')),  # Use enhanced URLs
]
```

### 3. **Admin Interface**

Update `complaints/admin.py`:

```python
# complaints/admin.py
from .admin_enhanced import ComplaintAdmin, ComplaintNoteAdmin, IncidentAdmin
```

Or simply replace the content with imports from `admin_enhanced.py`.

### 4. **Views**

Update `complaints/views.py` or use the enhanced views:

```python
# complaints/views.py
from .views_enhanced import *
```

---

## Usage Examples

### Example 1: Consumer Creates Complaint

```python
# POST /api/complaints/
{
  "supplier": 2,
  "order": 15,
  "title": "Late delivery",
  "description": "Order was supposed to arrive on Nov 20, still not received",
  "complaint_type": "delivery",
  "severity": "medium"
}

# System automatically:
# - Assigns to sales representative
# - Sets escalation_level = 'sales'
# - Sets status = 'open'
# - Creates initial note
```

### Example 2: Sales Rep Handles Complaint

```python
# 1. Update status to in_progress
POST /api/complaints/1/status/
{
  "status": "in_progress",
  "notes": "Contacted delivery team, investigating delay"
}

# 2. Add internal note
POST /api/complaints/1/notes/create/
{
  "content": "Delivery was delayed due to weather. ETA: tomorrow morning",
  "note_type": "internal",
  "is_visible_to_consumer": false
}

# 3. If unable to resolve, escalate
POST /api/complaints/1/escalate/
{
  "reason": "Delivery has been delayed 3+ days, requires manager approval for compensation"
}
# System automatically assigns to manager
```

### Example 3: Manager Resolves Complaint

```python
# 1. Review escalated complaint
GET /api/complaints/1/

# 2. Add resolution
POST /api/complaints/1/status/
{
  "status": "resolved",
  "resolution_notes": "Approved 20% discount on next order. Delivery completed Nov 23.",
  "notes": "Applied compensation policy due to extended delay"
}

# System sets resolved_at and resolved_by automatically
```

### Example 4: Critical Issue Escalation

```python
# Sales → Manager
POST /api/complaints/5/escalate/
{
  "reason": "Food safety issue reported, requires immediate management attention"
}

# Manager → Owner
POST /api/complaints/5/escalate/
{
  "reason": "Critical food safety issue, potential liability, owner decision required"
}

# Owner resolves
POST /api/complaints/5/status/
{
  "status": "resolved",
  "resolution_notes": "All affected products recalled. Full refund issued. Enhanced quality controls implemented.",
  "notes": "Conducted full investigation and implemented preventive measures"
}
```

---

## Permission Matrix

| Action | Consumer | Sales | Manager | Owner | Superuser |
|--------|----------|-------|---------|-------|-----------|
| Create Complaint | ✓ (own) | ✗ | ✗ | ✗ | ✓ |
| View Complaints | ✓ (own) | ✓ (supplier) | ✓ (supplier) | ✓ (supplier) | ✓ (all) |
| Update Status | ✗ | ✓ (assigned) | ✓ (assigned) | ✓ (assigned) | ✓ |
| Escalate (Sales→Manager) | ✗ | ✓ | ✗ | ✗ | ✓ |
| Escalate (Manager→Owner) | ✗ | ✗ | ✓ | ✗ | ✓ |
| Add Note | ✓ (visible only) | ✓ (all) | ✓ (all) | ✓ (all) | ✓ (all) |
| View Notes | ✓ (visible only) | ✓ (all) | ✓ (all) | ✓ (all) | ✓ (all) |
| Create Incident | ✗ | ✓ | ✓ | ✓ | ✓ |

---

## Best Practices

### 1. **Complaint Creation**
- Always provide clear, detailed descriptions
- Link to relevant orders when applicable
- Set appropriate severity level

### 2. **Escalation**
- Escalate only when current level cannot resolve
- Provide clear reason for escalation
- Document attempted resolution steps before escalating

### 3. **Status Updates**
- Update status promptly as work progresses
- Add notes explaining status changes
- Use resolution_notes for final resolutions

### 4. **Internal Communication**
- Use internal notes for sensitive information
- Keep consumer-visible notes professional and informative
- Document all significant actions in notes

### 5. **Resolution**
- Provide complete resolution notes
- Ensure consumer is satisfied before closing
- Document lessons learned for future prevention

---

## Testing

### Unit Tests

Create tests for:
1. Complaint creation with automatic assignment
2. Escalation workflow (sales→manager→owner)
3. Permission checks for each role
4. Note visibility for consumers vs staff
5. Status transitions
6. Resolution tracking

### Integration Tests

Test complete workflows:
1. End-to-end complaint resolution
2. Multi-level escalation
3. Role-based access control
4. Note creation and visibility

---

## Monitoring and Metrics

### Key Metrics to Track

1. **Response Time**: Time from complaint creation to first response
2. **Resolution Time**: Time from creation to resolution
3. **Escalation Rate**: Percentage of complaints escalated
4. **Escalation Level Distribution**: sales/manager/owner breakdown
5. **Resolution Rate**: Percentage resolved vs closed without resolution
6. **Repeat Complaints**: Same consumer/supplier pairs
7. **Average Notes per Complaint**: Indicator of complexity

### Dashboard Queries

```python
# Complaints by status
Complaint.objects.values('status').annotate(count=Count('id'))

# Complaints by escalation level
Complaint.objects.values('escalation_level').annotate(count=Count('id'))

# Average resolution time
Complaint.objects.filter(
    status='resolved'
).annotate(
    resolution_time=F('resolved_at') - F('created_at')
).aggregate(avg_time=Avg('resolution_time'))

# Escalation rate
total = Complaint.objects.count()
escalated = Complaint.objects.filter(
    escalation_level__in=['manager', 'owner']
).count()
escalation_rate = (escalated / total) * 100
```

---

## Troubleshooting

### Issue: Complaint not auto-assigned

**Cause**: No sales representative found for supplier

**Solution**: Ensure supplier has at least one staff member with `user_type='supplier_sales'`

### Issue: Cannot escalate complaint

**Cause**: 
- Already at highest level (owner)
- Complaint is resolved/closed
- User doesn't have permission

**Solution**: Check `can_escalate` field in response, verify status and escalation_level

### Issue: Consumer can't see notes

**Cause**: Notes marked as `is_visible_to_consumer=false`

**Solution**: Only staff can see internal notes. This is by design.

### Issue: Wrong user type trying to escalate

**Cause**: Permission denied based on role

**Solution**: 
- Sales can only escalate to manager
- Manager can only escalate to owner
- Ensure user has correct `user_type`

---

## Future Enhancements

Potential improvements:

1. **SLA Tracking**: Automatic warnings for complaints approaching SLA deadlines
2. **Email Notifications**: Notify users on escalation, status changes, resolution
3. **Templates**: Predefined response templates for common complaint types
4. **Analytics Dashboard**: Visual dashboards for complaint metrics
5. **AI-Powered Classification**: Automatic complaint type and severity detection
6. **Consumer Satisfaction**: Post-resolution satisfaction surveys
7. **Bulk Operations**: Bulk status updates, assignments
8. **File Attachments**: Support for images, documents in complaints and notes
9. **Related Complaints**: Link similar complaints for pattern detection
10. **Custom Workflows**: Configurable escalation rules per supplier

---

## Support

For questions or issues:
1. Check this documentation
2. Review SRS document section 3.2.3 (Order Management) and 7 (Incident Management)
3. Examine test cases in `complaints/tests.py`
4. Contact development team

---

**Version**: 2.0  
**Last Updated**: November 22, 2025  
**Author**: SCP Development Team
