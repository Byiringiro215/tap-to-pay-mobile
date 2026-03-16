# Restart App Guide - After Code Changes

## Issue
After updating the code with timeout fixes, the app may show build errors due to cached files.

## Solution

### Step 1: Clear All Caches
```powershell
cd my-expo-app
powershell -ExecutionPolicy Bypass -File clear-cache.ps1
```

Or manually:
```powershell
Remove-Item -Path ".expo" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "node_modules\.cache" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "node_modules\.babel-cache" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "node_modules\.metro-cache" -Recurse -Force -ErrorAction SilentlyContinue
```

### Step 2: Restart Expo
```bash
cd my-expo-app
npm start
```

### Step 3: Reconnect Tablet
1. Close Expo Go app on tablet
2. Reopen Expo Go
3. Scan new QR code from terminal
4. Wait for app to load

## What Was Changed

### Mobile App Updates
- Added 30-second timeout for all API calls
- Created `fetchWithTimeout` helper function
- Updated authentication error handling
- Improved error messages

### Backend Updates
- Added connection pool optimization
- Added request logging
- Added health check endpoint

## Expected Behavior After Restart

### Authentication
1. Select role
2. Enter credentials
3. Click Authenticate
4. Wait ~5 seconds (loading indicator shows)
5. Should see success message
6. App loads dashboard

### If Still Timing Out
1. Verify backend is running: `npm run start` in `Tap_and_Pay/backend`
2. Check backend logs for errors
3. Verify tablet is on same network
4. Test backend directly: `http://192.168.56.1:8275/health`

## Troubleshooting

### Error: "Identifier 'fetchWithTimeout' has already been declared"
**Solution**: Clear caches and restart
```powershell
powershell -ExecutionPolicy Bypass -File clear-cache.ps1
npm start
```

### Error: "Network request failed"
**Solution**: 
1. Check backend is running
2. Verify network connectivity
3. Restart both backend and app

### Error: "Request timeout"
**Solution**:
1. Check network speed
2. Verify backend response time
3. Increase timeout if needed

## Quick Restart Checklist

- [ ] Backend running: `npm run start` in `Tap_and_Pay/backend`
- [ ] Caches cleared: `powershell -ExecutionPolicy Bypass -File clear-cache.ps1`
- [ ] Expo restarted: `npm start` in `my-expo-app`
- [ ] Tablet on same network
- [ ] Expo Go app open on tablet
- [ ] QR code scanned
- [ ] App loading...

## Performance Tips

1. **Use 5GHz WiFi**: Better performance than 2.4GHz
2. **Close other apps**: Free up tablet resources
3. **Restart periodically**: Fresh start helps
4. **Monitor backend logs**: Check for errors

## Next Steps

After successful restart:
1. Test authentication with admin credentials
2. Test user login
3. Test all app features
4. Monitor response times
5. Report any issues

## Support

If issues persist:
1. Check backend logs
2. Check Expo Go console
3. Verify network connectivity
4. Restart everything
5. Check firewall settings
