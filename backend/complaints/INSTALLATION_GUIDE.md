# Enhanced Complaints System - Integration Guide

## Quick Start

This guide will help you integrate the enhanced complaints functionality into your SCP backend.

---

## What's Included

### New Files Created
1. **Models**: `complaints/models.py` - Enhanced with escalation tracking and ComplaintNote model
2. **Views**: `complaints/views_enhanced.py` - New views with role-based permissions
3. **Serializers**: `complaints/serializers.py` - Updated with nested data and new fields
4. **URLs**: `complaints/urls_enhanced.py` - New endpoints for escalation and notes
5. **Admin**: `complaints/admin_enhanced.py` - Enhanced admin interface
6. **Migration**: `complaints/migrations/0003_enhance_complaints.py` - Database schema updates
7. **Documentation**: `complaints/COMPLAINTS_DOCUMENTATION.md` - Complete API documentation

### Key Features Added
✅ **Escalation Workflow**: Sales → Manager → Owner  
✅ **Auto-Assignment**: Complaints auto-assigned to sales reps  
✅ **Complaint Notes**: Full communication history with visibility control  
✅ **Resolution Tracking**: Track who resolved and when  
✅ **Role-Based Permissions**: Proper access control per SRS requirements  
✅ **Audit Trail**: Complete history of all changes  
✅ **Admin Interface**: Enhanced Django admin for better management  

---

## Installation Steps

### Step 1: Backup Current Implementation

Before making changes, backup your current complaints app:

```bash
cd /path/to/backend
cp -r complaints complaints_backup_$(date +%Y%m%d)
```

### Step 2: Apply Database Migrations

The new functionality requires database schema changes:

```bash
# Apply the new migration
python manage.py migrate complaints

# Or if you need to create it first:
python manage.py makemigrations complaints
python manage.py migrate complaints
```

**Expected Changes**:
- New `ComplaintNote` table created
- New fields added to `Complaint` table:
  - `escalation_level`
  - `escalated_at`
  - `escalated_by`
  - `resolution_notes`
  - `resolved_at`
  - `resolved_by`
- Updated `status` field choices
- New indexes for better performance

### Step 3: Update URL Configuration

**Option A: Replace existing URLs (Recommended)**

Update `complaints/urls.py`:

```python
# complaints/urls.py
from django.urls import path
from .views_enhanced import (
    ComplaintListCreateView,
    ComplaintDetailView,
    ComplaintEscalateView,
    ComplaintStatusUpdateView,
    ComplaintNoteCreateView,
    ComplaintNoteListView,
    IncidentListCreateView,
    IncidentDetailView,
    IncidentStatusUpdateView,
)

urlpatterns = [
    # Complaint endpoints
    path('complaints/', ComplaintListCreateView.as_view(), name='complaint-list-create'),
    path('complaints/<int:pk>/', ComplaintDetailView.as_view(), name='complaint-detail'),
    path('complaints/<int:pk>/escalate/', ComplaintEscalateView.as_view(), name='complaint-escalate'),
    path('complaints/<int:pk>/status/', ComplaintStatusUpdateView.as_view(), name='complaint-status'),
    
    # Complaint notes endpoints (NEW)
    path('complaints/<int:complaint_id>/notes/', ComplaintNoteListView.as_view(), name='complaint-notes-list'),
    path('complaints/<int:complaint_id>/notes/create/', ComplaintNoteCreateView.as_view(), name='complaint-note-create'),

    # Incident endpoints
    path('incidents/', IncidentListCreateView.as_view(), name='incident-list-create'),
    path('incidents/<int:pk>/', IncidentDetailView.as_view(), name='incident-detail'),
    path('incidents/<int:pk>/status/', IncidentStatusUpdateView.as_view(), name='incident-status'),
]
```

**Option B: Use new file alongside old (for gradual migration)**

Keep old URLs and add new ones:

```python
# scp_project/urls.py
urlpatterns = [
    # ... other patterns ...
    path('api/v1/', include('complaints.urls')),  # Old URLs
    path('api/v2/', include('complaints.urls_enhanced')),  # New URLs
]
```

### Step 4: Update Admin Configuration

