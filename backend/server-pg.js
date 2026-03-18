const express = require('express');
const mqtt = require('mqtt');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

app.use(cors());
app.use(express.json());

// Request timeout middleware (30 seconds)
app.use((req, res, next) => {
  req.setTimeout(30000);
  res.setTimeout(30000);
  
  // Log requests
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path} - ${res.statusCode} (${duration}ms)`);
  });
  
  next();
});

const PORT = process.env.PORT || 8275;
const TEAM_ID = process.env.TEAM_ID || "its_ace";
const MQTT_BROKER = process.env.MQTT_BROKER || "mqtt://157.173.101.159:1883";
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// PostgreSQL Connection Pool - Optimized for Neon
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'tap_and_pay',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'password',
  ssl: process.env.DB_SSL === 'require' ? { rejectUnauthorized: false } : false,
  // Connection pool optimization
  max: 20,                    // Maximum connections
  idleTimeoutMillis: 30000,   // Close idle connections after 30s
  connectionTimeoutMillis: 30000, // Connection timeout 30s (increased for Neon)
  statement_timeout: 30000,   // Query timeout 30s (increased for Neon)
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
});

// Initialize Database Tables
async function initializeDatabase() {
  try {
    // Users table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        role VARCHAR(50) DEFAULT 'user',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Cards table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS cards (
        id SERIAL PRIMARY KEY,
        uid VARCHAR(255) UNIQUE NOT NULL,
        holder_name VARCHAR(255) NOT NULL,
        balance DECIMAL(10, 2) DEFAULT 0,
        last_topup DECIMAL(10, 2) DEFAULT 0,
        passcode VARCHAR(255),
        passcode_set BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Transactions table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS transactions (
        id SERIAL PRIMARY KEY,
        uid VARCHAR(255) NOT NULL,
        holder_name VARCHAR(255) NOT NULL,
        type VARCHAR(50) NOT NULL,
        amount DECIMAL(10, 2) NOT NULL,
        balance_before DECIMAL(10, 2) NOT NULL,
        balance_after DECIMAL(10, 2) NOT NULL,
        description TEXT,
        terminal_id VARCHAR(255) DEFAULT 'its_ace',
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (uid) REFERENCES cards(uid)
      )
    `);

    // Add terminal_id column if it doesn't exist (for existing DBs)
    await pool.query(`
      ALTER TABLE transactions ADD COLUMN IF NOT EXISTS terminal_id VARCHAR(255) DEFAULT 'its_ace'
    `);

    console.log('✓ Database tables initialized');
  } catch (err) {
    console.error('Error initializing database:', err.message);
  }
}

// Initialize demo users
async function initializeDemoUsers() {
  try {
    const demoUsers = [
      { username: 'admin', password: 'admin123', role: 'admin' },
      { username: 'manager', password: 'manager123', role: 'admin' },
      { username: 'user', password: 'user123', role: 'user' },
      { username: 'operator', password: 'operator123', role: 'user' }
    ];

    for (const demoUser of demoUsers) {
      const result = await pool.query('SELECT * FROM users WHERE username = $1', [demoUser.username]);
      
      if (result.rows.length === 0) {
        const hashedPassword = await bcrypt.hash(demoUser.password, 10);
        await pool.query(
          'INSERT INTO users (username, password, role) VALUES ($1, $2, $3)',
          [demoUser.username, hashedPassword, demoUser.role]
        );
        console.log(`✓ Demo user created: ${demoUser.username} / ${demoUser.password}`);
      } else {
        console.log(`✓ Demo user already exists: ${demoUser.username}`);
      }
    }
  } catch (err) {
    console.error('Error initializing demo users:', err.message);
  }
}

// Authentication Middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
};

// Role-based Authorization Middleware
const authorizeRole = (allowedRoles) => {
  return (req, res, next) => {
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }
    next();
  };
};

// Passcode helper functions
async function hashPasscode(passcode) {
  const saltRounds = 10;
  return await bcrypt.hash(passcode, saltRounds);
}

