# Tap & Pay - Authentication System

This document outlines the authentication system implemented across all portals of the Tap & Pay application.

## Overview

The Tap & Pay system now includes a comprehensive authentication system with:
- **Backend API**: JWT-based token authentication
- **Mobile App**: Role-based login (Admin/User) with password verification
- **Web Frontend**: Session-based authentication
- **Arduino Firmware**: RFID card-based authentication

## Backend Authentication (Node.js/Express)

### Authentication Endpoints

#### 1. Register User
```bash
POST /auth/register
Content-Type: application/json

{
  "username": "admin",
  "password": "admin123",
  "role": "admin"  // or "user"
}

Response:
{
  "success": true,
  "message": "User registered successfully",
  "user": {
    "id": "user_id",
    "username": "admin",
    "role": "admin"
  }
}
```

#### 2. Login
```bash
POST /auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "admin123"
}

Response:
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "user_id",
    "username": "admin",
    "role": "admin"
  }
}
```

### Using the Token

All protected endpoints require the JWT token in the Authorization header:

```bash
GET /products
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Protected Endpoints

| Endpoint | Method | Auth Required | Role Required | Description |
|----------|--------|---------------|---------------|-------------|
| `/auth/register` | POST | No | - | Register new user |
| `/auth/login` | POST | No | - | Login and get token |
| `/topup` | POST | Yes | admin, user | Top up card balance |
| `/pay` | POST | Yes | admin, user | Process payment |
| `/products` | GET | Yes | - | Get product catalog |
| `/card/:uid` | GET | Yes | - | Get card details |
| `/cards` | GET | Yes | admin | Get all cards (admin only) |
| `/transactions/:uid` | GET | Yes | - | Get card transactions |
| `/transactions` | GET | Yes | admin | Get all transactions (admin only) |
| `/card/:uid/set-passcode` | POST | Yes | - | Set card passcode |
| `/card/:uid/change-passcode` | POST | Yes | - | Change card passcode |
| `/card/:uid/verify-passcode` | POST | Yes | - | Verify card passcode |

## Mobile App Authentication

### Flow

1. **Role Selection** - User selects Admin or User role
2. **Authentication Screen** - User enters password
3. **App Access** - Upon successful authentication, user gains access to the app

### Demo Credentials

- **Admin**: 
  - Username: `admin`, Password: `admin123`
  - Username: `manager`, Password: `manager123`
- **User**: 
  - Username: `user`, Password: `user123`
  - Username: `operator`, Password: `operator123`

### Features

- Logout button in header (accessible from all screens)
- Role-based access control
- Transaction history with tabs and pagination
- White and black professional UI theme

## Web Frontend Authentication

The web frontend should implement:

1. **Login Page** - Username and password input
2. **Session Management** - Store JWT token in localStorage
3. **Protected Routes** - Redirect to login if token is invalid
4. **Token Refresh** - Implement token refresh mechanism for 24-hour tokens

### Example Implementation

```javascript
// Login
async function login(username, password) {
  const response = await fetch('http://backend-url/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password })
  });
  
  const data = await response.json();
  if (data.success) {
    localStorage.setItem('token', data.token);
    localStorage.setItem('user', JSON.stringify(data.user));
    // Redirect to dashboard
  }
}

// API Call with Token
async function fetchProtected(endpoint) {
  const token = localStorage.getItem('token');
  const response = await fetch(`http://backend-url${endpoint}`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  return response.json();
}
```

## Arduino Firmware Authentication

### RFID Card Authentication

The Arduino firmware authenticates users through:

1. **RFID Card Scanning** - Card UID is read
2. **Backend Verification** - UID is verified against database
3. **Passcode Verification** - 6-digit passcode is required for transactions
4. **Transaction Processing** - Payment/Top-up is processed

### Passcode System

- **6-digit numeric passcode** required for new cards
- **Hashed storage** using bcrypt (10 salt rounds)
- **Verification endpoints** for secure passcode checking
- **Change passcode** functionality with old passcode verification

## Security Features

1. **JWT Tokens** - Secure token-based authentication
2. **Password Hashing** - bcrypt with 10 salt rounds
3. **Role-Based Access Control** - Admin and User roles
4. **Token Expiration** - 24-hour token validity
5. **Passcode Hashing** - Secure card passcode storage
6. **HTTPS Ready** - All endpoints support HTTPS

## Environment Variables

Add to `.env` file:

```
MONGODB_URI=mongodb+srv://user:password@cluster.mongodb.net/tap-and-pay
JWT_SECRET=your-secret-key-change-in-production
```

## Error Responses

### 401 Unauthorized
```json
{
  "error": "Access token required"
}
```

### 403 Forbidden
```json
{
  "error": "Invalid or expired token"
}
```

### 403 Insufficient Permissions
```json
{
  "error": "Insufficient permissions"
}
```

## Testing

### Using cURL

```bash
# Register
curl -X POST http://localhost:8275/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123","role":"admin"}'

# Login with admin
curl -X POST http://localhost:8275/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Login with manager
curl -X POST http://localhost:8275/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"manager","password":"manager123"}'

# Login with user
curl -X POST http://localhost:8275/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"user","password":"user123"}'

# Login with operator
curl -X POST http://localhost:8275/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"operator","password":"operator123"}'

# Get Products (with token)
curl -X GET http://localhost:8275/products \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Next Steps

1. Implement authentication in web frontend
2. Add token refresh mechanism
3. Implement logout functionality
4. Add password reset feature
5. Implement 2FA for admin accounts
6. Add audit logging for all authentication events

