# Tap & Pay - Setup Guide

This guide will help you set up the Tap & Pay system locally.

## Prerequisites

- Node.js v18+ and npm
- MongoDB Atlas account (or local MongoDB)
- Git
- Expo CLI (for mobile app)

## Backend Setup

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Environment Variables

Create a `.env` file in the `backend` directory:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```env
# MongoDB Connection (get from MongoDB Atlas)
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/tap-and-pay

# JWT Secret (generate a strong random string)
JWT_SECRET=your-super-secret-key-min-32-characters

# Server Port
PORT=8275

# MQTT Broker
MQTT_BROKER=mqtt://157.173.101.159:1883

# Team ID
TEAM_ID=nexora_sonia
```

### 3. Start the Backend Server

```bash
npm run start
```

You should see:
```
Connected to MongoDB
✓ Demo admin user created: admin / admin123
✓ Demo manager user created: manager / manager123
✓ Demo user created: user / user123
✓ Demo operator user created: operator / operator123
Backend server running on http://0.0.0.0:8275
```

## Mobile App Setup

### 1. Install Dependencies

```bash
cd my-expo-app
npm install
```

### 2. Configure Environment Variables

Create a `.env` file in the `my-expo-app` directory:

```bash
cp .env.example .env
```

Edit `.env` with your backend URL:

```env
EXPO_PUBLIC_BACKEND_URL=http://your-backend-ip:8275
EXPO_PUBLIC_APP_NAME=Tap & Pay
EXPO_PUBLIC_APP_VERSION=1.0.0
```

### 3. Start the Mobile App

```bash
npm start
```

Then choose:
- `a` for Android
- `i` for iOS
- `w` for Web

## Demo Credentials

### Admin Users
- **Username**: `admin` | **Password**: `admin123`
- **Username**: `manager` | **Password**: `manager123`

### Regular Users
- **Username**: `user` | **Password**: `user123`
- **Username**: `operator` | **Password**: `operator123`

## API Testing

### Test Backend with cURL

```bash
# Login as admin
curl -X POST http://localhost:8275/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Response will include a token
# Use the token for subsequent requests

# Get products
curl -X GET http://localhost:8275/products \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Troubleshooting

### MongoDB Connection Error
- Verify your MongoDB URI in `.env`
- Check that your IP is whitelisted in MongoDB Atlas
- Ensure the database exists

### MQTT Connection Error
- Verify MQTT broker is running
- Check the MQTT_BROKER URL in `.env`
- Ensure network connectivity to the broker

### Backend Port Already in Use
- Change the PORT in `.env`
- Or kill the process using port 8275:
  ```bash
  # Windows
  netstat -ano | findstr :8275
  taskkill /PID <PID> /F
  
  # Linux/Mac
  lsof -i :8275
  kill -9 <PID>
  ```

### Mobile App Can't Connect to Backend
- Verify backend URL in `.env`
- Check that backend is running
- Ensure mobile device is on the same network
- Try using your computer's IP instead of localhost

## Project Structure

```
tap-to-pay-mobile/
├── backend/                 # Node.js/Express server
│   ├── server.js           # Main server file
│   ├── package.json        # Dependencies
│   └── .env                # Environment variables
├── frontend/               # Web dashboard
├── firmware/               # Arduino RFID code
├── mobile-app/             # React Native Expo app
│   ├── src/
│   │   ├── screens/        # App screens
│   │   ├── components/     # Reusable components
│   │   ├── context/        # App state management
│   │   ├── navigation/     # Navigation setup
│   │   └── theme.ts        # UI theme
│   ├── App.tsx             # Entry point
│   └── .env                # Environment variables
└── README.md               # Project documentation
```

## Next Steps

1. Set up MongoDB Atlas database
2. Configure MQTT broker
3. Deploy backend to production server
4. Build and deploy mobile app
5. Set up web frontend
6. Configure Arduino firmware

## Support

For issues or questions, refer to:
- AUTHENTICATION.md - Authentication system details
- README.md - Project overview
- Backend API documentation in code comments
