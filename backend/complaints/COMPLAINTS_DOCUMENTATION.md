# Complaints System with Escalation Level - Implementation Documentation

## Overview

This implementation provides a comprehensive complaints management system following the SRS requirements for the Supplier Consumer Platform (SCP). The system implements a three-tier escalation workflow: **Sales Representative → Manager → Owner**.

## Key Features

### 1. Escalation Levels

The complaints system implements a hierarchical escalation structure:

- **Sales Level**: First-line complaint handling by Sales Representatives
- **Manager Level**: Escalated complaints requiring managerial intervention
- **Owner Level**: Final escalation level for critical or unresolved issues

### 2. Role-Based Access Control

Access to complaints is strictly controlled based on user roles:

#### Sales Representative
- Can view and handle complaints at the **sales level** only
- Can escalate complaints to **manager level**
- Can respond to complaints assigned to them
- Cannot view manager or owner level complaints

#### Manager
- Can view and handle complaints at **sales** and **manager** levels
- Can escalate complaints to **owner level**
- Can respond to complaints at sales and manager levels
- Has oversight of sales representatives' work

#### Owner
- Can view and handle complaints at **all levels**
- Cannot escalate further (highest level)
- Has full oversight of the entire complaints system
- Can intervene at any level

### 3. Auto-Assignment

When a consumer creates a complaint:
- The complaint automatically starts at the **sales level**
- If a sales representative is assigned to the consumer-supplier link, they are auto-assigned to the complaint
- This ensures immediate ownership and accountability

## API Endpoints

### Complaint Endpoints

#### 1. List/Create Complaints
```
GET/POST /api/complaints/
```

**GET Response** (role-based filtering):
- Sales: Only sees sales-level complaints
- Manager: Sees sales and manager-level complaints
- Owner: Sees all complaints
- Consumer: Sees their own complaints

**POST Request** (Consumer only):
```json
{
  "supplier": 1,
  "order": 5,  // optional
  "title": "Product quality issue",
  "description": "Detailed description of the issue",
  "complaint_type": "product",  // product, delivery, billing, service, other
  "severity": "high"  // low, medium, high, critical
}
```

**Response**:
```json
{
  "id": 123,
  "consumer": 1,
  "consumer_name": "Restaurant ABC",
  "supplier": 2,
  "supplier_name": "Fresh Foods Ltd",
  "order": 5,
  "title": "Product quality issue",
  "description": "Detailed description",
  "complaint_type": "product",
  "severity": "high",
  "status": "open",
  "escalation_level": "sales",
  "escalation_reason": null,
  "assigned_to": 10,
  "assigned_to_email": "sales@freshfoods.com",
  "can_escalate": true,
  "next_escalation_level": "manager",
  "created_at": "2025-11-22T12:00:00Z",
  "updated_at": "2025-11-22T12:00:00Z"
}
```

#### 2. Get Complaint Details
```
GET /api/complaints/<id>/
```

Returns detailed complaint information including:
- All basic complaint data
- Response history (filtered by permissions)
- Escalation history
- Can escalate status
- Next escalation level

#### 3. Update Complaint Status
```
POST /api/complaints/<id>/status/
```

**Request**:
```json
{
  "status": "in_progress",  // open, in_progress, resolved, closed
  "internal_note": "Working on resolution"  // optional
}
```

**Permissions**:
- Sales: Can update sales-level complaints
- Manager: Can update sales and manager-level complaints
- Owner: Can update all complaints

#### 4. Escalate Complaint
```
POST /api/complaints/<id>/escalate/
```

**Request**:
```json
{
  "reason": "Issue requires manager intervention due to complexity"
}
```

**Response**:
```json
{
  "id": 123,
  "old_level": "sales",
  "new_level": "manager",
  "reason": "Issue requires manager intervention",
  "escalated_at": "2025-11-22T14:30:00Z"
}
```

**Permissions**:
- Sales can escalate sales → manager
- Manager can escalate manager → owner
- Owner cannot escalate further

#### 5. Add Response to Complaint
```
POST /api/complaints/<complaint_id>/responses/create/
```

**Request**:
```json
{
  "message": "We are investigating this issue",
  "is_internal": false,  // true for internal notes
  "attachment": null  // optional file upload
}
```

**Permissions**:
- Supplier staff: Can add responses to complaints they can handle
- Consumer: Can add non-internal responses to their complaints

#### 6. List Complaint Responses
```
GET /api/complaints/<complaint_id>/responses/
```

