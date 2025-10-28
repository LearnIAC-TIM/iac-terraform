// Sample Node.js Application for Azure Terraform Workshop
// Dette er en enkel Express.js app som kan deployes til App Service

const express = require('express');
const { Client } = require('pg');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Database connection configuration
const getDatabaseConfig = () => {
  // Prøv å hente connection string fra environment variable
  const connString = process.env.DATABASE_CONNECTION_STRING;
  
  if (connString) {
    return { connectionString: connString, ssl: { rejectUnauthorized: false } };
  }
  
  // Fallback til individuelle environment variables
  return {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    ssl: { rejectUnauthorized: false }
  };
};

// Health check endpoint
app.get('/', (req, res) => {
  res.json({
    status: 'healthy',
    message: 'Azure Terraform Workshop - Sample App',
    environment: process.env.ENVIRONMENT || 'development',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Database health check
app.get('/health/db', async (req, res) => {
  const client = new Client(getDatabaseConfig());
  
  try {
    await client.connect();
    const result = await client.query('SELECT NOW() as time, version() as version');
    await client.end();
    
    res.json({
      status: 'healthy',
      database: {
        connected: true,
        time: result.rows[0].time,
        version: result.rows[0].version
      }
    });
  } catch (error) {
    console.error('Database health check failed:', error);
    await client.end().catch(() => {});
    
    res.status(503).json({
      status: 'unhealthy',
      database: {
        connected: false,
        error: error.message
      }
    });
  }
});

// Simple API endpoint - Get all items
app.get('/api/items', async (req, res) => {
  const client = new Client(getDatabaseConfig());
  
  try {
    await client.connect();
    
    // Opprett tabell hvis den ikke eksisterer
    await client.query(`
      CREATE TABLE IF NOT EXISTS items (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    const result = await client.query('SELECT * FROM items ORDER BY created_at DESC');
    await client.end();
    
    res.json({
      success: true,
      count: result.rows.length,
      items: result.rows
    });
  } catch (error) {
    console.error('Error fetching items:', error);
    await client.end().catch(() => {});
    
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Create new item
app.post('/api/items', async (req, res) => {
  const { name, description } = req.body;
  
  if (!name) {
    return res.status(400).json({
      success: false,
      error: 'Name is required'
    });
  }
  
  const client = new Client(getDatabaseConfig());
  
  try {
    await client.connect();
    
    // Opprett tabell hvis den ikke eksisterer
    await client.query(`
      CREATE TABLE IF NOT EXISTS items (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    const result = await client.query(
      'INSERT INTO items (name, description) VALUES ($1, $2) RETURNING *',
      [name, description]
    );
    await client.end();
    
    res.status(201).json({
      success: true,
      item: result.rows[0]
    });
  } catch (error) {
    console.error('Error creating item:', error);
    await client.end().catch(() => {});
    
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Environment info (for debugging)
app.get('/api/info', (req, res) => {
  res.json({
    environment: process.env.ENVIRONMENT,
    nodeVersion: process.version,
    platform: process.platform,
    appInsights: !!process.env.APPLICATIONINSIGHTS_CONNECTION_STRING,
    databaseConfigured: !!(process.env.DATABASE_CONNECTION_STRING || process.env.DB_HOST)
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not found',
    path: req.path
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message
  });
});

// Start server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
  console.log(`Environment: ${process.env.ENVIRONMENT || 'development'}`);
  console.log(`Health check: http://localhost:${port}/`);
  console.log(`Database health: http://localhost:${port}/health/db`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  process.exit(0);
});
