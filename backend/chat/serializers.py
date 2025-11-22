from rest_framework import serializers
from .models import Conversation, Message


class ConversationSerializer(serializers.ModelSerializer):
    supplier_name = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    last_message_at = serializers.DateTimeField(source='updated_at', read_only=True)
    unread_count = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = [
            'id',
            'supplier',
            'supplier_name',
            'consumer',
            'order',
            'conversation_type',
            'created_by',
            'created_at',
            'updated_at',
            'last_message',
            'last_message_at',
            'unread_count',
        ]
        read_only_fields = ['created_by', 'created_at', 'updated_at', 'supplier_name', 'last_message', 'last_message_at', 'unread_count']

    def get_supplier_name(self, obj):
        return obj.supplier.company_name if obj.supplier else None

    def get_last_message(self, obj):
        last_msg = obj.messages.order_by('-sent_at').first()
        return last_msg.text if last_msg else None

    def get_unread_count(self, obj):
        request = self.context.get('request')
        if request and request.user:
            return obj.messages.filter(is_read=False).exclude(sender=request.user).count()
        return 0


class MessageSerializer(serializers.ModelSerializer):
    sender_username = serializers.CharField(source='sender.username', read_only=True)

    class Meta:
        model = Message
        fields = [
            'id',
            'conversation',
            'sender',
            'sender_username',
            'text',
            'attachment',
            'sent_at',
            'is_read',
        ]
        read_only_fields = ['sender', 'sent_at', 'is_read', 'sender_username', 'conversation']