async function verifyPasscode(inputPasscode, hashedPasscode) {
  return await bcrypt.compare(inputPasscode, hashedPasscode);
}

// Product catalog
const PRODUCTS = [
  // Food & Beverages
  { id: 'coffee', name: 'Coffee', price: 2.50, icon: '☕', category: 'food' },
  { id: 'sandwich', name: 'Sandwich', price: 5.00, icon: '🥪', category: 'food' },
  { id: 'water', name: 'Water Bottle', price: 1.00, icon: '💧', category: 'food' },
  { id: 'snack', name: 'Snack Pack', price: 3.00, icon: '🍿', category: 'food' },
  { id: 'juice', name: 'Fresh Juice', price: 3.50, icon: '🧃', category: 'food' },
  { id: 'salad', name: 'Salad Bowl', price: 6.00, icon: '🥗', category: 'food' },
  
  // Rwandan Local Foods
  { id: 'brochette', name: 'Brochette', price: 4.00, icon: '串', category: 'rwandan' },
  { id: 'isombe', name: 'Isombe', price: 3.50, icon: '🥬', category: 'rwandan' },
  { id: 'ubugari', name: 'Ubugari', price: 2.00, icon: '🍚', category: 'rwandan' },
  { id: 'sambaza', name: 'Sambaza (Fried)', price: 3.00, icon: '🐟', category: 'rwandan' },
  { id: 'akabenzi', name: 'Akabenzi (Pork)', price: 5.50, icon: '🥓', category: 'rwandan' },
  { id: 'ikivuguto', name: 'Ikivuguto (Yogurt)', price: 1.50, icon: '🥛', category: 'rwandan' },
  { id: 'agatogo', name: 'Agatogo', price: 4.50, icon: '🍲', category: 'rwandan' },
  { id: 'urwagwa', name: 'Urwagwa (Banana Beer)', price: 2.50, icon: '🍺', category: 'rwandan' },
  
  // Snacks & Drinks
  { id: 'fanta', name: 'Fanta', price: 1.20, icon: '🥤', category: 'drinks' },
  { id: 'primus', name: 'Primus Beer', price: 2.00, icon: '🍺', category: 'drinks' },
  { id: 'mutzig', name: 'Mutzig Beer', price: 2.00, icon: '🍺', category: 'drinks' },
  { id: 'inyange-juice', name: 'Inyange Juice', price: 1.50, icon: '🧃', category: 'drinks' },
  { id: 'chips', name: 'Chips', price: 2.50, icon: '🍟', category: 'food' },
  
  // Domain Registration Services
  { id: 'domain-com', name: '.com Domain', price: 12.00, icon: '🌐', category: 'domains' },
  { id: 'domain-net', name: '.net Domain', price: 11.00, icon: '🌐', category: 'domains' },
  { id: 'domain-org', name: '.org Domain', price: 10.00, icon: '🌐', category: 'domains' },
  { id: 'domain-io', name: '.io Domain', price: 35.00, icon: '🌐', category: 'domains' },
  { id: 'domain-dev', name: '.dev Domain', price: 15.00, icon: '🌐', category: 'domains' },
  { id: 'domain-app', name: '.app Domain', price: 18.00, icon: '🌐', category: 'domains' },
  { id: 'domain-ai', name: '.ai Domain', price: 80.00, icon: '🤖', category: 'domains' },
  { id: 'domain-xyz', name: '.xyz Domain', price: 8.00, icon: '🌐', category: 'domains' },
  { id: 'domain-co', name: '.co Domain', price: 25.00, icon: '🌐', category: 'domains' },
  { id: 'domain-rw', name: '.rw Domain', price: 20.00, icon: '🇷🇼', category: 'domains' },
  
  // Digital Services
  { id: 'hosting-basic', name: 'Basic Hosting (1mo)', price: 5.00, icon: '☁️', category: 'services' },
  { id: 'hosting-pro', name: 'Pro Hosting (1mo)', price: 15.00, icon: '☁️', category: 'services' },
  { id: 'ssl-cert', name: 'SSL Certificate', price: 10.00, icon: '🔒', category: 'services' },
  { id: 'email-pro', name: 'Professional Email', price: 8.00, icon: '📧', category: 'services' }
];

