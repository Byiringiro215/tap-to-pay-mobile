#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

BACKEND_URL="http://localhost:8275"

echo "Testing Tap & Pay Backend Authentication"
echo "========================================"

# Seed demo users
echo -e "\n${GREEN}1. Seeding demo users...${NC}"
curl -X POST $BACKEND_URL/auth/seed \
  -H "Content-Type: application/json" \
  -d '{}' | jq .

# Test login with admin
echo -e "\n${GREEN}2. Testing admin login (admin/admin123)...${NC}"
ADMIN_TOKEN=$(curl -s -X POST $BACKEND_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.token')

if [ "$ADMIN_TOKEN" != "null" ] && [ ! -z "$ADMIN_TOKEN" ]; then
  echo -e "${GREEN}✓ Admin login successful${NC}"
  echo "Token: $ADMIN_TOKEN"
else
  echo -e "${RED}✗ Admin login failed${NC}"
fi

# Test login with user
echo -e "\n${GREEN}3. Testing user login (user/user123)...${NC}"
USER_TOKEN=$(curl -s -X POST $BACKEND_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"user","password":"user123"}' | jq -r '.token')

if [ "$USER_TOKEN" != "null" ] && [ ! -z "$USER_TOKEN" ]; then
  echo -e "${GREEN}✓ User login successful${NC}"
  echo "Token: $USER_TOKEN"
else
  echo -e "${RED}✗ User login failed${NC}"
fi

# Test getting products with token
echo -e "\n${GREEN}4. Testing products endpoint with token...${NC}"
curl -s -X GET $BACKEND_URL/products \
  -H "Authorization: Bearer $USER_TOKEN" | jq '.[] | {id, name, price}' | head -20

echo -e "\n${GREEN}Done!${NC}"