**Permissions**:
- Consumer: Sees only non-internal responses
- Supplier staff: Sees all responses (if they have access to the complaint)

### Incident Endpoints

#### 1. List/Create Incidents
```
GET/POST /api/incidents/
```

**POST Permissions**: Only Manager, Owner, or Superuser

**Request**:
```json
{
  "supplier": 2,
  "order": 5,  // optional
  "complaint": 123,  // optional
  "title": "System-wide delivery delay",
  "description": "Detailed incident description",
  "severity": "critical"
}
```

#### 2. Get Incident Details
```
GET /api/incidents/<id>/
```

#### 3. Update Incident Status
```
POST /api/incidents/<id>/status/
```

**Request**:
```json
{
  "status": "investigating"  // open, investigating, mitigated, closed
}
```

**Permissions**: Only Manager, Owner, or Superuser

## Database Models

### Complaint Model

```python
class Complaint(models.Model):
    # Basic Info
    consumer = ForeignKey(ConsumerProfile)
    supplier = ForeignKey(SupplierProfile)
    order = ForeignKey(Order, null=True, blank=True)
    title = CharField(max_length=200)
    description = TextField()
    
    # Classification
    complaint_type = CharField(choices=TYPE_CHOICES)
    severity = CharField(choices=SEVERITY_CHOICES)
    status = CharField(choices=STATUS_CHOICES)
    
    # Escalation Management
    escalation_level = CharField(choices=ESCALATION_LEVEL_CHOICES, default='sales')
    escalation_reason = TextField(null=True, blank=True)
    
    # Assignment & Tracking
    created_by = ForeignKey(User)
    assigned_to = ForeignKey(User, null=True, blank=True)
    escalated_by = ForeignKey(User, null=True, blank=True)
    
    # Timestamps
    created_at = DateTimeField(auto_now_add=True)
    updated_at = DateTimeField(auto_now=True)
    escalated_at = DateTimeField(null=True, blank=True)
```

### ComplaintResponse Model

Tracks all responses/comments on a complaint:

```python
class ComplaintResponse(models.Model):
    complaint = ForeignKey(Complaint)
    user = ForeignKey(User)
    message = TextField()
    is_internal = BooleanField(default=False)
    attachment = FileField(null=True, blank=True)
    created_at = DateTimeField(auto_now_add=True)
```

### ComplaintEscalation Model

Audit trail for all escalation events:

```python
class ComplaintEscalation(models.Model):
    complaint = ForeignKey(Complaint)
    from_level = CharField(max_length=20)
    to_level = CharField(max_length=20)
    reason = TextField()
    escalated_by = ForeignKey(User)
    escalated_at = DateTimeField(auto_now_add=True)
```

## Workflow Examples

### Example 1: Standard Complaint Flow

1. **Consumer creates complaint**
   - Complaint created at sales level
   - Auto-assigned to sales rep (if available)
   - Status: "open"

2. **Sales rep attempts resolution**
   - Updates status to "in_progress"
   - Adds responses
   - If resolved: Updates status to "resolved"

3. **If unresolved: Escalation to Manager**
   - Sales rep escalates with reason
   - Complaint moves to manager level
   - Status may change to "in_progress"
   - Manager is notified

4. **Manager handles escalation**
   - Reviews history
   - Takes appropriate action
   - If resolved: Updates status to "resolved"
   - If still unresolved: Escalates to Owner

5. **Owner final resolution**
   - Reviews entire history
   - Makes final decision
   - Updates status to "resolved" or "closed"

### Example 2: Critical Issue Fast-Track

1. Consumer creates high/critical severity complaint
2. Sales rep immediately recognizes need for manager
3. Sales rep escalates to manager with detailed reason
4. Manager assesses and may escalate to owner if necessary
5. Owner provides strategic resolution

## Permission Matrix

| Action | Sales | Manager | Owner | Consumer |
|--------|-------|---------|-------|----------|
| Create Complaint | ❌ | ❌ | ❌ | ✅ |
| View Sales Level | ✅ | ✅ | ✅ | ✅* |
| View Manager Level | ❌ | ✅ | ✅ | ✅* |
| View Owner Level | ❌ | ❌ | ✅ | ✅* |
| Update Status (Sales) | ✅ | ✅ | ✅ | ❌ |
| Update Status (Manager) | ❌ | ✅ | ✅ | ❌ |
| Update Status (Owner) | ❌ | ❌ | ✅ | ❌ |
| Escalate Sales→Manager | ✅ | ✅ | ✅ | ❌ |
| Escalate Manager→Owner | ❌ | ✅ | ✅ | ❌ |
| Add Response | ✅† | ✅† | ✅† | ✅ |
| View Internal Notes | ✅† | ✅† | ✅† | ❌ |
| Create Incident | ❌ | ✅ | ✅ | ❌ |

