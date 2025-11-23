# Generated migration for escalation level functionality

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('complaints', '0002_incident'),
    ]

    operations = [
        # Add escalation level field to Complaint
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
                help_text='Current escalation level: sales → manager → owner',
                max_length=20
            ),
        ),
        migrations.AddField(
            model_name='complaint',
            name='escalation_reason',
            field=models.TextField(
                blank=True,
                help_text='Reason for escalation to higher level',
                null=True
            ),
        ),
        migrations.AddField(
            model_name='complaint',
            name='escalated_by',
            field=models.ForeignKey(
                blank=True,
                help_text='Staff member who escalated this complaint',
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='escalated_complaints',
                to=settings.AUTH_USER_MODEL
            ),
        ),
        migrations.AddField(
            model_name='complaint',
            name='escalated_at',
            field=models.DateTimeField(
                blank=True,
                help_text='When the complaint was last escalated',
                null=True
            ),
        ),
        
        # Update assigned_to field help text
        migrations.AlterField(
            model_name='complaint',
            name='assigned_to',
            field=models.ForeignKey(
                blank=True,
                help_text='Current staff member handling this complaint',
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='assigned_complaints',
                to=settings.AUTH_USER_MODEL
            ),
        ),
        
        # Add indexes
        migrations.AddIndex(
            model_name='complaint',
            index=models.Index(fields=['supplier', 'status'], name='complaints_c_supplie_idx'),
        ),
        migrations.AddIndex(
            model_name='complaint',
            index=models.Index(fields=['consumer', 'status'], name='complaints_c_consume_idx'),
        ),
        migrations.AddIndex(
            model_name='complaint',
            index=models.Index(fields=['escalation_level', 'status'], name='complaints_c_escalat_idx'),
        ),
        
        # Create ComplaintResponse model
        migrations.CreateModel(
            name='ComplaintResponse',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('message', models.TextField()),
                ('is_internal', models.BooleanField(default=False, help_text='Internal note not visible to consumer')),
                ('attachment', models.FileField(blank=True, null=True, upload_to='complaint_responses/')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('complaint', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='responses', to='complaints.complaint')),
                ('user', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='complaint_responses', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['created_at'],
            },
        ),
        
        # Create ComplaintEscalation model
        migrations.CreateModel(
            name='ComplaintEscalation',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('from_level', models.CharField(max_length=20)),
                ('to_level', models.CharField(max_length=20)),
                ('reason', models.TextField()),
                ('escalated_at', models.DateTimeField(auto_now_add=True)),
                ('complaint', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='escalation_history', to='complaints.complaint')),
                ('escalated_by', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='escalations_performed', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-escalated_at'],
            },
        ),
        
        # Update Complaint Meta
        migrations.AlterModelOptions(
            name='complaint',
            options={'ordering': ['-created_at']},
        ),
        
        # Update Incident Meta
        migrations.AlterModelOptions(
            name='incident',
            options={'ordering': ['-created_at']},
        ),
    ]
