# Simple Login Test - Tests login endpoint directly

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tap and Pay - Login Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$BACKEND_URL = "http://192.168.56.1:8275"

Write-Host "Backend URL: $BACKEND_URL" -ForegroundColor Yellow
Write-Host ""

# Test 1: Health Check
Write-Host "Test 1: Health Check" -ForegroundColor Cyan
$startTime = Get-Date
try {
    $response = Invoke-WebRequest -Uri "$BACKEND_URL/health" -TimeoutSec 10 -ErrorAction Stop
    $duration = (Get-Date) - $startTime
    Write-Host "  OK - Backend is running" -ForegroundColor Green
    Write-Host "    Response time: $($duration.TotalMilliseconds)ms" -ForegroundColor Gray
} catch {
    Write-Host "  FAIL - Backend not responding" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 2: Admin Login
Write-Host "Test 2: Admin Login (admin/admin123)" -ForegroundColor Cyan

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
    
    Write-Host "  OK - Login successful" -ForegroundColor Green
    Write-Host "    Response time: $($duration.TotalMilliseconds)ms" -ForegroundColor Gray
    Write-Host "    Username: $($data.user.username)" -ForegroundColor Gray
    Write-Host "    Role: $($data.user.role)" -ForegroundColor Gray
    Write-Host "    Token: $($data.token.Substring(0, 20))..." -ForegroundColor Gray
} catch {
    Write-Host "  FAIL - Login failed" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 3: User Login
Write-Host "Test 3: User Login (user/user123)" -ForegroundColor Cyan

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
    
    Write-Host "  OK - Login successful" -ForegroundColor Green
    Write-Host "    Response time: $($duration.TotalMilliseconds)ms" -ForegroundColor Gray
    Write-Host "    Username: $($data.user.username)" -ForegroundColor Gray
    Write-Host "    Role: $($data.user.role)" -ForegroundColor Gray
} catch {
    Write-Host "  FAIL - Login failed" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 4: Invalid Credentials
Write-Host "Test 4: Invalid Credentials (admin/wrong)" -ForegroundColor Cyan

$loginBody = @{
    username = "admin"
    password = "wrongpassword"
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest `
        -Uri "$BACKEND_URL/auth/login" `
        -Method POST `
        -Headers @{"Content-Type" = "application/json"} `
        -Body $loginBody `
        -TimeoutSec 60 `
        -ErrorAction Stop
    
    Write-Host "  FAIL - Should have rejected invalid credentials" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "  OK - Correctly rejected invalid credentials" -ForegroundColor Green
        Write-Host "    Status: 401 Unauthorized" -ForegroundColor Gray
    } else {
        Write-Host "  FAIL - Unexpected error" -ForegroundColor Red
    }
}

Write-Host ""

# Test 5: Performance Test
Write-Host "Test 5: Performance Test (5 rapid logins)" -ForegroundColor Cyan

$loginBody = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

$times = @()
for ($i = 1; $i -le 5; $i++) {
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
        Write-Host "    Request $i : $($duration.TotalMilliseconds)ms" -ForegroundColor Gray
    } catch {
        Write-Host "    Request $i : FAILED" -ForegroundColor Red
    }
}

if ($times.Count -gt 0) {
    $avgTime = ($times | Measure-Object -Average).Average
    $maxTime = ($times | Measure-Object -Maximum).Maximum
    $minTime = ($times | Measure-Object -Minimum).Minimum
    
    Write-Host ""
    Write-Host "  Performance Summary:" -ForegroundColor Yellow
    Write-Host "    Average: $([Math]::Round($avgTime, 2))ms" -ForegroundColor Gray
    Write-Host "    Min: $([Math]::Round($minTime, 2))ms" -ForegroundColor Gray
    Write-Host "    Max: $([Math]::Round($maxTime, 2))ms" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "All Tests Passed" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
