from django.core.management.base import BaseCommand
from accounts.models import ConsumerSupplierLink, SupplierStaff
from django.db.models import Count

class Command(BaseCommand):
    help = 'Backfill assigned_sales_rep for existing ConsumerSupplierLinks'

    def handle(self, *args, **options):
        links = ConsumerSupplierLink.objects.filter(status='accepted', assigned_sales_rep__isnull=True)
        print(f"Found {links.count()} unassigned links.")
        
        for link in links:
            # Find sales reps for this supplier
            sales_reps = SupplierStaff.objects.filter(
                supplier=link.supplier,
                user__user_type='supplier_sales'
            ).annotate(
                num_consumers=Count('assigned_consumers')
            ).order_by('num_consumers')
            
            best_rep = sales_reps.first()
            if best_rep:
                link.assigned_sales_rep = best_rep
                link.save()
                print(f"Assigned {link.consumer} to {best_rep.user.username}")
            else:
                print(f"No sales rep found for supplier {link.supplier}")
