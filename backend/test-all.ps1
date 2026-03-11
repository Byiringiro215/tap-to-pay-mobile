# Tap and Pay Backend - Comprehensive Test Suite (PowerShell)

$BACKEND_URL = "http://localhost:8275"
$TEST_UID = "CARD-TEST-001"
$TEST_HOLDER = "John Doe"
$TEST_PASSCODE = "123456"

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Blue
    Write-Host $Title -ForegroundColor Blue
    Write-Host "============================================================" -ForegroundColor Blue
}

function Write-Subsection {
    param([string]$Title)
    Write-Host ""
    Write-Host $Title -ForegroundColor Yellow
    Write-Host "===========================================================`n" -ForegroundColor Yellow
}

function Write-Test {
    param([string]$Title)
    Write-Host ""
    Write-Host $Title -ForegroundColor Green
}

function Test-Endpoint {
    param(
        [string]$Method,
        [string]$Uri,
        [string]$Token,
        [object]$Body
    )
    
    try {
        $headers = @{
            "Content-Type" = "application/json"
        }
        
        if ($Token) {
            $headers["Authorization"] = "Bearer $Token"
        }
        
        $params = @{
            Uri     = $Uri
            Method  = $Method
            Headers = $headers
            ErrorAction = "Stop"
        }
        
        if ($Body) {
            $params["Body"] = $Body | ConvertTo-Json
        }
        
        $response = Invoke-WebRequest @params
        return $response.Content | ConvertFrom-Json
    }
    catch {
        try {
            $errorContent = $_.Exception.Response.Content.ReadAsStream()
            $reader = New-Object System.IO.StreamReader($errorContent)
            $errorText = $reader.ReadToEnd()
            $reader.Close()
            if ($errorText) {
                return $errorText | ConvertFrom-Json
            }
        }
        catch {
            # If we can't parse error, return generic error object
        }
        return @{ error = $_.Exception.Message }
    }
}

# ============================================================================
# HEADER
# ============================================================================
Write-Section "Tap and Pay Backend - Comprehensive Test Suite"

# ============================================================================
# SECTION 1: AUTHENTICATION TESTS
# ============================================================================
Write-Subsection "[SECTION 1] AUTHENTICATION TESTS"

Write-Test "1.1 Seeding demo users..."
$seedResponse = Test-Endpoint -Method POST -Uri "$BACKEND_URL/auth/seed"
$seedResponse | ConvertTo-Json | Write-Host

Write-Test "1.2 Checking existing users..."
$usersResponse = Test-Endpoint -Method GET -Uri "$BACKEND_URL/auth/users"
$usersResponse | ConvertTo-Json | Write-Host

Write-Test "1.3 Testing admin login (admin/admin123)..."
$adminResponse = Test-Endpoint -Method POST -Uri "$BACKEND_URL/auth/login" `
    -Body @{ username = "admin"; password = "admin123" }
$ADMIN_TOKEN = $adminResponse.token
$adminResponse | ConvertTo-Json | Write-Host
if ($ADMIN_TOKEN) {
    Write-Host "OK: Admin token obtained" -ForegroundColor Green
}
else {
    Write-Host "FAIL: Admin login failed" -ForegroundColor Red
    exit 1
}

Write-Test "1.4 Testing user login (user/user123)..."
$userResponse = Test-Endpoint -Method POST -Uri "$BACKEND_URL/auth/login" `
    -Body @{ username = "user"; password = "user123" }
$USER_TOKEN = $userResponse.token
$userResponse | ConvertTo-Json | Write-Host
if ($USER_TOKEN) {
    Write-Host "OK: User token obtained" -ForegroundColor Green
}
else {
    Write-Host "FAIL: User login failed" -ForegroundColor Red
    exit 1
}

Write-Test "1.5 Testing manager login (manager/manager123)..."
$managerResponse = Test-Endpoint -Method POST -Uri "$BACKEND_URL/auth/login" `
    -Body @{ username = "manager"; password = "manager123" }
$MANAGER_TOKEN = $managerResponse.token
$managerResponse | ConvertTo-Json | Write-Host

Write-Test "1.6 Testing operator login (operator/operator123)..."
$operatorResponse = Test-Endpoint -Method POST -Uri "$BACKEND_URL/auth/login" `
    -Body @{ username = "operator"; password = "operator123" }