// MQTT Topics
const TOPIC_STATUS = `rfid/${TEAM_ID}/card/status`;
const TOPIC_BALANCE = `rfid/${TEAM_ID}/card/balance`;
const TOPIC_TOPUP = `rfid/${TEAM_ID}/card/topup`;
const TOPIC_PAYMENT = `rfid/${TEAM_ID}/card/payment`;
const TOPIC_REMOVED = `rfid/${TEAM_ID}/card/removed`;

// MQTT Client Setup
const mqttClient = mqtt.connect(MQTT_BROKER);

mqttClient.on('connect', () => {
  console.log('✓ Connected to MQTT Broker');
  mqttClient.subscribe(TOPIC_STATUS);
  mqttClient.subscribe(TOPIC_BALANCE);
  mqttClient.subscribe(TOPIC_PAYMENT);
  mqttClient.subscribe(TOPIC_REMOVED);
});

mqttClient.on('message', (topic, message) => {
  console.log(`Received message on ${topic}: ${message.toString()}`);
  try {
    const payload = JSON.parse(message.toString());

    if (topic === TOPIC_STATUS) {
      io.emit('card-status', payload);
    } else if (topic === TOPIC_BALANCE) {
      io.emit('card-balance', payload);
    } else if (topic === TOPIC_PAYMENT) {
      io.emit('payment-result', payload);
    } else if (topic === TOPIC_REMOVED) {
      io.emit('card-removed', payload);
    }
  } catch (err) {
    console.error('Failed to parse MQTT message:', err);
  }
});

// Health Check Endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Authentication Endpoints
app.post('/auth/register', async (req, res) => {
  const { username, password, role } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required' });
  }

  try {
    const result = await pool.query('SELECT * FROM users WHERE username = $1', [username]);
    if (result.rows.length > 0) {
      return res.status(400).json({ error: 'Username already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = await pool.query(
      'INSERT INTO users (username, password, role) VALUES ($1, $2, $3) RETURNING id, username, role',
      [username, hashedPassword, role || 'user']
    );

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      user: {
        id: newUser.rows[0].id,
        username: newUser.rows[0].username,
        role: newUser.rows[0].role
      }
    });
  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ error: 'Registration failed' });
  }
});

// Seed demo users endpoint
app.post('/auth/seed', async (req, res) => {
  try {
    await initializeDemoUsers();
    
    const result = await pool.query('SELECT id, username, role FROM users');
    res.json({
      success: true,
      message: 'Demo users seeded successfully',
      users: result.rows
    });
  } catch (err) {
    console.error('Seed error:', err);
    res.status(500).json({ error: 'Seeding failed' });
  }
});

