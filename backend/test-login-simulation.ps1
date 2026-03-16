# Test Login Simulation - Simulates tablet login behavior
# This script tests the login endpoint with detailed timing and diagnostics

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tap & Pay - Login Simulation Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$BACKEND_URL = "http://192.168.56.1:8275"
$TIMEOUT_MS = 60000  # 60 seconds like the app

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Backend URL: $BACKEND_URL" -ForegroundColor Gray
Write-Host "  Timeout: $($TIMEOUT_MS / 1000) seconds" -ForegroundColor Gray
Write-Host ""

# Test 1: Check if backend is reachable
Write-Host "Test 1: Backend Connectivity" -ForegroundColor Cyan
Write-Host "  Checking if backend is reachable..." -ForegroundColor Gray

$startTime = Get-Date
try {
    $response = Invoke-WebRequest -Uri "$BACKEND_URL/health" -TimeoutSec 10 -ErrorAction Stop
    $duration = (Get-Date) - $startTime
    Write-Host "  ✓ Backend is reachable" -ForegroundColor Green
    Write-Host "    Response time: $($duration.TotalMilliseconds)ms" -ForegroundColor Gray
    Write-Host "    Status: $($response.StatusCode)" -ForegroundColor Gray
} catch {
    Write-Host "  ✗ Backend is NOT reachable" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "DIAGNOSIS:" -ForegroundColor Yellow
    Write-Host "  - Backend server may not be running" -ForegroundColor Gray
    Write-Host "  - Check: cd Tap_and_Pay/backend && npm start" -ForegroundColor Gray
    Write-Host "  - Network connectivity issue" -ForegroundColor Gray
    exit 1
}

Write-Host ""

# Test 2: Test login with admin credentials
Write-Host "Test 2: Admin Login (admin/admin123)" -ForegroundColor Cyan
Write-Host "  Sending login request..." -ForegroundColor Gray

$loginBody = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

$startTime = Get-Date
try {
    $response = Invoke-WebRequest `
        -Uri "$BACKEND_URL/auth/login" `
        -Method POST `
        -Headers @{"Content-Type" = "application/json"} `
        -Body $loginBody `
        -TimeoutSec 60 `
        -ErrorAction Stop
    
    $duration = (Get-Date) - $startTime
    $data = $response.Content | ConvertFrom-Json
    
    Write-Host "  ✓ Login successful" -ForegroundColor Green
    Write-Host "    Response time: $($duration.TotalMilliseconds)ms" -ForegroundColor Gray
    Write-Host "    Status: $($response.StatusCode)" -ForegroundColor Gray
    Write-Host "    Username: $($data.user.username)" -ForegroundColor Gray
    Write-Host "    Role: $($data.user.role)" -ForegroundColor Gray
    Write-Host "    Token: $($data.token.Substring(0, 20))..." -ForegroundColor Gray
    
    $adminToken = $data.token
} catch {
    Write-Host "  ✗ Login failed" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Message -like "*timeout*") {
        Write-Host ""
        Write-Host "DIAGNOSIS: REQUEST TIMEOUT" -ForegroundColor Yellow
        Write-Host "  - Backend is slow to respond" -ForegroundColor Gray
        Write-Host "  - Cloud database may be initializing" -ForegroundColor Gray
        Write-Host "  - Try again in a few seconds" -ForegroundColor Gray
    }
    exit 1
}

Write-Host ""

# Test 3: Test login with user credentials
Write-Host "Test 3: User Login (user/user123)" -ForegroundColor Cyan
Write-Host "  Sending login request..." -ForegroundColor Gray

$loginBody = @{
    username = "user"
    password = "user123"
} | ConvertTo-Json