Update `complaints/admin.py`:

```python
# complaints/admin.py
from django.contrib import admin
from .models import Complaint, ComplaintNote, Incident


class ComplaintNoteInline(admin.TabularInline):
    model = ComplaintNote
    extra = 0
    readonly_fields = ('created_at', 'created_by')
    fields = ('note_type', 'content', 'created_by', 'created_at', 'is_visible_to_consumer')


@admin.register(Complaint)
class ComplaintAdmin(admin.ModelAdmin):
    list_display = (
        'id', 'title', 'consumer', 'supplier', 'complaint_type',
        'severity', 'status', 'escalation_level', 'assigned_to', 'created_at',
    )
    list_filter = ('status', 'escalation_level', 'severity', 'complaint_type', 'created_at')
    search_fields = ('title', 'description', 'consumer__business_name', 'supplier__company_name')
    readonly_fields = (
        'created_by', 'created_at', 'updated_at',
        'escalated_by', 'escalated_at',
        'resolved_by', 'resolved_at',
    )
    inlines = [ComplaintNoteInline]


@admin.register(ComplaintNote)
class ComplaintNoteAdmin(admin.ModelAdmin):
    list_display = ('id', 'complaint', 'note_type', 'created_by', 'created_at', 'is_visible_to_consumer')
    list_filter = ('note_type', 'is_visible_to_consumer', 'created_at')
    readonly_fields = ('created_at', 'created_by')


@admin.register(Incident)
class IncidentAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'supplier', 'severity', 'status', 'created_by', 'created_at')
    list_filter = ('status', 'severity', 'created_at')
    readonly_fields = ('created_by', 'created_at', 'updated_at')
```

### Step 5: Update Views (if needed)

If you had custom views in `complaints/views.py`, you can either:

**Option A**: Replace with enhanced views
```python
# complaints/views.py
from .views_enhanced import *
```

**Option B**: Keep both and use enhanced views selectively
```python
# complaints/views.py
from .views_enhanced import (
    ComplaintEscalateView,
    ComplaintNoteCreateView,
    ComplaintNoteListView,
)
# Keep your existing views and add new ones
```

### Step 6: Test the Installation

#### A. Test Migration
```bash
python manage.py showmigrations complaints
# Should show 0003_enhance_complaints as applied
```

#### B. Test Admin Interface
```bash
python manage.py runserver
# Navigate to http://localhost:8000/admin/complaints/
# Verify you can see the enhanced fields
```

#### C. Test API Endpoints
```bash
# Create a test complaint (as consumer)
curl -X POST http://localhost:8000/api/complaints/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "supplier": 1,
    "title": "Test Complaint",
    "description": "Testing enhanced complaints",
    "complaint_type": "other",
    "severity": "low"
  }'

# Test escalation (as sales rep)
curl -X POST http://localhost:8000/api/complaints/1/escalate/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Testing escalation workflow"
  }'

# Test adding note
curl -X POST http://localhost:8000/api/complaints/1/notes/create/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Test note",
    "note_type": "comment"
  }'
```

---

## Configuration

### Required Settings

Ensure your `settings.py` has complaints app installed:

```python
# settings.py
INSTALLED_APPS = [
    # ...
    'complaints',
    # ...
]
```

### Optional Settings

You can add custom settings for complaints:

```python
# settings.py

# Complaint SLA settings (optional, for future use)
COMPLAINT_SLA = {
    'low': 72,      # hours
    'medium': 48,
    'high': 24,
    'critical': 8,
}

# Auto-assignment settings
COMPLAINT_AUTO_ASSIGN = True  # Default: True
```

---

## Data Migration (if you have existing complaints)

If you have existing complaints in the database, run this data migration:

```python
# Create a data migration file
python manage.py makemigrations complaints --empty --name migrate_existing_complaints
```

Then edit the migration file:

```python
# complaints/migrations/0004_migrate_existing_complaints.py
from django.db import migrations


def migrate_existing_complaints(apps, schema_editor):
    """
    Migrate existing complaints to new structure
    """
    Complaint = apps.get_model('complaints', 'Complaint')
    ComplaintNote = apps.get_model('complaints', 'ComplaintNote')
    
    for complaint in Complaint.objects.all():
        # Set default escalation level
        if not complaint.escalation_level:
            complaint.escalation_level = 'sales'
        
        # Create initial note for existing complaints
        if not complaint.notes.exists():
            ComplaintNote.objects.create(
                complaint=complaint,
                note_type='comment',
                content=f"Complaint migrated from old system: {complaint.description[:100]}",
                created_by=complaint.created_by,
                is_visible_to_consumer=True
            )
        
        complaint.save()


class Migration(migrations.Migration):
    dependencies = [
        ('complaints', '0003_enhance_complaints'),
    ]

    operations = [
        migrations.RunPython(migrate_existing_complaints),
    ]
```

Run the migration:
```bash
python manage.py migrate complaints
```

---

## Rollback Plan

If you need to rollback:

### 1. Database Rollback
```bash
python manage.py migrate complaints 0002_incident
```

### 2. Code Rollback
```bash
# Restore from backup
rm -rf complaints
mv complaints_backup_YYYYMMDD complaints
```

### 3. Restart Server
```bash
python manage.py runserver
```

---

## Frontend Integration

### Updated API Endpoints for Flutter App

The Flutter app needs to be updated to support new endpoints:

#### 1. Update Consumer Complaint Creation

```dart
// lib/features/consumer/data/consumer_api_service.dart

Future<Map<String, dynamic>> createComplaint({
  required int supplierId,
  int? orderId,
  required String title,
  required String description,
  required String complaintType,
  required String severity,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/complaints/'),
    headers: await _getHeaders(),
    body: jsonEncode({
      'supplier': supplierId,
      'order': orderId,
      'title': title,
      'description': description,
      'complaint_type': complaintType,
      'severity': severity,
    }),
  );
  
  if (response.statusCode == 201) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to create complaint');
  }
}

// Get complaint details with notes
Future<Map<String, dynamic>> getComplaintDetails(int complaintId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/complaints/$complaintId/'),
    headers: await _getHeaders(),
  );
  
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load complaint details');
  }
}

// Add note to complaint
Future<void> addComplaintNote(int complaintId, String content) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/complaints/$complaintId/notes/create/'),
    headers: await _getHeaders(),
    body: jsonEncode({
      'content': content,
      'note_type': 'comment',
    }),
  );
  
  if (response.statusCode != 201) {
    throw Exception('Failed to add note');
  }
}
```

#### 2. Update Supplier Complaint Handling

```dart
// lib/features/supplier/data/supplier_api_service.dart

// Escalate complaint
Future<Map<String, dynamic>> escalateComplaint(int complaintId, String reason) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/complaints/$complaintId/escalate/'),
    headers: await _getHeaders(),
    body: jsonEncode({'reason': reason}),
  );
  
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to escalate complaint');
  }
}

// Update complaint status
Future<Map<String, dynamic>> updateComplaintStatus({
  required int complaintId,
  required String status,
  String? notes,
  String? resolutionNotes,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/complaints/$complaintId/status/'),
    headers: await _getHeaders(),
    body: jsonEncode({
      'status': status,
      'notes': notes,
      'resolution_notes': resolutionNotes,
    }),
  );
  
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to update complaint status');
  }
}

// Get complaint notes
Future<List<dynamic>> getComplaintNotes(int complaintId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/complaints/$complaintId/notes/'),
    headers: await _getHeaders(),
  );
  
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load complaint notes');
  }
}
```

#### 3. Update UI Models