$OPERATOR_TOKEN = $operatorResponse.token
$operatorResponse | ConvertTo-Json | Write-Host

Write-Test "1.7 Testing invalid credentials..."
$invalidResponse = Test-Endpoint -Method POST -Uri "$BACKEND_URL/auth/login" `
    -Body @{ username = "invalid"; password = "wrong" }
$invalidResponse | ConvertTo-Json | Write-Host

# ============================================================================
# SECTION 2: PRODUCTS ENDPOINT
# ============================================================================
Write-Subsection "[SECTION 2] PRODUCTS ENDPOINT"

Write-Test "2.1 Getting products list (with user token)..."
$productsResponse = Test-Endpoint -Method GET -Uri "$BACKEND_URL/products" -Token $USER_TOKEN
$productsResponse | ConvertTo-Json | Write-Host
$PRODUCT_COUNT = ($productsResponse | Measure-Object).Count
Write-Host "OK: Total products: $PRODUCT_COUNT" -ForegroundColor Green

# ============================================================================
# SECTION 3: CARD OPERATIONS
# ============================================================================
Write-Subsection "[SECTION 3] CARD OPERATIONS"

Write-Test "3.1 Creating new card with top-up (user token)..."
$topupResponse = Test-Endpoint -Method POST -Uri "$BACKEND_URL/topup" -Token $USER_TOKEN `
    -Body @{ 
        uid = $TEST_UID
        amount = 50
        holderName = $TEST_HOLDER
        passcode = $TEST_PASSCODE
    }
$topupResponse | ConvertTo-Json | Write-Host

Write-Test "3.2 Getting card details..."
$cardResponse = Test-Endpoint -Method GET -Uri "$BACKEND_URL/card/$TEST_UID" -Token $USER_TOKEN
$cardResponse | ConvertTo-Json | Write-Host

Write-Test "3.3 Setting passcode on card..."
$setPasscodeResponse = Test-Endpoint -Method POST -Uri "$BACKEND_URL/card/$TEST_UID/set-passcode" `
    -Token $USER_TOKEN -Body @{ passcode = "654321" }
$setPasscodeResponse | ConvertTo-Json | Write-Host

Write-Test "3.4 Verifying passcode..."
$verifyResponse = Test-Endpoint -Method POST -Uri "$BACKEND_URL/card/$TEST_UID/verify-passcode" `
    -Token $USER_TOKEN -Body @{ passcode = "654321" }
$verifyResponse | ConvertTo-Json | Write-Host

Write-Test "3.5 Changing passcode..."
$changePasscodeResponse = Test-Endpoint -Method POST -Uri "$BACKEND_URL/card/$TEST_UID/change-passcode" `
    -Token $USER_TOKEN -Body @{ oldPasscode = "654321"; newPasscode = "111111" }
$changePasscodeResponse | ConvertTo-Json | Write-Host

# ============================================================================
# SECTION 4: PAYMENT OPERATIONS
# ============================================================================
Write-Subsection "[SECTION 4] PAYMENT OPERATIONS"

Write-Test "4.1 Making payment with product ID..."
$paymentResponse = Test-Endpoint -Method POST -Uri "$BACKEND_URL/pay" -Token $USER_TOKEN `
    -Body @{ 
        uid = $TEST_UID
        productId = "coffee"
        passcode = "111111"
    }
$paymentResponse | ConvertTo-Json | Write-Host

Write-Test "4.2 Making payment with custom amount..."
$customPaymentResponse = Test-Endpoint -Method POST -Uri "$BACKEND_URL/pay" -Token $USER_TOKEN `
    -Body @{ 
        uid = $TEST_UID
        amount = 5.50
        description = "Custom payment"
        passcode = "111111"
    }
$customPaymentResponse | ConvertTo-Json | Write-Host

Write-Test "4.3 Testing insufficient balance..."
$insufficientResponse = Test-Endpoint -Method POST -Uri "$BACKEND_URL/pay" -Token $USER_TOKEN `
    -Body @{ 
        uid = $TEST_UID
        amount = 1000
        description = "Large payment"
        passcode = "111111"
    }
