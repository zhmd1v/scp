from django.contrib import admin
from .models import Conversation, Message


class MessageInline(admin.TabularInline):
    model = Message
    extra = 0
    readonly_fields = ['sender', 'text', 'attachment', 'sent_at', 'is_read']


@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ['id', 'supplier', 'consumer', 'assigned_staff', 'order', 'conversation_type', 'created_at']
    list_filter = ['conversation_type', 'supplier', 'assigned_staff']
    search_fields = ['supplier__company_name', 'consumer__business_name', 'assigned_staff__user__username']
    inlines = [MessageInline]


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ['id', 'conversation', 'sender', 'sent_at', 'is_read']
    list_filter = ['is_read', 'sent_at']
    search_fields = ['text']
