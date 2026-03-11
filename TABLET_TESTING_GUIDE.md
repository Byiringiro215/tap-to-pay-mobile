# Tablet Testing Guide

## Quick Setup for Tablet Testing

### Your Network Configuration
- **Machine IP**: `192.168.56.1`
- **Backend Port**: `8275`
- **Backend URL**: `http://192.168.56.1:8275`

### Prerequisites
1. Backend server running on your machine
2. Tablet on the same network as your machine
3. Expo Go app installed on tablet

## Step 1: Start Backend Server

```bash
cd Tap_and_Pay/backend
npm run start
```

Wait for output:
```
Backend server running on http://0.0.0.0:8275
✓ Database tables initialized
✓ Demo users created
✓ Connected to MQTT Broker
```

## Step 2: Verify Backend is Accessible

```powershell
# Test from your machine
$response = Invoke-WebRequest -Uri "http://192.168.56.1:8275/auth/users" -Method GET
$response.Content | ConvertFrom-Json | ConvertTo-Json
```

Should show 4 demo users.

## Step 3: Start Mobile App

```bash
cd my-expo-app
npm start
```

You'll see:
```
Expo Go app is ready at http://192.168.56.1:19000
```

## Step 4: Connect Tablet

1. Open **Expo Go** app on tablet
2. Scan the QR code shown in terminal
3. App will load on tablet

## Step 5: Test Authentication

### Test Admin Login
1. Select **Administrator** role
2. Username: `admin`
3. Password: `admin123`
4. Click **Authenticate**
5. Should see success and navigate to app

### Test User Login
1. Go back to role selection
2. Select **Normal User** role
3. Username: `user`
4. Password: `user123`
5. Click **Authenticate**
6. Should see success and navigate to app

## Demo Credentials

### Admin Accounts
| Username | Password | Role |
|----------|----------|------|
| admin | admin123 | admin |
| manager | manager123 | admin |

### User Accounts
| Username | Password | Role |
|----------|----------|------|
| user | user123 | user |
| operator | operator123 | user |

## Troubleshooting

### Tablet Can't Connect to Backend

**Problem**: "Failed to connect to server"

**Solution**:
1. Verify tablet is on same network as machine
2. Check firewall isn't blocking port 8275
3. Verify backend is running: `npm run start`
4. Test connection from machine:
   ```powershell
   Invoke-WebRequest -Uri "http://192.168.56.1:8275/auth/users"
   ```

### Wrong Credentials Error

**Problem**: "Invalid username or password" for correct credentials

**Solution**:
1. Restart backend server (auto-seeds demo users)
2. Verify you're using exact credentials from table above
3. Check backend logs for errors

### Role Mismatch Error

**Problem**: "This account is for admin role, not user"

**Solution**:
1. Go back to role selection
2. Select the correct role for your account
3. Admin accounts: select "Administrator"
4. User accounts: select "Normal User"

### App Crashes After Login

**Problem**: App crashes or shows blank screen

**Solution**:
1. Check Expo Go console for errors
2. Restart app: close and reopen Expo Go
3. Restart backend: stop and run `npm run start` again
4. Check network connectivity

## Testing Features

Once logged in, you can test:

### Admin Features
- View all cards
- View all transactions
- Top-up cards
- Process payments
- Manage system

### User Features
- Top-up own cards
- View marketplace
- Make purchases
- View transaction history
- Manage passcodes

## Network Troubleshooting

### Find Your Machine IP
```powershell
ipconfig | Select-String "IPv4 Address"
```

### Check if Port 8275 is Open
```powershell
netstat -ano | findstr "8275"
```

Should show:
```
TCP    0.0.0.0:8275    0.0.0.0:0    LISTENING
```

### Test Backend Connectivity
```powershell
# From machine
Test-NetConnection -ComputerName 192.168.56.1 -Port 8275

# Should show: TcpTestSucceeded : True
```

## Performance Tips

1. **Keep backend running**: Don't close terminal
2. **Use 5GHz WiFi**: Better performance than 2.4GHz
3. **Close other apps**: Free up tablet resources
4. **Clear app cache**: If experiencing issues
5. **Restart periodically**: Fresh start helps

## Next Steps

After successful authentication:
1. Test top-up functionality
2. Test marketplace purchases
3. Test transaction history
4. Test admin features (if admin account)
5. Test logout and re-login

## Support

For issues:
1. Check backend logs in terminal
2. Check Expo Go console on tablet
3. Verify network connectivity
4. Restart backend and app
5. Check firewall settings