```dart
// lib/features/consumer/data/consumer_models.dart (or supplier_models.dart)

class Complaint {
  final int id;
  final String title;
  final String description;
  final String complaintType;
  final String severity;
  final String status;
  final String escalationLevel;
  final DateTime? escalatedAt;
  final UserInfo? escalatedBy;
  final UserInfo? assignedTo;
  final String? resolutionNotes;
  final DateTime? resolvedAt;
  final UserInfo? resolvedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ComplaintNote> notes;
  final bool canEscalate;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.complaintType,
    required this.severity,
    required this.status,
    required this.escalationLevel,
    this.escalatedAt,
    this.escalatedBy,
    this.assignedTo,
    this.resolutionNotes,
    this.resolvedAt,
    this.resolvedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.notes,
    required this.canEscalate,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      complaintType: json['complaint_type'],
      severity: json['severity'],
      status: json['status'],
      escalationLevel: json['escalation_level'],
      escalatedAt: json['escalated_at'] != null 
          ? DateTime.parse(json['escalated_at']) 
          : null,
      escalatedBy: json['escalated_by_info'] != null 
          ? UserInfo.fromJson(json['escalated_by_info']) 
          : null,
      assignedTo: json['assigned_to_info'] != null 
          ? UserInfo.fromJson(json['assigned_to_info']) 
          : null,
      resolutionNotes: json['resolution_notes'],
      resolvedAt: json['resolved_at'] != null 
          ? DateTime.parse(json['resolved_at']) 
          : null,
      resolvedBy: json['resolved_by_info'] != null 
          ? UserInfo.fromJson(json['resolved_by_info']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      notes: (json['notes'] as List)
          .map((note) => ComplaintNote.fromJson(note))
          .toList(),
      canEscalate: json['can_escalate'] ?? false,
    );
  }
}

class ComplaintNote {
  final int id;
  final String noteType;
  final String content;
  final UserInfo? createdBy;
  final DateTime createdAt;
  final String? previousValue;
  final String? newValue;
  final bool isVisibleToConsumer;

  ComplaintNote({
    required this.id,
    required this.noteType,
    required this.content,
    this.createdBy,
    required this.createdAt,
    this.previousValue,
    this.newValue,
    required this.isVisibleToConsumer,
  });

  factory ComplaintNote.fromJson(Map<String, dynamic> json) {
    return ComplaintNote(
      id: json['id'],
      noteType: json['note_type'],
      content: json['content'],
      createdBy: json['created_by_info'] != null 
          ? UserInfo.fromJson(json['created_by_info']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      previousValue: json['previous_value'],
      newValue: json['new_value'],
      isVisibleToConsumer: json['is_visible_to_consumer'] ?? true,
    );
  }
}

class UserInfo {
  final int id;
  final String email;
  final String username;
  final String userType;

  UserInfo({
    required this.id,
    required this.email,
    required this.username,
    required this.userType,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      userType: json['user_type'],
    );
  }
}
```

---

## Verification Checklist

After installation, verify:

- [ ] Database migration applied successfully
- [ ] All new fields visible in Django admin
- [ ] Can create complaints as consumer
- [ ] Complaints auto-assigned to sales rep
- [ ] Can add notes to complaints
- [ ] Can escalate as sales rep
- [ ] Can escalate as manager
- [ ] Cannot escalate beyond owner level
- [ ] Status updates work correctly
- [ ] Resolution tracking works
- [ ] Consumers see only visible notes
- [ ] Staff see all notes
- [ ] Permissions enforced correctly

---

## Troubleshooting

### Common Issues

**Issue**: Migration fails with "column already exists"
**Solution**: 
```bash
python manage.py migrate complaints --fake 0003_enhance_complaints
python manage.py migrate complaints
```

**Issue**: Cannot import views_enhanced
**Solution**: Ensure file is in correct location: `complaints/views_enhanced.py`

**Issue**: 404 on new endpoints
**Solution**: Check URL configuration is updated and server restarted

**Issue**: Permissions not working
**Solution**: Verify user has correct `user_type` in database

---

## Support

- **Documentation**: See `COMPLAINTS_DOCUMENTATION.md` for complete API reference
- **SRS**: Refer to SRS document sections 3.2.3 and 7
- **Issues**: Check existing issues or create new one with details

---

## Next Steps

1. ✅ Complete installation
2. ✅ Run verification tests
3. 🔄 Update Flutter app with new models and endpoints
4. 🔄 Test end-to-end workflows
5. 📊 Set up monitoring and metrics
6. 📧 Configure notification system (optional)
7. 🚀 Deploy to production

---

**Version**: 2.0  
**Last Updated**: November 22, 2025  
**Compatibility**: Django 4.x+, DRF 3.x+
