# Debugging Guide - Authentication Issues

## 🔍 What Was Fixed

### 1. Backend URL Configuration
**Issue**: .env file had wrong IP (157.173.101.159 instead of 192.168.56.1)
**Fix**: Updated .env to use correct machine IP

**File**: `my-expo-app/.env`
```
# Before
EXPO_PUBLIC_BACKEND_URL=http://157.173.101.159:8275

# After
EXPO_PUBLIC_BACKEND_URL=http://192.168.56.1:8275
```

### 2. Added Comprehensive Logging
**Files Modified**:
- `my-expo-app/src/screens/AuthenticationScreen.tsx`
- `my-expo-app/src/context/AppContext.tsx`

**Logging Added**:
- Authentication flow steps
- API request/response times
- Error details
- Socket connection status

---

## 📋 How to Debug

### Step 1: Check Backend URL
**In Expo Go app console, look for:**
```
=== AUTHENTICATION START ===
Timestamp: 2026-03-16T...
Backend URL: http://192.168.56.1:8275
Username: admin
Role: admin
```

**If Backend URL is wrong:**
1. Clear app caches: `powershell -ExecutionPolicy Bypass -File clear-cache.ps1`
2. Restart app: `npm start`
3. Rescan QR code

### Step 2: Monitor Authentication Steps
**Expected log sequence:**
```
Step 1: Creating abort controller...
Step 2: Sending login request...
Step 3: Response received in XXXms
Step 4: Response parsed
Step 5: Login successful, checking role...
Step 6: Role matches, storing token...
Step 7: Token stored, showing success alert...
=== AUTHENTICATION SUCCESS ===
```

### Step 3: Check API Response Times
**Look for:**
```
[API] Fetching: POST http://192.168.56.1:8275/auth/login
[API] Response: 200 in 524ms for http://192.168.56.1:8275/auth/login
```

**If response time is > 60000ms:**
- Request timed out
- Check backend is running
- Check network connectivity

### Step 4: Check Socket Connection
**Look for:**
```
[Socket] Connecting to: http://192.168.56.1:8275
[Socket] Connected successfully
```

**If socket doesn't connect:**
- Backend might not be running
- Check firewall settings
- Verify network connectivity

---

## 🚨 Common Issues and Solutions

### Issue 1: "Failed to connect to server"
**Logs to check:**
```
Backend URL: http://157.173.101.159:8275  ← WRONG IP!
```

**Solution:**
1. Update .env file with correct IP (192.168.56.1)
2. Clear caches
3. Restart app

### Issue 2: "Request timeout"
**Logs to check:**
```
Step 2: Timeout triggered after 60 seconds
```

**Solution:**
1. Verify backend is running: `npm run start` in `Tap_and_Pay/backend`
2. Check network connectivity
3. Verify tablet is on same network as machine

### Issue 3: "Invalid username or password"
**Logs to check:**
```
Step 5: Login failed
Error from server: Invalid username or password
```

**Solution:**
1. Verify credentials are correct
2. Check backend has demo users
3. Try: admin/admin123 or user/user123

### Issue 4: "This account is for admin role, not user"
**Logs to check:**
```
Expected: user, Got: admin
```

**Solution:**
1. Select correct role matching account
2. Admin accounts: select "Administrator"
3. User accounts: select "Normal User"

### Issue 5: Button stays in loading state
**Logs to check:**
```
Step 1: Creating abort controller...
Step 2: Sending login request...
[No response after 60 seconds]
```

**Solution:**
1. Check backend is running
2. Check network connectivity
3. Check firewall allows port 8275
4. Restart backend and app

---

## 🔧 How to View Logs

### On Tablet (Expo Go)
1. Shake device to open menu
2. Tap "View logs"
3. Look for logs starting with `===` or `[API]` or `[Socket]`

### On Machine (Terminal)
```bash
# If running Expo in terminal
npm start

# Logs appear in terminal
```

---

## 📊 Log Format Reference

### Authentication Logs
```
=== AUTHENTICATION START ===
Timestamp: [ISO timestamp]
Backend URL: [URL being used]
Username: [entered username]
Role: [selected role]
Step 1: Creating abort controller...
Step 2: Sending login request...
Step 3: Response received in XXXms
Step 4: Response parsed
Step 5: [Success or Error]
=== AUTHENTICATION SUCCESS/ERROR ===
```

### API Logs
```
[API] Fetching: [METHOD] [URL]
[API] Response: [STATUS] in [TIME]ms for [URL]
[API] Error after [TIME]ms for [URL]: [ERROR]
```

### Socket Logs
```
[Socket] Connecting to: [URL]
[Socket] Connected successfully
[Socket] Disconnected
```

---

## ✅ Verification Checklist

Before testing, verify:
- [ ] Backend running: `npm run start` in `Tap_and_Pay/backend`
- [ ] Correct IP in .env: `192.168.56.1`
- [ ] Caches cleared: `powershell -ExecutionPolicy Bypass -File clear-cache.ps1`
- [ ] App restarted: `npm start` in `my-expo-app`
- [ ] QR code scanned on tablet
- [ ] Tablet on same network as machine
- [ ] Firewall allows port 8275

---

## 🎯 Expected Behavior

### Successful Login
1. User enters credentials
2. Button shows loading state
3. Logs show authentication steps
4. Response received in ~500-1000ms
5. Success alert appears
6. App loads dashboard

### Failed Login
1. User enters wrong credentials
2. Button shows loading state
3. Logs show error
4. Error alert appears
5. User can retry

---

## 📞 Troubleshooting Steps

### If Still Having Issues

1. **Check Backend**
   ```bash
   # Verify backend is running
   netstat -ano | findstr "8275"
   
   # If not running, start it
   npm run start
   ```

2. **Check Network**
   ```bash
   # Verify tablet can reach backend
   ping 192.168.56.1
   ```

3. **Check Logs**
   - Look for error messages in Expo Go console
   - Check backend terminal for errors
   - Look for timeout messages

4. **Clear Everything**
   ```bash
   # Clear caches
   powershell -ExecutionPolicy Bypass -File clear-cache.ps1
   
   # Restart app
   npm start
   
   # Rescan QR code on tablet
   ```

5. **Restart Everything**
   - Stop backend
   - Stop mobile app
   - Restart backend: `npm run start`
   - Restart app: `npm start`
   - Rescan QR code

---

## 📝 Summary

✅ **Backend URL fixed** (192.168.56.1)
✅ **Comprehensive logging added**
✅ **Easy debugging with step-by-step logs**
✅ **Clear error messages**

**Status**: Ready for debugging and testing
