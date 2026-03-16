# PostgreSQL Setup Guide

This guide will help you set up PostgreSQL for the Tap & Pay backend.

## Installation

### Windows

1. **Download PostgreSQL**
   - Visit: https://www.postgresql.org/download/windows/
   - Download the latest version (14 or higher)

2. **Run Installer**
   - Execute the downloaded installer
   - Follow the installation wizard
   - Remember the password you set for the `postgres` user
   - Default port: 5432

3. **Verify Installation**
   ```bash
   psql --version
   ```

### macOS

1. **Install via Homebrew**
   ```bash
   brew install postgresql@15
   brew services start postgresql@15
   ```

2. **Verify Installation**
   ```bash
   psql --version
   ```

### Linux (Ubuntu/Debian)

1. **Install PostgreSQL**
   ```bash
   sudo apt-get update
   sudo apt-get install postgresql postgresql-contrib
   ```

2. **Start PostgreSQL**
   ```bash
   sudo systemctl start postgresql
   sudo systemctl enable postgresql
   ```

3. **Verify Installation**
   ```bash
   psql --version
   ```

## Create Database and User

### Using psql Command Line

1. **Connect to PostgreSQL**
   ```bash
   psql -U postgres
   ```

2. **Create Database**
   ```sql
   CREATE DATABASE tap_and_pay;
   ```

3. **Create User (Optional)**
   ```sql
   CREATE USER tap_user WITH PASSWORD 'secure_password';
   GRANT ALL PRIVILEGES ON DATABASE tap_and_pay TO tap_user;
   ```

4. **Exit psql**
   ```sql
   \q
   ```

### Using pgAdmin (GUI)

1. **Download pgAdmin**
   - Visit: https://www.pgadmin.org/download/
   - Install for your operating system

2. **Open pgAdmin**
   - Default URL: http://localhost:5050
   - Login with your credentials

3. **Create Database**
   - Right-click "Databases"
   - Select "Create" → "Database"
   - Name: `tap_and_pay`
   - Click "Save"

## Configure Backend

### Update .env File

Edit `Tap_and_Pay/backend/.env`:

```env
# PostgreSQL Connection
DB_HOST=localhost
DB_PORT=5432
DB_NAME=tap_and_pay
DB_USER=postgres
DB_PASSWORD=your_postgres_password

# JWT Secret
JWT_SECRET=your-secret-key-change-in-production-12345

# Server Port
PORT=8275

# MQTT Broker
MQTT_BROKER=mqtt://157.173.101.159:1883

# Team ID
TEAM_ID=nexora_sonia
```

### Alternative: Using Connection String

```env
DATABASE_URL=postgresql://postgres:password@localhost:5432/tap_and_pay
```

## Start Backend

```bash
cd Tap_and_Pay/backend
npm install
npm run start
```

You should see:
```
✓ Database tables initialized
✓ Demo user created: admin / admin123
✓ Demo manager user created: manager / manager123
✓ Demo user created: user / user123
✓ Demo operator user created: operator / operator123
✓ Connected to MQTT Broker
Backend server running on http://0.0.0.0:8275
```

## Database Management

### Using psql

```bash
# Connect to database
psql -U postgres -d tap_and_pay

# List tables
\dt

# View users table
SELECT * FROM users;

# View cards table
SELECT * FROM cards;

# View transactions table
SELECT * FROM transactions;

# Exit
\q
```

### Using pgAdmin

1. Open pgAdmin
2. Navigate to: Servers → PostgreSQL → Databases → tap_and_pay
3. Right-click and select "Query Tool"
4. Write and execute SQL queries

## Backup and Restore

### Backup Database

```bash
pg_dump -U postgres tap_and_pay > backup.sql
```

### Restore Database

```bash
psql -U postgres tap_and_pay < backup.sql
```

## Troubleshooting

### Connection Refused
- Ensure PostgreSQL is running
- Check if port 5432 is available
- Verify credentials in .env

### Authentication Failed
- Verify username and password
- Check user permissions
- Ensure user has access to database

### Database Does Not Exist
- Create database using psql or pgAdmin
- Verify database name in .env

### Tables Not Created
- Check backend logs for errors
- Manually create tables using SQL scripts
- Verify database user has CREATE privileges

## SQL Scripts

### Create All Tables Manually

```sql
-- Users table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'user',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Cards table
CREATE TABLE cards (
  id SERIAL PRIMARY KEY,
  uid VARCHAR(255) UNIQUE NOT NULL,
  holder_name VARCHAR(255) NOT NULL,
  balance DECIMAL(10, 2) DEFAULT 0,
  last_topup DECIMAL(10, 2) DEFAULT 0,
  passcode VARCHAR(255),
  passcode_set BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transactions table
CREATE TABLE transactions (
  id SERIAL PRIMARY KEY,
  uid VARCHAR(255) NOT NULL,
  holder_name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  balance_before DECIMAL(10, 2) NOT NULL,
  balance_after DECIMAL(10, 2) NOT NULL,
  description TEXT,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (uid) REFERENCES cards(uid)
);

-- Create indexes for better performance
CREATE INDEX idx_cards_uid ON cards(uid);
CREATE INDEX idx_transactions_uid ON transactions(uid);
CREATE INDEX idx_transactions_timestamp ON transactions(timestamp);
```

## Next Steps

1. Install PostgreSQL
2. Create database and user
3. Update .env file
4. Start backend server
5. Test API endpoints
6. Deploy to production

## Support

For PostgreSQL documentation: https://www.postgresql.org/docs/
For pgAdmin documentation: https://www.pgadmin.org/docs/
