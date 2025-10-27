const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

const slotName = process.env.SLOT_NAME || 'unknown';
const featureToggle = process.env.FEATURE_TOGGLE_NEW_UI === 'true';

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    slot: slotName
  });
});

app.get('/', (req, res) => {
  const version = featureToggle ? 'v2' : 'v1';
  const bgColor = featureToggle ? '#4CAF50' : '#2196F3';
  
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Azure Web App Lab</title>
      <style>
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          background: linear-gradient(135deg, ${bgColor} 0%, #1976D2 100%);
          color: white;
          display: flex;
          justify-content: center;
          align-items: center;
          height: 100vh;
          margin: 0;
        }
        .container {
          text-align: center;
          background: rgba(255, 255, 255, 0.1);
          padding: 50px;
          border-radius: 20px;
        }
        h1 { font-size: 3em; }
        .slot { font-size: 1.5em; margin: 20px 0; }
        .version { 
          font-size: 2em; 
          background: rgba(255, 255, 255, 0.2);
          padding: 20px;
          border-radius: 10px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🚀 Azure Web App Lab</h1>
        <div class="slot">Slot: <strong>${slotName.toUpperCase()}</strong></div>
        <div class="version">Version: ${version}</div>
        <div style="margin-top: 30px;">
          ${featureToggle ? '✨ <strong>NY UI AKTIVERT!</strong> ✨' : '📘 Standard UI'}
        </div>
        <p style="margin-top: 30px; opacity: 0.8;">
          ${new Date().toISOString()}
        </p>
      </div>
    </body>
    </html>
  `);
});

app.get('/api/info', (req, res) => {
  res.json({
    slot: slotName,
    featureToggle: featureToggle,
    version: featureToggle ? 'v2' : 'v1',
    timestamp: new Date().toISOString()
  });
});

app.listen(port, () => {
  console.log(`✅ Server kjører på port ${port}`);
  console.log(`📍 Slot: ${slotName}`);
  console.log(`🎚️  Feature Toggle: ${featureToggle}`);
});