// Debug endpoint to check users
app.get('/auth/users', async (req, res) => {
  try {
    const result = await pool.query('SELECT id, username, role FROM users');
    res.json({
      success: true,
      count: result.rows.length,
      users: result.rows
    });
  } catch (err) {
    console.error('Error fetching users:', err);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

app.post('/auth/login', async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password are required' });
  }

  try {
    // Set query timeout
    const client = await pool.connect();
    try {
      // Use a faster query with timeout
      const result = await client.query('SELECT id, username, password, role FROM users WHERE username = $1 LIMIT 1', [username]);
      
      if (result.rows.length === 0) {
        return res.status(401).json({ error: 'Invalid username or password' });
      }

      const user = result.rows[0];
      const isPasswordValid = await bcrypt.compare(password, user.password);
      if (!isPasswordValid) {
        return res.status(401).json({ error: 'Invalid username or password' });
      }

      const token = jwt.sign(
        { id: user.id, username: user.username, role: user.role },
        JWT_SECRET,
        { expiresIn: '24h' }
      );

      res.json({
        success: true,
        message: 'Login successful',
        token,
        user: {
          id: user.id,
          username: user.username,
          role: user.role
        }
      });
    } finally {
      client.release();
    }
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Login failed' });
  }
});

// Protected Endpoints
app.post('/topup', authenticateToken, authorizeRole(['admin', 'user']), async (req, res) => {
  const { uid, amount, holderName, passcode } = req.body;

  if (!uid || amount === undefined) {
    return res.status(400).json({ error: 'UID and amount are required' });
  }

  try {
    let card = await pool.query('SELECT * FROM cards WHERE uid = $1', [uid]);
    const balanceBefore = card.rows.length > 0 ? parseFloat(card.rows[0].balance) : 0;

    if (card.rows.length === 0) {
      if (!holderName) {
        return res.status(400).json({ error: 'Holder name is required for new cards' });
      }
      
      if (!passcode || !/^\d{6}$/.test(passcode)) {
        return res.status(400).json({ error: 'A 6-digit passcode is required for new cards' });
      }
      
      const hashedPasscode = await hashPasscode(passcode);
      
      card = await pool.query(
        'INSERT INTO cards (uid, holder_name, balance, last_topup, passcode, passcode_set) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
        [uid, holderName, amount, amount, hashedPasscode, true]
      );
    } else {
      card = await pool.query(
        'UPDATE cards SET balance = balance + $1, last_topup = $2, updated_at = CURRENT_TIMESTAMP WHERE uid = $3 RETURNING *',
        [amount, amount, uid]
      );
    }

    const cardData = card.rows[0];

    // Create transaction record
    await pool.query(
      'INSERT INTO transactions (uid, holder_name, type, amount, balance_before, balance_after, description, terminal_id) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
      [uid, cardData.holder_name, 'topup', amount, balanceBefore, parseFloat(cardData.balance), `Top-up of ${amount.toFixed(2)}`, TEAM_ID]
    );

    // Publish to MQTT
    const payload = JSON.stringify({ uid, amount: parseFloat(cardData.balance) });
    mqttClient.publish(TOPIC_TOPUP, payload, (err) => {
      if (err) {
        console.error('Failed to publish topup:', err);
      }
    });

    res.json({
      success: true,
      message: 'Topup successful',
      card: {
        uid: cardData.uid,
        holderName: cardData.holder_name,
        balance: parseFloat(cardData.balance),
        lastTopup: parseFloat(cardData.last_topup)
      }
    });
  } catch (err) {
    console.error('Topup error:', err);
    res.status(500).json({ error: 'Topup failed' });
  }
});

app.post('/pay', authenticateToken, authorizeRole(['admin', 'user']), async (req, res) => {
  const { uid, productId, amount, description, passcode } = req.body;

  if (!uid || (!productId && amount === undefined)) {
    return res.status(400).json({ error: 'UID and product or amount are required' });
  }

  try {
    const cardResult = await pool.query('SELECT * FROM cards WHERE uid = $1', [uid]);
    if (cardResult.rows.length === 0) {
      return res.status(404).json({ error: 'Card not found. Please top up first.' });
    }
    
    const card = cardResult.rows[0];
    
    if (card.passcode_set) {
      if (!passcode) {
        return res.status(401).json({ 
          error: 'Passcode required for this card',
          passcodeRequired: true
        });
      }
      
      const isValid = await verifyPasscode(passcode, card.passcode);
      if (!isValid) {
        return res.status(401).json({ 
          error: 'Incorrect passcode',
          passcodeRequired: true
        });
      }
    }
    
    let payAmount = amount;
    let payDescription = description || 'Payment';

    if (productId) {
      const product = PRODUCTS.find(p => p.id === productId);
      if (!product) {
        return res.status(400).json({ error: 'Invalid product ID' });
      }
      payAmount = product.price;
      payDescription = `Purchase: ${product.name}`;
    }

    if (!payAmount || payAmount <= 0) {
      return res.status(400).json({ error: 'Invalid payment amount' });
    }

    if (parseFloat(card.balance) < payAmount) {
      return res.status(400).json({
        error: 'Insufficient balance',
        currentBalance: parseFloat(card.balance),
        required: payAmount,
        shortfall: payAmount - parseFloat(card.balance)
      });
    }

    const balanceBefore = parseFloat(card.balance);

    const updatedCard = await pool.query(
      'UPDATE cards SET balance = balance - $1, updated_at = CURRENT_TIMESTAMP WHERE uid = $2 RETURNING *',
      [payAmount, uid]
    );

    const cardData = updatedCard.rows[0];

    await pool.query(
      'INSERT INTO transactions (uid, holder_name, type, amount, balance_before, balance_after, description, terminal_id) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
      [uid, cardData.holder_name, 'debit', payAmount, balanceBefore, parseFloat(cardData.balance), payDescription, TEAM_ID]
    );

    const payload = JSON.stringify({
      uid,
      amount: parseFloat(cardData.balance),
      deducted: payAmount,
      description: payDescription,
      status: 'success'
    });
    mqttClient.publish(TOPIC_PAYMENT, payload);

    io.emit('payment-success', {
      uid: cardData.uid,
      holderName: cardData.holder_name,
      amount: payAmount,
      balanceBefore,
      balanceAfter: parseFloat(cardData.balance),
      description: payDescription
    });

    res.json({
      success: true,
      message: 'Payment successful',
      transaction: {
        amount: payAmount,
        description: payDescription,
        balanceBefore,
        balanceAfter: parseFloat(cardData.balance),
        terminalId: TEAM_ID,
      },
      card: {
        uid: cardData.uid,
        holderName: cardData.holder_name,
        balance: parseFloat(cardData.balance)
      }
    });
  } catch (err) {
    console.error('Payment error:', err);
    res.status(500).json({ error: 'Payment processing failed' });
  }
});

app.get('/products', authenticateToken, (req, res) => {
  res.json(PRODUCTS);
});

app.get('/card/:uid', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM cards WHERE uid = $1', [req.params.uid]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Card not found' });
    }
    const card = result.rows[0];
    res.json({
      uid: card.uid,
      holderName: card.holder_name,
      balance: parseFloat(card.balance),
      passcodeSet: card.passcode_set
    });
  } catch (err) {
    console.error('Database error:', err);
    res.status(500).json({ error: 'Database operation failed' });
  }
});

