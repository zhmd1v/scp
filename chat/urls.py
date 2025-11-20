from django.urls import path
from .views import (
    ConversationListCreateView,
    MessageListCreateView,
    MarkConversationReadView,
)

urlpatterns = [
    # список/создание диалогов
    path('conversations/', ConversationListCreateView.as_view(), name='conversation-list-create'),

    # сообщения внутри конкретного диалога
    path('conversations/<int:conversation_id>/messages/',
         MessageListCreateView.as_view(),
         name='message-list-create'),

    # пометить сообщения как прочитанные
    path('conversations/<int:conversation_id>/read/',
         MarkConversationReadView.as_view(),
         name='conversation-mark-read'),
]
