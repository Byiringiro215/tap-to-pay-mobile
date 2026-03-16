# Quick Start - Tap and Pay

## 🚀 Start Backend (Terminal 1)
```bash
cd Tap_and_Pay/backend
npm run start
```

Expected: `Backend server running on http://0.0.0.0:8275`

## 📱 Start Mobile App (Terminal 2)
```bash
cd my-expo-app
npm start
```

Expected: `Expo Go app is ready at http://192.168.56.1:19000`

## 📲 On Tablet
1. Open **Expo Go** app
2. Scan QR code from terminal
3. Wait for app to load

## 🔐 Login Credentials

### Administrator Role
```
Username: admin
Password: admin123
```

### User Role
```
Username: user
Password: user123
```

## ✅ Test Flow
1. Select role on tablet
2. Enter credentials
3. Click Authenticate
4. Should see success message
5. App loads with dashboard

## 🔧 Network Info
- **Machine IP**: `192.168.56.1`
- **Backend URL**: `http://192.168.56.1:8275`
- **Port**: `8275`

## ❌ If Connection Fails
1. Verify backend is running
2. Check tablet is on same network
3. Verify firewall allows port 8275
4. Restart both backend and app

## 📚 Full Guides
- `TABLET_TESTING_GUIDE.md` - Detailed tablet setup
- `MOBILE_APP_SETUP.md` - Complete app configuration
- `AUTHENTICATION.md` - Auth system details
- `TEST_RESULTS.md` - Backend test results