app.get('/cards', authenticateToken, authorizeRole(['admin']), async (req, res) => {
  try {
    const result = await pool.query('SELECT uid, holder_name, balance, passcode_set, updated_at FROM cards ORDER BY updated_at DESC');
    const cards = result.rows.map(card => ({
      uid: card.uid,
      holderName: card.holder_name,
      balance: parseFloat(card.balance),
      passcodeSet: card.passcode_set,
      updatedAt: card.updated_at
    }));
    res.json(cards);
  } catch (err) {
    console.error('Database error:', err);
    res.status(500).json({ error: 'Database operation failed' });
  }
});

app.get('/transactions/:uid', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM transactions WHERE uid = $1 ORDER BY timestamp DESC LIMIT 50',
      [req.params.uid]
    );
    const transactions = result.rows.map(tx => ({
      _id: tx.id,
      uid: tx.uid,
      holderName: tx.holder_name,
      type: tx.type,
      amount: parseFloat(tx.amount),
      balanceAfter: parseFloat(tx.balance_after),
      description: tx.description,
      terminalId: tx.terminal_id,
      timestamp: tx.timestamp
    }));
    res.json(transactions);
  } catch (err) {
    console.error('Database error:', err);
    res.status(500).json({ error: 'Database operation failed' });
  }
});

app.get('/transactions', authenticateToken, authorizeRole(['admin']), async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 100;
    const result = await pool.query(
      'SELECT * FROM transactions ORDER BY timestamp DESC LIMIT $1',
      [limit]
    );
    const transactions = result.rows.map(tx => ({
      _id: tx.id,
      uid: tx.uid,
      holderName: tx.holder_name,
      type: tx.type,
      amount: parseFloat(tx.amount),
      balanceAfter: parseFloat(tx.balance_after),
      description: tx.description,
      terminalId: tx.terminal_id,
      timestamp: tx.timestamp
    }));
    res.json(transactions);
  } catch (err) {
    console.error('Database error:', err);
    res.status(500).json({ error: 'Database operation failed' });
  }
});

