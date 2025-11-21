# Django Project Fixes

## Issues Found and Fixed

### 1. **CRITICAL: Email Field Not Unique**
**Problem**: The User model had `USERNAME_FIELD = "email"` but the email field wasn't unique, causing authentication failures.

**Fix Applied**:
- Made email field unique in the User model
- Created migration `0002_alter_user_email.py` to update the database schema
- Added custom UserManager to properly handle email-based user creation

### 2. **Serializer Forward Reference Error**
**Problem**: `SupplierStaffSerializer` and `UserSerializer` referenced `SupplierProfileSerializer` and `ConsumerProfileSerializer` before they were defined.

**Fix Applied**:
- Reordered serializers in `serializers.py` to define them before use

### 3. **Missing Email Validation**
**Problem**: Email was optional in `ConsumerRegisterSerializer` but it's required for authentication.

**Fix Applied**:
- Made email required in registration
- Added email uniqueness validation
- Fixed user creation to properly use email

### 4. **Authentication View Issues**
**Problem**: The authentication view was overly complex and didn't properly handle email-based login.

**Fix Applied**:
- Simplified authentication logic
- Added proper password checking
- Returns more user information in response

## Files Modified

1. `/home/claude/backend/accounts/models.py`
   - Added UserManager class
   - Made email unique
   - Added REQUIRED_FIELDS

2. `/home/claude/backend/accounts/serializers.py`
   - Reordered serializer definitions
   - Made email required in registration
   - Added email validation

3. `/home/claude/backend/accounts/views.py`
   - Simplified EmailOrUsernameAuthTokenView
   - Fixed authentication logic

4. `/home/claude/backend/accounts/migrations/0002_alter_user_email.py` (NEW)
   - Migration to make email unique

## How to Apply These Fixes

### Option 1: Fresh Database (Recommended if no important data)

```bash
# 1. Drop the existing database
docker-compose down -v

# 2. Apply migrations
docker-compose up -d db
docker-compose run backend python manage.py migrate

# 3. Create a superuser
docker-compose run backend python manage.py createsuperuser
# You'll be prompted for: email, username, and password

# 4. Start the server
docker-compose up
```

### Option 2: Existing Database with Data

```bash
# 1. Backup your database first!
docker-compose exec db pg_dump -U postgres scp_db > backup.sql

# 2. Run migrations
docker-compose run backend python manage.py migrate

# Note: If you have existing users with duplicate emails, 
# the migration will fail. You'll need to clean up duplicates first:

# Connect to Django shell
docker-compose run backend python manage.py shell

# In the shell:
from accounts.models import User
from django.db.models import Count

# Find duplicate emails
duplicates = User.objects.values('email').annotate(
    email_count=Count('email')
).filter(email_count__gt=1)

# Review and manually fix duplicates
for dup in duplicates:
    users = User.objects.filter(email=dup['email'])
    print(f"Email: {dup['email']}, Count: {dup['email_count']}")
    for user in users:
        print(f"  - ID: {user.id}, Username: {user.username}")
```

### Option 3: Manual Migration for Existing Data

If the automatic migration fails:

```sql
-- Connect to your database
-- 1. Find and resolve duplicate emails
SELECT email, COUNT(*) 
FROM users 
GROUP BY email 
HAVING COUNT(*) > 1;

-- 2. Update or delete duplicates manually
-- Then add the unique constraint:
ALTER TABLE users ADD CONSTRAINT users_email_unique UNIQUE (email);
```

## Testing the Fixes

### 1. Test User Registration

```bash
curl -X POST http://localhost:8000/api/accounts/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "username": "testuser",
    "password": "securepass123",
    "business_name": "Test Restaurant",
    "business_type": "restaurant",
    "city": "Almaty"
  }'
```

### 2. Test Login with Email

```bash
curl -X POST http://localhost:8000/api/accounts/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "securepass123"
  }'
```

### 3. Test Login with Username

```bash
curl -X POST http://localhost:8000/api/accounts/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "securepass123"
  }'
```

### 4. Test Current User Endpoint

```bash
# Use the token from login response
curl -X GET http://localhost:8000/api/accounts/me/ \
  -H "Authorization: Token YOUR_TOKEN_HERE"
```

## Additional Improvements Made

1. **Better Error Messages**: More descriptive error responses in authentication
2. **Proper Password Checking**: Uses Django's built-in password verification
3. **Token Response Enhancement**: Returns user info along with token
4. **Code Organization**: Better serializer ordering for maintainability

## Common Issues and Solutions

### Issue: "UNIQUE constraint failed: users.email"
**Solution**: You're trying to create a user with an email that already exists. Use a different email.

### Issue: Migration fails with duplicate emails
**Solution**: Follow Option 2 or 3 above to clean up duplicates before migrating.

### Issue: "Cannot authenticate with email"
**Solution**: Make sure you've applied all migrations and restarted the server.

### Issue: "Username field not found"
**Solution**: The system now uses email as the primary login field. Use email for authentication.

## Creating Superuser

Since email is now the USERNAME_FIELD, create superuser like this:

```bash
docker-compose run backend python manage.py createsuperuser

# You'll be prompted:
# Email: admin@example.com
# Username: admin
# Password: ********
```

## Important Notes

- **Email is now the primary login field** - Users login with email, not username
- **Username is still required** - But only for display purposes
- **Email must be unique** - Cannot have two users with the same email
- **Backward Compatible** - Users can still login with username if they prefer

## Next Steps

1. Apply these fixes to your codebase
2. Run migrations
3. Test all authentication flows
4. Update your frontend to use email for login (if needed)
5. Update any documentation

## Support

If you encounter issues:
1. Check the Django logs: `docker-compose logs backend`
2. Check database logs: `docker-compose logs db`
3. Verify migrations: `docker-compose run backend python manage.py showmigrations`
4. Test in Django shell: `docker-compose run backend python manage.py shell`
