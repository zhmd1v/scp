import os
import sys
import django

sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'scp_project.settings')
django.setup()

from chat.models import Conversation

def cleanup_empty_chats():
    # Find conversations with no messages
    empty_chats = Conversation.objects.filter(messages__isnull=True)
    count = empty_chats.count()
    
    print(f"Found {count} empty conversations.")
    
    if count > 0:
        print("Deleting...")
        empty_chats.delete()
        print("Done.")
    else:
        print("No empty chats to delete.")

if __name__ == '__main__':
    cleanup_empty_chats()