app.post('/card/:uid/set-passcode', authenticateToken, async (req, res) => {
  const { passcode } = req.body;
  
  if (!passcode || !/^\d{6}$/.test(passcode)) {
    return res.status(400).json({ error: 'Passcode must be exactly 6 digits' });
  }
  
  try {
    const result = await pool.query('SELECT * FROM cards WHERE uid = $1', [req.params.uid]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Card not found' });
    }
    
    const card = result.rows[0];
    if (card.passcode_set) {
      return res.status(400).json({ error: 'Passcode already set. Use change-passcode endpoint to update.' });
    }
    
    const hashedPasscode = await hashPasscode(passcode);
    await pool.query(
      'UPDATE cards SET passcode = $1, passcode_set = true, updated_at = CURRENT_TIMESTAMP WHERE uid = $2',
      [hashedPasscode, req.params.uid]
    );
    
    res.json({ 
      success: true, 
      message: 'Passcode set successfully',
      passcodeSet: true
    });
  } catch (err) {
    console.error('Set passcode error:', err);
    res.status(500).json({ error: 'Failed to set passcode' });
  }
});

app.post('/card/:uid/change-passcode', authenticateToken, async (req, res) => {
  const { oldPasscode, newPasscode } = req.body;
  
  if (!oldPasscode || !newPasscode) {
    return res.status(400).json({ error: 'Both old and new passcodes are required' });
  }
  
  if (!/^\d{6}$/.test(newPasscode)) {
    return res.status(400).json({ error: 'New passcode must be exactly 6 digits' });
  }
  
  try {
    const result = await pool.query('SELECT * FROM cards WHERE uid = $1', [req.params.uid]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Card not found' });
    }
    
    const card = result.rows[0];
    if (!card.passcode_set) {
      return res.status(400).json({ error: 'No passcode set. Use set-passcode endpoint first.' });
    }
    
    const isValid = await verifyPasscode(oldPasscode, card.passcode);
    if (!isValid) {
      return res.status(401).json({ error: 'Incorrect old passcode' });
    }
    
    const hashedPasscode = await hashPasscode(newPasscode);
    await pool.query(
      'UPDATE cards SET passcode = $1, updated_at = CURRENT_TIMESTAMP WHERE uid = $2',
      [hashedPasscode, req.params.uid]
    );
    
    res.json({ 
      success: true, 
      message: 'Passcode changed successfully'
    });
  } catch (err) {
    console.error('Change passcode error:', err);
    res.status(500).json({ error: 'Failed to change passcode' });
  }
});

app.post('/card/:uid/verify-passcode', authenticateToken, async (req, res) => {
  const { passcode } = req.body;
  
  if (!passcode || !/^\d{6}$/.test(passcode)) {
    return res.status(400).json({ error: 'Passcode must be exactly 6 digits', valid: false });
  }
  
  try {
    const result = await pool.query('SELECT * FROM cards WHERE uid = $1', [req.params.uid]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Card not found', valid: false });
    }
    
    const card = result.rows[0];
    if (!card.passcode_set) {
      return res.status(400).json({ error: 'No passcode set for this card', valid: false });
    }
    
    const isValid = await verifyPasscode(passcode, card.passcode);
    
    if (isValid) {
      res.json({ 
        success: true, 
        valid: true,
        message: 'Passcode verified'
      });
    } else {
      res.status(401).json({ 
        error: 'Incorrect passcode', 
        valid: false 
      });
    }
  } catch (err) {
    console.error('Verify passcode error:', err);
    res.status(500).json({ error: 'Failed to verify passcode', valid: false });
  }
});

// Socket connectivity
io.on('connection', (socket) => {
  console.log('User connected to the dashboard');
  socket.on('disconnect', () => {
    console.log('User disconnected');
  });
});

// Start server
server.listen(PORT, '0.0.0.0', async () => {
  console.log(`Backend server running on http://0.0.0.0:${PORT}`);
  console.log(`Access from: http://157.173.101.159:${PORT}`);
  
  // Initialize database and demo users
  await initializeDatabase();
  await initializeDemoUsers();
});
