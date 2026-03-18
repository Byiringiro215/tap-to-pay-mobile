// One-time migration: local PostgreSQL -> Neon
// Run: node migrate-to-neon.js
const { Pool } = require('pg');
require('dotenv').config();

const local = new Pool({
  host: 'localhost', port: 5432, database: 'tap-and-pay',
  user: 'postgres', password: 'postgres', ssl: false,
});

const neon = new Pool({
  host: process.env.DB_HOST, port: process.env.DB_PORT,
  database: process.env.DB_NAME, user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: { rejectUnauthorized: false },
});

async function migrate() {
  console.log('Starting migration to Neon...');

  // Create tables on Neon
  await neon.query(`
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY, username VARCHAR(255) UNIQUE NOT NULL,
      password VARCHAR(255) NOT NULL, role VARCHAR(50) DEFAULT 'user',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`);
  await neon.query(`
    CREATE TABLE IF NOT EXISTS cards (
      id SERIAL PRIMARY KEY, uid VARCHAR(255) UNIQUE NOT NULL,
      holder_name VARCHAR(255) NOT NULL, balance DECIMAL(10,2) DEFAULT 0,
      last_topup DECIMAL(10,2) DEFAULT 0, passcode VARCHAR(255),
      passcode_set BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`);
  await neon.query(`
    CREATE TABLE IF NOT EXISTS transactions (
      id SERIAL PRIMARY KEY, uid VARCHAR(255) NOT NULL,
      holder_name VARCHAR(255) NOT NULL, type VARCHAR(50) NOT NULL,
      amount DECIMAL(10,2) NOT NULL, balance_before DECIMAL(10,2) NOT NULL,
      balance_after DECIMAL(10,2) NOT NULL, description TEXT,
      terminal_id VARCHAR(255) DEFAULT 'its_ace',
      timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (uid) REFERENCES cards(uid)
    )`);
  await neon.query(`ALTER TABLE transactions ADD COLUMN IF NOT EXISTS terminal_id VARCHAR(255) DEFAULT 'its_ace'`);
  console.log('✓ Tables created on Neon');

  // Migrate users
  const users = await local.query('SELECT * FROM users');
  for (const u of users.rows) {
    await neon.query(
      `INSERT INTO users (username, password, role, created_at)
       VALUES ($1, $2, $3, $4) ON CONFLICT (username) DO NOTHING`,
      [u.username, u.password, u.role, u.created_at]
    );
  }
  console.log(`✓ Migrated ${users.rows.length} users`);

  // Migrate cards
  const cards = await local.query('SELECT * FROM cards');
  for (const c of cards.rows) {
    await neon.query(
      `INSERT INTO cards (uid, holder_name, balance, last_topup, passcode, passcode_set, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) ON CONFLICT (uid) DO UPDATE
       SET balance = EXCLUDED.balance, holder_name = EXCLUDED.holder_name`,
      [c.uid, c.holder_name, c.balance, c.last_topup, c.passcode, c.passcode_set, c.created_at, c.updated_at]
    );
  }
  console.log(`✓ Migrated ${cards.rows.length} cards`);

  // Migrate transactions
  const txs = await local.query('SELECT * FROM transactions ORDER BY timestamp ASC');
  for (const t of txs.rows) {
    await neon.query(
      `INSERT INTO transactions (uid, holder_name, type, amount, balance_before, balance_after, description, terminal_id, timestamp)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) ON CONFLICT DO NOTHING`,
      [t.uid, t.holder_name, t.type, t.amount, t.balance_before, t.balance_after, t.description, t.terminal_id || 'its_ace', t.timestamp]
    );
  }
  console.log(`✓ Migrated ${txs.rows.length} transactions`);

  await local.end();
  await neon.end();
  console.log('Migration complete.');
}

migrate().catch(err => { console.error('Migration failed:', err.message); process.exit(1); });
