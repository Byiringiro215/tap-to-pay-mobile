# Network Diagnostics - Comprehensive network and backend analysis

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Network and Backend Diagnostics" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Part 1: Network Configuration
Write-Host "PART 1: Network Configuration" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Your IP Addresses:" -ForegroundColor Yellow
Write-Host "  VirtualBox Host-Only: 192.168.56.1 (for tablet testing)" -ForegroundColor Green
Write-Host "  Wi-Fi: 10.12.74.121 (internet connection)" -ForegroundColor Gray
Write-Host ""

# Part 2: Backend Connectivity Tests
Write-Host "PART 2: Backend Connectivity" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

$BACKEND_URL = "http://192.168.56.1:8275"
Write-Host "Testing connection to: $BACKEND_URL" -ForegroundColor Yellow
Write-Host ""

# Test 2.1: TCP connection test
Write-Host "Test 2.1: TCP Connection (Port 8275)" -ForegroundColor Gray
$startTime = Get-Date
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $tcpClient.Connect("192.168.56.1", 8275)
    $duration = (Get-Date) - $startTime
    
    if ($tcpClient.Connected) {
        Write-Host "  OK - TCP connection successful" -ForegroundColor Green
        Write-Host "    Time: $($duration.TotalMilliseconds)ms" -ForegroundColor Gray
    }
    $tcpClient.Close()
} catch {
    Write-Host "  FAIL - TCP connection failed" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 2.2: HTTP Health Check
Write-Host "Test 2.2: HTTP Health Check" -ForegroundColor Gray
$startTime = Get-Date
try {
    $response = Invoke-WebRequest -Uri "$BACKEND_URL/health" -TimeoutSec 10 -ErrorAction Stop
    $duration = (Get-Date) - $startTime
    
    Write-Host "  OK - Health check passed" -ForegroundColor Green
    Write-Host "    Response time: $($duration.TotalMilliseconds)ms" -ForegroundColor Gray
    Write-Host "    Status: $($response.StatusCode)" -ForegroundColor Gray
} catch {
    Write-Host "  FAIL - Health check failed" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Part 3: Database Connectivity
Write-Host "PART 3: Database Connectivity" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Database Configuration:" -ForegroundColor Yellow
Write-Host "  Host: ep-cool-term-adrhpv9t-pooler.c-2.us-east-1.aws.neon.tech" -ForegroundColor Gray
Write-Host "  Port: 5432" -ForegroundColor Gray
Write-Host "  Database: neondb" -ForegroundColor Gray
Write-Host ""

Write-Host "Test 3.1: DNS Resolution" -ForegroundColor Gray
try {
    $hostname = "ep-cool-term-adrhpv9t-pooler.c-2.us-east-1.aws.neon.tech"
    $ip = [System.Net.Dns]::GetHostAddresses($hostname)[0].IPAddressToString
    Write-Host "  OK - DNS resolution successful" -ForegroundColor Green
    Write-Host "    IP: $ip" -ForegroundColor Gray
} catch {
    Write-Host "  FAIL - DNS resolution failed" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Part 4: Backend Performance Analysis
Write-Host "PART 4: Backend Performance Analysis" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Test 4.1: Login Endpoint Performance" -ForegroundColor Gray

$loginBody = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

$times = @()
for ($i = 1; $i -le 3; $i++) {
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
        Write-Host "  Request $i : $($duration.TotalMilliseconds)ms" -ForegroundColor Gray
    } catch {
        Write-Host "  Request $i : FAILED" -ForegroundColor Red
    }
}

if ($times.Count -gt 0) {
    $avgTime = ($times | Measure-Object -Average).Average
    Write-Host ""
    Write-Host "  Average response time: $([Math]::Round($avgTime, 2))ms" -ForegroundColor Yellow
}

Write-Host ""

# Part 5: Summary
Write-Host "PART 5: Summary" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan
Write-Host ""

Write-Host "Network Setup:" -ForegroundColor Yellow
Write-Host "  VirtualBox Host-Only: 192.168.56.1" -ForegroundColor Green
Write-Host "  Wi-Fi Connection: 10.12.74.121" -ForegroundColor Green
Write-Host ""

Write-Host "For Tablet Testing:" -ForegroundColor Yellow
Write-Host "  1. Tablet must be on same network as VirtualBox adapter" -ForegroundColor Gray
Write-Host "  2. Tablet should connect to 192.168.56.1:8275" -ForegroundColor Gray
Write-Host "  3. Backend must be running on development machine" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Diagnostics Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
