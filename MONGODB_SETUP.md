# MongoDB Setup Guide

## Option 1: Local MongoDB (Recommended for Development)

### Windows

1. **Download MongoDB Community Edition**
   - Visit: https://www.mongodb.com/try/download/community
   - Select Windows and download the MSI installer

2. **Install MongoDB**
   - Run the installer
   - Choose "Install MongoDB as a Service"
   - Default installation path: `C:\Program Files\MongoDB\Server\7.0`

3. **Start MongoDB Service**
   ```bash
   # MongoDB should start automatically as a service
   # Or manually start it:
   net start MongoDB
   ```

4. **Verify Installation**
   ```bash
   mongosh
   # You should see the MongoDB shell prompt
   ```

5. **Update .env file**
   ```env
   MONGODB_URI=mongodb://localhost:27017/tap-and-pay
   ```

6. **Restart Backend**
   ```bash
   npm run start
   ```

### macOS

1. **Install via Homebrew**
   ```bash
   brew tap mongodb/brew
   brew install mongodb-community
   ```

2. **Start MongoDB**
   ```bash
   brew services start mongodb-community
   ```

3. **Verify Installation**
   ```bash
   mongosh
   ```

4. **Update .env file**
   ```env
   MONGODB_URI=mongodb://localhost:27017/tap-and-pay
   ```

### Linux (Ubuntu/Debian)

1. **Install MongoDB**
   ```bash
   sudo apt-get update
   sudo apt-get install -y mongodb
   ```

2. **Start MongoDB**
   ```bash
   sudo systemctl start mongodb
   sudo systemctl enable mongodb
   ```

3. **Verify Installation**
   ```bash
   mongosh
   ```

4. **Update .env file**
   ```env
   MONGODB_URI=mongodb://localhost:27017/tap-and-pay
   ```

## Option 2: MongoDB Atlas (Cloud - Recommended for Production)

### Setup Steps

1. **Create MongoDB Atlas Account**
   - Visit: https://www.mongodb.com/cloud/atlas
   - Sign up for a free account

2. **Create a Cluster**
   - Click "Create a Deployment"
   - Choose "M0 Shared" (free tier)
   - Select your region
   - Click "Create Deployment"

3. **Create Database User**
   - Go to "Database Access"
   - Click "Add New Database User"
   - Create username and password
   - Click "Add User"

4. **Whitelist IP Address**
   - Go to "Network Access"
   - Click "Add IP Address"
   - For development: Add `0.0.0.0/0` (allows all IPs)
   - For production: Add your server's IP only

5. **Get Connection String**
   - Go to "Databases"
   - Click "Connect" on your cluster
   - Choose "Drivers"
   - Copy the connection string
   - Replace `<password>` with your database user password

6. **Update .env file**
   ```env
   MONGODB_URI=mongodb+srv://username:password@cluster-name.mongodb.net/tap-and-pay
   ```

7. **Restart Backend**
   ```bash
   npm run start
   ```

## Verify Connection

Once MongoDB is running and backend is started, you should see:

```
Connected to MongoDB
✓ Demo admin user created: admin / admin123
✓ Demo manager user created: manager / manager123
✓ Demo user created: user / user123
✓ Demo operator user created: operator / operator123
Backend server running on http://0.0.0.0:8275
```

## Troubleshooting

### Connection Refused
- Ensure MongoDB is running
- Check if port 27017 is available
- Verify MONGODB_URI in .env

### Authentication Failed
- Verify username and password in connection string
- Check IP whitelist in MongoDB Atlas
- Ensure database user has correct permissions

### Timeout Error
- Check network connectivity
- Verify MongoDB Atlas IP whitelist includes your IP
- Try increasing connection timeout in .env

## Database Management

### Using MongoDB Compass (GUI)

1. Download: https://www.mongodb.com/products/compass
2. Connect with your MongoDB URI
3. Browse collections and documents visually

### Using mongosh (CLI)

```bash
# Connect to local MongoDB
mongosh

# Connect to MongoDB Atlas
mongosh "mongodb+srv://username:password@cluster.mongodb.net/tap-and-pay"

# List databases
show databases

# Use a database
use tap-and-pay

# List collections
show collections

# View users
db.users.find()

# View cards
db.cards.find()

# View transactions
db.transactions.find()
```

## Backup and Restore

### Backup Local MongoDB
```bash
mongodump --db tap-and-pay --out ./backup
```

### Restore Local MongoDB
```bash
mongorestore --db tap-and-pay ./backup/tap-and-pay
```

## Next Steps

1. Set up MongoDB (local or Atlas)
2. Update .env with correct MONGODB_URI
3. Restart backend server
4. Verify demo users are created
5. Test API endpoints
