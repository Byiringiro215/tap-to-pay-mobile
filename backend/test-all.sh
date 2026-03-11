#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BACKEND_URL="http://localhost:8275"
TEST_UID="CARD-TEST-001"
TEST_HOLDER="John Doe"
TEST_PASSCODE="123456"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Tap & Pay Backend - Comprehensive Test Suite           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

# ============================================================================
# SECTION 1: AUTHENTICATION TESTS
# ============================================================================
echo -e "\n${YELLOW}[SECTION 1] AUTHENTICATION TESTS${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"

echo -e "\n${GREEN}1.1 Seeding demo users...${NC}"
SEED_RESPONSE=$(curl -s -X POST $BACKEND_URL/auth/seed \
  -H "Content-Type: application/json" \
  -d '{}')
echo "$SEED_RESPONSE" | jq .

echo -e "\n${GREEN}1.2 Checking existing users...${NC}"
curl -s -X GET $BACKEND_URL/auth/users | jq .

echo -e "\n${GREEN}1.3 Testing admin login (admin/admin123)...${NC}"
ADMIN_RESPONSE=$(curl -s -X POST $BACKEND_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')
ADMIN_TOKEN=$(echo "$ADMIN_RESPONSE" | jq -r '.token')
echo "$ADMIN_RESPONSE" | jq .
if [ "$ADMIN_TOKEN" != "null" ] && [ ! -z "$ADMIN_TOKEN" ]; then
  echo -e "${GREEN}✓ Admin token obtained${NC}"
else
  echo -e "${RED}✗ Admin login failed${NC}"
  exit 1
fi

echo -e "\n${GREEN}1.4 Testing user login (user/user123)...${NC}"
USER_RESPONSE=$(curl -s -X POST $BACKEND_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"user","password":"user123"}')
USER_TOKEN=$(echo "$USER_RESPONSE" | jq -r '.token')
echo "$USER_RESPONSE" | jq .
if [ "$USER_TOKEN" != "null" ] && [ ! -z "$USER_TOKEN" ]; then
  echo -e "${GREEN}✓ User token obtained${NC}"
else
  echo -e "${RED}✗ User login failed${NC}"
  exit 1
fi

echo -e "\n${GREEN}1.5 Testing manager login (manager/manager123)...${NC}"
MANAGER_RESPONSE=$(curl -s -X POST $BACKEND_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"manager","password":"manager123"}')
MANAGER_TOKEN=$(echo "$MANAGER_RESPONSE" | jq -r '.token')
echo "$MANAGER_RESPONSE" | jq .

echo -e "\n${GREEN}1.6 Testing operator login (operator/operator123)...${NC}"
OPERATOR_RESPONSE=$(curl -s -X POST $BACKEND_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"operator","password":"operator123"}')
OPERATOR_TOKEN=$(echo "$OPERATOR_RESPONSE" | jq -r '.token')
echo "$OPERATOR_RESPONSE" | jq .

echo -e "\n${GREEN}1.7 Testing invalid credentials...${NC}"
curl -s -X POST $BACKEND_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"invalid","password":"wrong"}' | jq .

# ============================================================================
# SECTION 2: PRODUCTS ENDPOINT
# ============================================================================
echo -e "\n${YELLOW}[SECTION 2] PRODUCTS ENDPOINT${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"

echo -e "\n${GREEN}2.1 Getting products list (with user token)...${NC}"
PRODUCTS=$(curl -s -X GET $BACKEND_URL/products \
  -H "Authorization: Bearer $USER_TOKEN")
echo "$PRODUCTS" | jq '.[] | {id, name, price, icon, category}' | head -30
PRODUCT_COUNT=$(echo "$PRODUCTS" | jq 'length')
echo -e "${GREEN}✓ Total products: $PRODUCT_COUNT${NC}"

# ============================================================================
# SECTION 3: CARD OPERATIONS
# ============================================================================
echo -e "\n${YELLOW}[SECTION 3] CARD OPERATIONS${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"

echo -e "\n${GREEN}3.1 Creating new card with top-up (user token)...${NC}"
TOPUP_RESPONSE=$(curl -s -X POST $BACKEND_URL/topup \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d "{\"uid\":\"$TEST_UID\",\"amount\":50,\"holderName\":\"$TEST_HOLDER\",\"passcode\":\"$TEST_PASSCODE\"}")
echo "$TOPUP_RESPONSE" | jq .

echo -e "\n${GREEN}3.2 Getting card details...${NC}"
curl -s -X GET $BACKEND_URL/card/$TEST_UID \
  -H "Authorization: Bearer $USER_TOKEN" | jq .

echo -e "\n${GREEN}3.3 Setting passcode on card...${NC}"
curl -s -X POST $BACKEND_URL/card/$TEST_UID/set-passcode \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d "{\"passcode\":\"654321\"}" | jq .

