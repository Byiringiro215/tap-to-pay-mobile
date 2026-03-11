# Debug script to test login endpoint

$BACKEND_URL = "http://157.173.101.159:8275"

Write-Host "Testing Backend Login Endpoint" -ForegroundColor Cyan
Write-Host "Backend URL: $BACKEND_URL" -ForegroundColor Yellow
Write-Host ""

# Test 1: Check if backend is reachable
Write-Host "1. Checking if backend is reachable..." -ForegroundColor Green
try {
    $response = Invoke-WebRequest -Uri "$BACKEND_URL/auth/users" -Method GET -ErrorAction Stop
    Write-Host "OK: Backend is reachable" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor Cyan
}
catch {
    Write-Host "FAIL: Backend is NOT reachable" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: Seed users
Write-Host "`n2. Seeding demo users..." -ForegroundColor Green
try {
    $response = Invoke-WebRequest -Uri "$BACKEND_URL/auth/seed" -Method POST `
        -ContentType "application/json" -Body '{}' -ErrorAction Stop
    Write-Host "OK: Users seeded" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor Cyan
}
catch {
    Write-Host "FAIL: Seeding failed" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Login with admin
Write-Host "`n3. Testing admin login..." -ForegroundColor Green
try {
    $body = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json
    
    Write-Host "Request body: $body" -ForegroundColor Cyan
    
    $response = Invoke-WebRequest -Uri "$BACKEND_URL/auth/login" -Method POST `
        -ContentType "application/json" -Body $body -ErrorAction Stop
    
    $data = $response.Content | ConvertFrom-Json
    Write-Host "OK: Admin login successful" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor Cyan
    Write-Host "Token: $($data.token.Substring(0, 30))..." -ForegroundColor Yellow
}
catch {
    Write-Host "FAIL: Admin login failed" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $errorContent = $reader.ReadToEnd()
        Write-Host "Response: $errorContent" -ForegroundColor Red
    }
}

# Test 4: Login with user
Write-Host "`n4. Testing user login..." -ForegroundColor Green
try {
    $body = @{
        username = "user"
        password = "user123"
    } | ConvertTo-Json
    
    Write-Host "Request body: $body" -ForegroundColor Cyan
    
    $response = Invoke-WebRequest -Uri "$BACKEND_URL/auth/login" -Method POST `
        -ContentType "application/json" -Body $body -ErrorAction Stop
    
    $data = $response.Content | ConvertFrom-Json
    Write-Host "OK: User login successful" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor Cyan
    Write-Host "Token: $($data.token.Substring(0, 30))..." -ForegroundColor Yellow
}
catch {
    Write-Host "FAIL: User login failed" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $errorContent = $reader.ReadToEnd()
        Write-Host "Response: $errorContent" -ForegroundColor Red
    }
}

# Test 5: Invalid credentials
Write-Host "`n5. Testing invalid credentials..." -ForegroundColor Green
try {
    $body = @{
        username = "invalid"
        password = "wrong"
    } | ConvertTo-Json
    
    Write-Host "Request body: $body" -ForegroundColor Cyan
    
    $response = Invoke-WebRequest -Uri "$BACKEND_URL/auth/login" -Method POST `
        -ContentType "application/json" -Body $body -ErrorAction Stop
    
    Write-Host "FAIL: Should have failed but didn't" -ForegroundColor Red
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.Value__
    if ($statusCode -eq 401) {
        Write-Host "OK: Correctly rejected invalid credentials (401)" -ForegroundColor Green
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $errorContent = $reader.ReadToEnd()
            Write-Host "Response: $errorContent" -ForegroundColor Cyan
        }
    }
    else {
        Write-Host "FAIL: Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nDebug test completed!" -ForegroundColor Green