*Consumer can only view their own complaints
†Only for complaints they have access to

## Frontend Integration

### Flutter/React Native Consumer App

**Consumer Complaint Creation Flow**:
```dart
// 1. Consumer selects supplier and optionally order
// 2. Fills complaint form
// 3. Submits complaint

Future<void> createComplaint(ComplaintData data) async {
  final response = await api.post('/api/complaints/', data: {
    'supplier': data.supplierId,
    'order': data.orderId,
    'title': data.title,
    'description': data.description,
    'complaint_type': data.type,
    'severity': data.severity,
  });
  
  if (response.statusCode == 201) {
    // Complaint created successfully
    // Show success message
  }
}
```

**Consumer View Complaints**:
```dart
Future<List<Complaint>> getMyComplaints() async {
  final response = await api.get('/api/complaints/');
  return (response.data as List)
      .map((json) => Complaint.fromJson(json))
      .toList();
}
```

### Flutter Supplier App (Sales Rep)

**View Assigned Complaints**:
```dart
// Automatically filtered to sales-level complaints
Future<List<Complaint>> getSalesComplaints() async {
  final response = await api.get('/api/complaints/');
  // Returns only sales-level complaints
  return parseComplaints(response.data);
}
```

**Escalate Complaint**:
```dart
Future<void> escalateComplaint(int id, String reason) async {
  await api.post('/api/complaints/$id/escalate/', data: {
    'reason': reason,
  });
}
```

### Web App (Manager/Owner)

**Dashboard with Escalation Filters**:
```javascript
// Manager sees sales + manager levels
// Owner sees all levels

async function getComplaints(filters) {
  const response = await api.get('/api/complaints/', {
    params: filters
  });
  return response.data;
}

// Filter by escalation level
getComplaints({ escalation_level: 'manager' });
```

## Testing Checklist

### Unit Tests
- [ ] Complaint creation with auto-assignment
- [ ] Escalation level validation
- [ ] Permission checks for each role
- [ ] Status update validations
- [ ] Escalation workflow

### Integration Tests
- [ ] Consumer creates complaint → Sales receives
- [ ] Sales escalates → Manager receives
- [ ] Manager escalates → Owner receives
- [ ] Response visibility (internal vs public)
- [ ] Link validation before complaint creation

### Role-Based Access Tests
- [ ] Sales cannot see manager-level complaints
- [ ] Manager cannot see owner-level complaints
- [ ] Consumer sees only their complaints
- [ ] Proper filtering by escalation level

## Migration Instructions

1. **Backup existing data**:
```bash
python manage.py dumpdata complaints > complaints_backup.json
```

2. **Run migrations**:
```bash
python manage.py makemigrations complaints
python manage.py migrate complaints
```

3. **Update existing complaints** (if any):
```python
# All existing complaints default to 'sales' level
# This is handled automatically by the migration
```

4. **Verify admin interface**:
- Check that all new fields appear in Django admin
- Test escalation functionality
- Verify inline models work correctly

## Monitoring & Analytics

Suggested metrics to track:
- Average time at each escalation level
- Escalation rate (% of complaints escalated)
- Resolution time by escalation level
- Most common escalation reasons
- Complaint volume by severity and type

## Future Enhancements

1. **Automated Escalation**:
   - Auto-escalate after X hours without resolution
   - Auto-escalate based on severity

2. **SLA Management**:
   - Define SLAs per escalation level
   - Alert when approaching SLA breach

3. **Email Notifications**:
   - Notify on escalation
   - Notify on status changes
   - Digest emails for managers/owners

4. **Advanced Analytics**:
   - Complaint trends
   - Staff performance metrics
   - Supplier quality scores

5. **Template Responses**:
   - Pre-defined responses for common issues
   - Response templates per escalation level

## Support

For questions or issues with the complaints system:
1. Check this documentation
2. Review the SRS document
3. Examine the code comments
4. Contact the development team

---

**Version**: 1.0
**Date**: November 2025
**Author**: Implementation based on SRS v2.0
