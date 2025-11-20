from django.db import models
from django.conf import settings

from accounts.models import ConsumerProfile, SupplierProfile, SupplierStaff
from orders.models import Order


class Conversation(models.Model):
    """
    Диалог между потребителем и поставщиком (или внутренний чат поставщика).
    """
    CONVERSATION_TYPE_CHOICES = [
        ('supplier_consumer', 'Supplier–Consumer'),
        ('supplier_internal', 'Supplier internal'),
    ]

    supplier = models.ForeignKey(
        SupplierProfile,
        on_delete=models.CASCADE,
        related_name='conversations'
    )
    consumer = models.ForeignKey(
        ConsumerProfile,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='conversations'
    )
    order = models.ForeignKey(
        Order,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='conversations'
    )

    conversation_type = models.CharField(
        max_length=32,
        choices=CONVERSATION_TYPE_CHOICES,
        default='supplier_consumer'
    )

    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_conversations'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        base = f"Conversation #{self.id} with supplier {self.supplier}"
        if self.consumer:
            base += f" and consumer {self.consumer}"
        if self.order:
            base += f" (order #{self.order_id})"
        return base


class Message(models.Model):
    """
    Сообщение в диалоге.
    """
    conversation = models.ForeignKey(
        Conversation,
        on_delete=models.CASCADE,
        related_name='messages'
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='chat_messages'
    )
    text = models.TextField(blank=True)
    attachment = models.FileField(
        upload_to='chat_attachments/',
        null=True,
        blank=True
    )

    sent_at = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    def __str__(self):
        return f"Message #{self.id} in conv {self.conversation_id}"