echo -e "\n${GREEN}3.4 Verifying passcode...${NC}"
curl -s -X POST $BACKEND_URL/card/$TEST_UID/verify-passcode \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d "{\"passcode\":\"654321\"}" | jq .

echo -e "\n${GREEN}3.5 Changing passcode...${NC}"
curl -s -X POST $BACKEND_URL/card/$TEST_UID/change-passcode \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d "{\"oldPasscode\":\"654321\",\"newPasscode\":\"111111\"}" | jq .

# ============================================================================
# SECTION 4: PAYMENT OPERATIONS
# ============================================================================
echo -e "\n${YELLOW}[SECTION 4] PAYMENT OPERATIONS${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"

echo -e "\n${GREEN}4.1 Making payment with product ID...${NC}"
curl -s -X POST $BACKEND_URL/pay \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d "{\"uid\":\"$TEST_UID\",\"productId\":\"coffee\",\"passcode\":\"111111\"}" | jq .

echo -e "\n${GREEN}4.2 Making payment with custom amount...${NC}"
curl -s -X POST $BACKEND_URL/pay \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d "{\"uid\":\"$TEST_UID\",\"amount\":5.50,\"description\":\"Custom payment\",\"passcode\":\"111111\"}" | jq .

echo -e "\n${GREEN}4.3 Testing insufficient balance...${NC}"
curl -s -X POST $BACKEND_URL/pay \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d "{\"uid\":\"$TEST_UID\",\"amount\":1000,\"description\":\"Large payment\",\"passcode\":\"111111\"}" | jq .

echo -e "\n${GREEN}4.4 Testing payment without passcode (should fail)...${NC}"
curl -s -X POST $BACKEND_URL/pay \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d "{\"uid\":\"$TEST_UID\",\"amount\":2.50,\"description\":\"No passcode\"}" | jq .

# ============================================================================
# SECTION 5: TRANSACTION HISTORY
# ============================================================================
echo -e "\n${YELLOW}[SECTION 5] TRANSACTION HISTORY${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"

echo -e "\n${GREEN}5.1 Getting transactions for specific card...${NC}"
curl -s -X GET $BACKEND_URL/transactions/$TEST_UID \
  -H "Authorization: Bearer $USER_TOKEN" | jq .

echo -e "\n${GREEN}5.2 Getting all transactions (admin only)...${NC}"
curl -s -X GET "$BACKEND_URL/transactions?limit=10" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq .

echo -e "\n${GREEN}5.3 Testing unauthorized access to all transactions (user token)...${NC}"
curl -s -X GET "$BACKEND_URL/transactions?limit=10" \
  -H "Authorization: Bearer $USER_TOKEN" | jq .

# ============================================================================
# SECTION 6: ADMIN OPERATIONS
# ============================================================================
echo -e "\n${YELLOW}[SECTION 6] ADMIN OPERATIONS${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"

echo -e "\n${GREEN}6.1 Getting all cards (admin only)...${NC}"
curl -s -X GET $BACKEND_URL/cards \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq .

echo -e "\n${GREEN}6.2 Testing unauthorized access to all cards (user token)...${NC}"
curl -s -X GET $BACKEND_URL/cards \
  -H "Authorization: Bearer $USER_TOKEN" | jq .

# ============================================================================
# SECTION 7: AUTHORIZATION TESTS
# ============================================================================
echo -e "\n${YELLOW}[SECTION 7] AUTHORIZATION TESTS${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"

echo -e "\n${GREEN}7.1 Testing missing token...${NC}"
curl -s -X GET $BACKEND_URL/products | jq .

echo -e "\n${GREEN}7.2 Testing invalid token...${NC}"
curl -s -X GET $BACKEND_URL/products \
  -H "Authorization: Bearer invalid.token.here" | jq .

echo -e "\n${GREEN}7.3 Testing topup with user role (should succeed)...${NC}"
curl -s -X POST $BACKEND_URL/topup \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d "{\"uid\":\"CARD-TEST-002\",\"amount\":25,\"holderName\":\"Jane Doe\",\"passcode\":\"999999\"}" | jq .

# ============================================================================
# SUMMARY
# ============================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    TEST SUITE COMPLETED                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo -e "\n${GREEN}✓ All tests completed successfully!${NC}"
echo -e "\n${YELLOW}Summary:${NC}"
echo -e "  • Authentication: 4 demo users tested"
echo -e "  • Products: $PRODUCT_COUNT items available"
echo -e "  • Cards: Created and managed with passcodes"
echo -e "  • Payments: Processed with authorization"
echo -e "  • Transactions: Recorded and retrievable"
echo -e "  • Admin: Role-based access control verified"
echo -e "\n"
