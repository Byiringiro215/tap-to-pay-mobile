# Mobile App Setup and Authentication Guide

## Overview
The mobile app is now fully integrated with the backend API. This guide explains how to set up and test the authentication flow.

## Prerequisites
- Backend server running on port 8275
- PostgreSQL database configured
- Mobile app dependencies installed

## Backend Setup

### 1. Start the Backend Server
```bash
cd Tap_and_Pay/backend
npm run start
```

Expected output:
```
Backend server running on http://0.0.0.0:8275
Access from: http://localhost:8275
✓ Database tables initialized
✓ Demo user created: admin / admin123
✓ Demo user created: manager / manager123
✓ Demo user created: user / user123
✓ Demo user created: operator / operator123
✓ Connected to MQTT Broker
```

### 2. Verify Backend is Running
```powershell
# Test with PowerShell
$response = Invoke-WebRequest -Uri "http://localhost:8275/auth/users" -Method GET
$response.Content | ConvertFrom-Json | ConvertTo-Json
```

## Mobile App Configuration

### 1. Backend URL Configuration
The backend URL is configured in `my-expo-app/src/config.ts`:

```typescript
export const BACKEND_URL = 'http://localhost:8275';
```

**For different scenarios:**
- **Local development (Expo Go on same machine)**: Use `http://localhost:8275`
- **Physical device on same network**: Use your machine's IP (e.g., `http://192.168.1.100:8275`)
- **Production**: Use your production server URL

**To find your machine IP:**
```powershell
# Windows
ipconfig

# Look for IPv4 Address under your network adapter
# Example: 192.168.1.100
```

### 2. Start the Mobile App
```bash
cd my-expo-app
npm start
```

Then:
- Press `i` for iOS simulator
- Press `a` for Android emulator
- Scan QR code with Expo Go app on physical device

## Authentication Flow

### Step 1: Role Selection
1. App starts and shows role selection screen
2. User selects either:
   - **Administrator** (👨‍💼) - Full system access
   - **Normal User** (👤) - Limited access

### Step 2: Authentication
1. User enters credentials based on selected role
2. App sends login request to backend
3. Backend validates credentials and returns JWT token
4. App stores token for subsequent API calls

### Step 3: Access App
1. After successful authentication, user can access the app
2. All API calls include the JWT token in Authorization header
3. Token is valid for 24 hours

## Demo Credentials

### Admin Role
- **Username**: `admin` | **Password**: `admin123`
- **Username**: `manager` | **Password**: `manager123`

### User Role
- **Username**: `user` | **Password**: `user123`
- **Username**: `operator` | **Password**: `operator123`

## Testing Authentication

### Test 1: Successful Login
1. Select "Administrator" role
2. Enter username: `admin`
3. Enter password: `admin123`
4. Click "Authenticate"
5. Should see success message and navigate to app

### Test 2: Wrong Password
1. Select "Administrator" role
2. Enter username: `admin`
3. Enter password: `wrongpassword`
4. Click "Authenticate"
5. Should see error: "Invalid username or password"

### Test 3: Wrong Role
1. Select "Normal User" role
2. Enter username: `admin` (admin role user)
3. Enter password: `admin123`
4. Click "Authenticate"
5. Should see error: "This account is for admin role, not user"

### Test 4: Non-existent User
1. Select any role
2. Enter username: `nonexistent`
3. Enter password: `anypassword`
4. Click "Authenticate"
5. Should see error: "Invalid username or password"

## Troubleshooting

### Issue: "Failed to connect to server"
**Cause**: Backend URL is incorrect or backend is not running

**Solution**:
1. Verify backend is running: `npm run start` in `Tap_and_Pay/backend`
2. Check backend URL in `my-expo-app/src/config.ts`
3. Ensure port 8275 is not blocked by firewall

### Issue: "Invalid username or password" for correct credentials
**Cause**: Database doesn't have demo users or credentials are wrong

**Solution**:
1. Restart backend server (it auto-seeds demo users)
2. Verify credentials in backend logs
3. Check PostgreSQL is running and database exists

### Issue: "This account is for admin role, not user"
**Cause**: User selected wrong role

**Solution**:
1. Go back to role selection
2. Select the correct role matching the account
3. Re-enter credentials

### Issue: App crashes after login
**Cause**: Token not being stored or API calls failing

**Solution**:
1. Check browser console for errors
2. Verify backend is returning valid token
3. Check network tab to see API responses

## API Endpoints Used by Mobile App

### Authentication
- `POST /auth/login` - Login with credentials
- `POST /auth/seed` - Seed demo users (admin only)

### Products
- `GET /products` - Get all products

### Cards
- `GET /card/{uid}` - Get card details
- `POST /topup` - Top-up card
- `POST /card/{uid}/set-passcode` - Set card passcode
- `POST /card/{uid}/verify-passcode` - Verify passcode
- `POST /card/{uid}/change-passcode` - Change passcode

### Payments
- `POST /pay` - Make payment

### Transactions
- `GET /transactions/{uid}` - Get card transactions
- `GET /transactions` - Get all transactions (admin only)

### Admin
- `GET /cards` - Get all cards (admin only)

## Token Management

### How Tokens Work
1. User logs in with credentials
2. Backend validates and returns JWT token
3. App stores token in memory (not persisted)
4. Token is included in all API requests: `Authorization: Bearer {token}`
5. Token expires after 24 hours

### Token Storage
Currently, tokens are stored in memory only. For production, consider:
- Using AsyncStorage for persistence
- Implementing token refresh mechanism
- Secure storage for sensitive data

## Next Steps

1. ✅ Backend API fully functional
2. ✅ Authentication integrated
3. ✅ Demo credentials working
4. **Next**: Test all app features with authenticated user
5. **Next**: Implement token persistence (AsyncStorage)
6. **Next**: Add token refresh mechanism
7. **Next**: Deploy to production

## Support

For issues or questions:
1. Check backend logs: `npm run start` output
2. Check mobile app console: Expo Go app logs
3. Run test suite: `powershell -ExecutionPolicy Bypass -File Tap_and_Pay/backend/test-all.ps1`
4. Review authentication documentation: `Tap_and_Pay/AUTHENTICATION.md`