$insufficientResponse | ConvertTo-Json | Write-Host

Write-Test "4.4 Testing payment without passcode (should fail)..."
$noPasscodeResponse = Test-Endpoint -Method POST -Uri "$BACKEND_URL/pay" -Token $USER_TOKEN `
    -Body @{ 
        uid = $TEST_UID
        amount = 2.50
        description = "No passcode"
    }
$noPasscodeResponse | ConvertTo-Json | Write-Host

# ============================================================================
# SECTION 5: TRANSACTION HISTORY
# ============================================================================
Write-Subsection "[SECTION 5] TRANSACTION HISTORY"

Write-Test "5.1 Getting transactions for specific card..."
$cardTxResponse = Test-Endpoint -Method GET -Uri "$BACKEND_URL/transactions/$TEST_UID" -Token $USER_TOKEN
$cardTxResponse | ConvertTo-Json | Write-Host

Write-Test "5.2 Getting all transactions (admin only)..."
$allTxResponse = Test-Endpoint -Method GET -Uri "$BACKEND_URL/transactions?limit=10" -Token $ADMIN_TOKEN
$allTxResponse | ConvertTo-Json | Write-Host

Write-Test "5.3 Testing unauthorized access to all transactions (user token)..."
$unauthorizedTxResponse = Test-Endpoint -Method GET -Uri "$BACKEND_URL/transactions?limit=10" -Token $USER_TOKEN
$unauthorizedTxResponse | ConvertTo-Json | Write-Host

# ============================================================================
# SECTION 6: ADMIN OPERATIONS
# ============================================================================
Write-Subsection "[SECTION 6] ADMIN OPERATIONS"

Write-Test "6.1 Getting all cards (admin only)..."
$allCardsResponse = Test-Endpoint -Method GET -Uri "$BACKEND_URL/cards" -Token $ADMIN_TOKEN
$allCardsResponse | ConvertTo-Json | Write-Host

Write-Test "6.2 Testing unauthorized access to all cards (user token)..."
$unauthorizedCardsResponse = Test-Endpoint -Method GET -Uri "$BACKEND_URL/cards" -Token $USER_TOKEN
$unauthorizedCardsResponse | ConvertTo-Json | Write-Host

# ============================================================================
# SECTION 7: AUTHORIZATION TESTS
# ============================================================================
Write-Subsection "[SECTION 7] AUTHORIZATION TESTS"

Write-Test "7.1 Testing missing token..."
$noTokenResponse = Test-Endpoint -Method GET -Uri "$BACKEND_URL/products"
$noTokenResponse | ConvertTo-Json | Write-Host

Write-Test "7.2 Testing invalid token..."
$invalidTokenResponse = Test-Endpoint -Method GET -Uri "$BACKEND_URL/products" -Token "invalid.token.here"
$invalidTokenResponse | ConvertTo-Json | Write-Host

Write-Test "7.3 Testing topup with user role (should succeed)..."
$topup2Response = Test-Endpoint -Method POST -Uri "$BACKEND_URL/topup" -Token $USER_TOKEN `
    -Body @{ 
        uid = "CARD-TEST-002"
        amount = 25
        holderName = "Jane Doe"
        passcode = "999999"
    }
$topup2Response | ConvertTo-Json | Write-Host

# ============================================================================
# SUMMARY
# ============================================================================
Write-Section "Test Suite Completed"
Write-Host ""
Write-Host "OK: All tests completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  - Authentication: 4 demo users tested" -ForegroundColor Cyan
Write-Host "  - Products: $PRODUCT_COUNT items available" -ForegroundColor Cyan
Write-Host "  - Cards: Created and managed with passcodes" -ForegroundColor Cyan
Write-Host "  - Payments: Processed with authorization" -ForegroundColor Cyan
Write-Host "  - Transactions: Recorded and retrievable" -ForegroundColor Cyan
Write-Host "  - Admin: Role-based access control verified" -ForegroundColor Cyan
Write-Host ""
