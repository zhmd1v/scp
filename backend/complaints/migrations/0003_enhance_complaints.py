# Generated migration for enhanced complaints functionality

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('complaints', '0002_incident'),
    ]

    operations = [
        # Update Complaint model status choices
        migrations.AlterField(
            model_name='complaint',
            name='status',
            field=models.CharField(
                choices=[
                    ('open', 'Open'),
                    ('in_progress', 'In Progress'),
                    ('escalated_to_manager', 'Escalated to Manager'),
                    ('escalated_to_owner', 'Escalated to Owner'),
                    ('resolved', 'Resolved'),
                    ('closed', 'Closed')
                ],
                default='open',
                max_length=30
            ),
        ),
        
        # Add escalation_level field
        migrations.AddField(
            model_name='complaint',
            name='escalation_level',
            field=models.CharField(
                choices=[
                    ('sales', 'Sales Representative'),
                    ('manager', 'Manager'),
                    ('owner', 'Owner')
                ],
                default='sales',
                help_text='Current escalation level of the complaint',
                max_length=20
            ),
        ),
        
        # Add escalated_at field
        migrations.AddField(
            model_name='complaint',
            name='escalated_at',
            field=models.DateTimeField(
                blank=True,
                help_text='Timestamp of last escalation',
                null=True
            ),
        ),
        
        # Add escalated_by field
        migrations.AddField(
            model_name='complaint',
            name='escalated_by',
            field=models.ForeignKey(
                blank=True,
                help_text='User who escalated the complaint',
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='escalated_complaints',
                to=settings.AUTH_USER_MODEL
            ),
        ),
        
        # Add resolution_notes field
        migrations.AddField(
            model_name='complaint',
            name='resolution_notes',
            field=models.TextField(
                blank=True,
                help_text='Final resolution notes',
                null=True
            ),
        ),
        
        # Add resolved_at field
        migrations.AddField(
            model_name='complaint',
            name='resolved_at',
            field=models.DateTimeField(
                blank=True,
                help_text='Timestamp when complaint was resolved',
                null=True
            ),
        ),
        
        # Add resolved_by field
        migrations.AddField(
            model_name='complaint',
            name='resolved_by',
            field=models.ForeignKey(
                blank=True,
                help_text='User who resolved the complaint',
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='resolved_complaints',
                to=settings.AUTH_USER_MODEL
            ),
        ),
        
        # Update Meta for Complaint model
        migrations.AlterModelOptions(
            name='complaint',
            options={'ordering': ['-created_at']},
        ),
        
        # Alter database table name
        migrations.AlterModelTable(
            name='complaint',
            table='complaints',
        ),
        
        # Create ComplaintNote model
        migrations.CreateModel(
            name='ComplaintNote',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('note_type', models.CharField(
                    choices=[
                        ('comment', 'Comment'),
                        ('escalation', 'Escalation'),
                        ('status_change', 'Status Change'),
                        ('resolution', 'Resolution'),
                        ('internal', 'Internal Note')
                    ],
                    default='comment',
                    max_length=20
                )),
                ('content', models.TextField()),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('previous_value', models.CharField(blank=True, max_length=50, null=True)),
                ('new_value', models.CharField(blank=True, max_length=50, null=True)),
                ('is_visible_to_consumer', models.BooleanField(
                    default=True,
                    help_text='Whether this note is visible to the consumer'
                )),
                ('complaint', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='notes',
                    to='complaints.complaint'
                )),
                ('created_by', models.ForeignKey(
                    null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name='complaint_notes',
                    to=settings.AUTH_USER_MODEL
                )),
            ],
            options={
                'db_table': 'complaint_notes',
                'ordering': ['created_at'],
            },
        ),
        
        # Add indexes for better query performance
        migrations.AddIndex(
            model_name='complaint',
            index=models.Index(fields=['status', 'escalation_level'], name='complaints_status_esc_idx'),
        ),
        migrations.AddIndex(
            model_name='complaint',
            index=models.Index(fields=['supplier', 'status'], name='complaints_supp_status_idx'),
        ),
        migrations.AddIndex(
            model_name='complaint',
            index=models.Index(fields=['consumer', 'created_at'], name='complaints_cons_created_idx'),
        ),
    ]
