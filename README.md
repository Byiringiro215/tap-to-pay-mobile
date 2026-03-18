# Tap & Pay — IoT RFID Payment System

Team: **its_ace** | Backend: `http://157.173.101.159:8275` | Frontend: `http://157.173.101.159:9275`

---

## Overview

A full-stack RFID-based tap-to-pay system. An Arduino/ESP8266 reads RFID cards and communicates via MQTT. A Node.js backend handles authentication, wallet management, and transactions stored in PostgreSQL (Neon). A React Native mobile app (Expo) provides the user interface for agents and salespersons.

---

## Project Structure

```
tap-to-pay/
├── backend/
│   ├── server-pg.js          # Main backend (PostgreSQL + MQTT + Socket.IO)
│   ├── server.js             # Legacy MongoDB backend
│   ├── .env                  # DB credentials, JWT secret, MQTT broker
│   └── package.json
├── frontend/
│   ├── index.html            # Web dashboard
│   ├── app.js
│   └── style.css
├── mobile-app/               # React Native (Expo) app
│   ├── App.tsx               # Entry point
│   ├── src/
│   │   ├── screens/
│   │   │   ├── AuthenticationScreen.tsx
│   │   │   ├── RoleSelectionScreen.tsx
│   │   │   ├── DashboardScreen.tsx
│   │   │   ├── TopUpScreen.tsx
│   │   │   ├── MarketplaceScreen.tsx
│   │   │   ├── TransactionsScreen.tsx
│   │   │   └── SettingsScreen.tsx
│   │   ├── context/AppContext.tsx
│   │   ├── navigation/AppNavigation.tsx
│   │   └── components/
│   └── .env                  # EXPO_PUBLIC_BACKEND_URL
└── firmware/
    └── rfid_topup_arduino.ino
```

---

## Quick Start

### Backend
```bash
cd backend
npm install
node server-pg.js
```

### Mobile App
```bash
cd mobile-app
npm install
npx expo start -c
```

Scan the QR code with Expo Go on your device (must be on the same Wi-Fi as the backend machine).

### Frontend (Web)
```bash
cd frontend
npm install
npm start
```

---

## Environment Variables

### `backend/.env`
```env
DB_HOST=ep-cool-term-adrhpv9t-pooler.c-2.us-east-1.aws.neon.tech
DB_PORT=5432
DB_NAME=neondb
DB_USER=neondb_owner
DB_PASSWORD=<password>
DB_SSL=require
JWT_SECRET=your-secret-key
PORT=8275
MQTT_BROKER=mqtt://157.173.101.159:1883
TEAM_ID=its_ace
```

### `mobile-app/.env`
```env
# Physical device / tablet (same Wi-Fi as backend machine)
EXPO_PUBLIC_BACKEND_URL=http://10.12.74.121:8275

# BlueStacks emulator
# EXPO_PUBLIC_BACKEND_URL=http://10.0.2.2:8275
```

---

## User Roles & Flows

### Agent (Admin) — Top-Up
1. Select **Administrator** role → login (`admin / admin123`)
2. Scan RFID card on reader
3. Enter amount → Confirm Top-Up
4. Balance updated in DB and on card via MQTT

### Salesperson (User) — Payment
1. Select **Normal User** role → login (`user / user123`)
2. Scan RFID card
3. Browse marketplace → add to cart
4. Checkout → enter 6-digit passcode
5. Balance deducted, transaction recorded

### Tab Navigation
| Role | Tabs |
|------|------|
| Admin | Top Up → Shop → History → Settings |
| User | Dashboard → Top Up → Shop → History |

---

## API Endpoints

All endpoints (except `/auth/login`, `/auth/register`) require `Authorization: Bearer <token>`.

| Method | Path | Description |
|--------|------|-------------|
| POST | `/auth/login` | Login, returns JWT |
| POST | `/auth/register` | Register user |
| GET | `/products` | Product catalog |
| GET | `/cards` | All cards (admin) |
| GET | `/card/:uid` | Card details |
| POST | `/topup` | Top up card |
| POST | `/pay` | Process payment |
| GET | `/transactions` | All transactions (admin) |
| GET | `/transactions/:uid` | Card transactions |
| POST | `/card/:uid/set-passcode` | Set 6-digit passcode |
| POST | `/card/:uid/change-passcode` | Change passcode |
| GET | `/health` | Health check |

---

## MQTT Topics

Team ID: `its_ace`

| Topic | Direction | Description |
|-------|-----------|-------------|
| `rfid/its_ace/card/status` | Arduino → Backend | Card scanned |
| `rfid/its_ace/card/balance` | Arduino → Backend | Balance update |
| `rfid/its_ace/card/topup` | Backend → Arduino | Top-up command |
| `rfid/its_ace/card/payment` | Backend → Arduino | Payment result |
| `rfid/its_ace/card/removed` | Arduino → Backend | Card removed |

---

## Database Schema (PostgreSQL)

### `users`
| Column | Type |
|--------|------|
| id | SERIAL PK |
| username | VARCHAR UNIQUE |
| password | VARCHAR (bcrypt) |
| role | VARCHAR (admin/user) |
| created_at | TIMESTAMP |

### `cards`
| Column | Type |
|--------|------|
| uid | VARCHAR UNIQUE |
| holder_name | VARCHAR |
| balance | DECIMAL |
| passcode | VARCHAR (bcrypt) |
| passcode_set | BOOLEAN |

### `transactions`
| Column | Type |
|--------|------|
| uid | VARCHAR (FK → cards) |
| type | VARCHAR (topup/debit) |
| amount | DECIMAL |
| balance_before | DECIMAL |
| balance_after | DECIMAL |
| description | TEXT |
| terminal_id | VARCHAR |
| timestamp | TIMESTAMP |

---

## Hardware (ESP8266 + RC522)

| RC522 Pin | ESP8266 (NodeMCU) |
|-----------|-------------------|
| 3.3V | 3V3 |
| GND | GND |
| RST | D3 (GPIO0) |
| MISO | D6 (GPIO12) |
| MOSI | D7 (GPIO13) |
| SCK | D5 (GPIO14) |
| SDA/SS | D4 (GPIO2) |

Arduino libraries required: `MFRC522`, `PubSubClient`, `ArduinoJson`

---

## Demo Credentials

| Username | Password | Role |
|----------|----------|------|
| admin | admin123 | admin |
| manager | manager123 | admin |
| user | user123 | user |
| operator | operator123 | user |

---

## Tech Stack

- **Mobile**: React Native (Expo), TypeScript, NativeWind
- **Backend**: Node.js, Express, Socket.IO, MQTT, JWT, bcrypt
- **Database**: PostgreSQL (Neon cloud)
- **Hardware**: ESP8266, RC522 RFID reader
- **Protocol**: MQTT (broker: 157.173.101.159:1883)