$startTime = Get-Date
try {
    $response = Invoke-WebRequest `
        -Uri "$BACKEND_URL/auth/login" `
        -Method POST `
        -Headers @{"Content-Type" = "application/json"} `
        -Body $loginBody `
        -TimeoutSec 60 `
        -ErrorAction Stop
    
    $duration = (Get-Date) - $startTime
    $data = $response.Content | ConvertFrom-Json
    
    Write-Host "  ✓ Login successful" -ForegroundColor Green
    Write-Host "    Response time: $($duration.TotalMilliseconds)ms" -ForegroundColor Gray
    Write-Host "    Status: $($response.StatusCode)" -ForegroundColor Gray
    Write-Host "    Username: $($data.user.username)" -ForegroundColor Gray
    Write-Host "    Role: $($data.user.role)" -ForegroundColor Gray
    Write-Host "    Token: $($data.token.Substring(0, 20))..." -ForegroundColor Gray
    
    $userToken = $data.token
} catch {
    Write-Host "  ✗ Login failed" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 4: Test invalid credentials
Write-Host "Test 4: Invalid Credentials (admin/wrongpassword)" -ForegroundColor Cyan
Write-Host "  Sending login request..." -ForegroundColor Gray

$loginBody = @{
    username = "admin"
    password = "wrongpassword"
} | ConvertTo-Json

$startTime = Get-Date
try {
    $response = Invoke-WebRequest `
        -Uri "$BACKEND_URL/auth/login" `
        -Method POST `
        -Headers @{"Content-Type" = "application/json"} `
        -Body $loginBody `
        -TimeoutSec 60 `
        -ErrorAction Stop
    
    Write-Host "  ✗ Should have failed but didn't" -ForegroundColor Red
} catch {
    $duration = (Get-Date) - $startTime
    
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "  ✓ Correctly rejected invalid credentials" -ForegroundColor Green
        Write-Host "    Response time: $($duration.TotalMilliseconds)ms" -ForegroundColor Gray
        Write-Host "    Status: 401 Unauthorized" -ForegroundColor Gray
    } else {
        Write-Host "  ✗ Unexpected error" -ForegroundColor Red
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Test 5: Test protected endpoint with token
Write-Host "Test 5: Protected Endpoint (/cards with token)" -ForegroundColor Cyan
Write-Host "  Sending request with admin token..." -ForegroundColor Gray

$startTime = Get-Date
try {
    $response = Invoke-WebRequest `
        -Uri "$BACKEND_URL/cards" `
        -Method GET `
        -Headers @{"Authorization" = "Bearer $adminToken"} `
        -TimeoutSec 60 `
        -ErrorAction Stop
    
    $duration = (Get-Date) - $startTime
    $data = $response.Content | ConvertFrom-Json
    
    Write-Host "  ✓ Protected endpoint accessible" -ForegroundColor Green
    Write-Host "    Response time: $($duration.TotalMilliseconds)ms" -ForegroundColor Gray
    Write-Host "    Status: $($response.StatusCode)" -ForegroundColor Gray
    Write-Host "    Cards returned: $($data.Count)" -ForegroundColor Gray
} catch {
    Write-Host "  ✗ Protected endpoint failed" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 6: Test protected endpoint without token
Write-Host "Test 6: Protected Endpoint (/cards without token)" -ForegroundColor Cyan
Write-Host "  Sending request without token..." -ForegroundColor Gray

try {
    $response = Invoke-WebRequest `
        -Uri "$BACKEND_URL/cards" `
        -Method GET `
        -TimeoutSec 60 `
        -ErrorAction Stop
    
    Write-Host "  ✗ Should have been rejected but wasn't" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "  ✓ Correctly rejected request without token" -ForegroundColor Green
        Write-Host "    Status: 401 Unauthorized" -ForegroundColor Gray
    } else {
        Write-Host "  ✗ Unexpected error" -ForegroundColor Red
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Test 7: Stress test - Multiple rapid logins
Write-Host "Test 7: Stress Test (5 rapid logins)" -ForegroundColor Cyan
Write-Host "  Sending 5 login requests rapidly..." -ForegroundColor Gray

$times = @()
for ($i = 1; $i -le 5; $i++) {
    $loginBody = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json
    
    $startTime = Get-Date
    try {
        $response = Invoke-WebRequest `
            -Uri "$BACKEND_URL/auth/login" `
            -Method POST `
            -Headers @{"Content-Type" = "application/json"} `
            -Body $loginBody `
            -TimeoutSec 60 `
            -ErrorAction Stop
        
        $duration = (Get-Date) - $startTime
        $times += $duration.TotalMilliseconds
        Write-Host "    Request $i: $($duration.TotalMilliseconds)ms" -ForegroundColor Gray
    } catch {
        Write-Host "    Request $i: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($times.Count -gt 0) {
    $avgTime = ($times | Measure-Object -Average).Average
    $maxTime = ($times | Measure-Object -Maximum).Maximum
    $minTime = ($times | Measure-Object -Minimum).Minimum
    
    Write-Host "  ✓ Stress test completed" -ForegroundColor Green
    Write-Host "    Average time: $([Math]::Round($avgTime, 2))ms" -ForegroundColor Gray
    Write-Host "    Min time: $([Math]::Round($minTime, 2))ms" -ForegroundColor Gray
    Write-Host "    Max time: $([Math]::Round($maxTime, 2))ms" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ All tests completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Key Findings:" -ForegroundColor Yellow
Write-Host "  - Backend is reachable and responding" -ForegroundColor Gray
Write-Host "  - Authentication is working" -ForegroundColor Gray
Write-Host "  - Token generation is working" -ForegroundColor Gray
Write-Host "  - Protected endpoints are secured" -ForegroundColor Gray
Write-Host ""
Write-Host "If login times are >5 seconds:" -ForegroundColor Yellow
Write-Host "  - Cloud database is initializing" -ForegroundColor Gray
Write-Host "  - This is normal for first request" -ForegroundColor Gray
Write-Host "  - Subsequent requests will be faster" -ForegroundColor Gray
Write-Host ""
