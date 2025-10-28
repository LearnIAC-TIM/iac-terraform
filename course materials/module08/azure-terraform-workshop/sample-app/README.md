# Sample Application

En enkel Node.js Express applikasjon for å teste Azure infrastrukturen.

## Features

- ✅ Health check endpoints
- ✅ Database connectivity testing
- ✅ Simple CRUD API for items
- ✅ Application Insights ready
- ✅ Environment configuration

## Endpoints

### Health Check
```
GET /
```
Returnerer app status og basic info.

### Database Health Check
```
GET /health/db
```
Tester database connectivity og returnerer PostgreSQL versjon.

### API Endpoints

#### Get all items
```
GET /api/items
```

#### Create new item
```
POST /api/items
Content-Type: application/json

{
  "name": "Item name",
  "description": "Item description (optional)"
}
```

#### Environment info
```
GET /api/info
```

## Lokal kjøring

### Forutsetninger
- Node.js 18+ installert
- PostgreSQL server tilgjengelig

### Setup

```bash
# Installer dependencies
npm install

# Sett environment variables
export DATABASE_CONNECTION_STRING="postgresql://user:password@host:5432/database?sslmode=require"
export ENVIRONMENT="development"

# Kjør app
npm start

# Eller med nodemon for development
npm run dev
```

## Deploy til Azure App Service

### Metode 1: Azure CLI

```bash
# Naviger til sample-app directory
cd sample-app

# Deploy med ZIP
az webapp up \
  --name <app-service-name> \
  --resource-group <resource-group-name> \
  --runtime "NODE:18-lts"

# Eller deploy fra Git
az webapp deployment source config \
  --name <app-service-name> \
  --resource-group <resource-group-name> \
  --repo-url <git-url> \
  --branch main \
  --manual-integration
```

### Metode 2: GitHub Actions

Se `.github/workflows/deploy-app.yml` for CI/CD pipeline.

### Metode 3: VS Code

Bruk Azure App Service extension i VS Code for å deploye direkte.

## Environment Variables

App Service må ha følgende environment variables konfigurert:

### Required
- `DATABASE_CONNECTION_STRING` - PostgreSQL connection string (fra Key Vault)

### Optional
- `ENVIRONMENT` - Environment navn (dev/staging/prod)
- `APPLICATIONINSIGHTS_CONNECTION_STRING` - Application Insights (automatisk fra Terraform)

## Testing

### Test lokalt

```bash
# Health check
curl http://localhost:3000/

# Database health
curl http://localhost:3000/health/db

# Get items
curl http://localhost:3000/api/items

# Create item
curl -X POST http://localhost:3000/api/items \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Item", "description": "This is a test"}'
```

### Test i Azure

Erstatt `<app-name>` med ditt App Service navn:

```bash
# Health check
curl https://<app-name>.azurewebsites.net/

# Database health
curl https://<app-name>.azurewebsites.net/health/db

# Get items
curl https://<app-name>.azurewebsites.net/api/items
```

## Database Schema

Applikasjonen oppretter automatisk følgende tabell ved første kjøring:

```sql
CREATE TABLE items (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Utvidelse

Dette er en minimal app. For produksjon bør du legge til:

- ✅ Proper error handling
- ✅ Input validation (f.eks. med Joi eller express-validator)
- ✅ Authentication og authorization
- ✅ Rate limiting
- ✅ Logging (Winston eller Pino)
- ✅ Database migrations (f.eks. med Knex eller Prisma)
- ✅ Unit og integration tests
- ✅ API documentation (Swagger/OpenAPI)
- ✅ CORS configuration
- ✅ Security headers (Helmet)

## Troubleshooting

### Problem: Cannot connect to database
**Sjekk:**
1. Er `DATABASE_CONNECTION_STRING` satt?
2. Er App Service VNet Integration konfigurert?
3. Er database firewall rules korrekte?
4. Kan du koble til fra Azure Cloud Shell?

### Problem: App crasher ved startup
**Sjekk:**
1. Node.js versjon i App Service
2. Alle npm dependencies installert
3. Logs i App Service: `az webapp log tail`

### Problem: 502 Bad Gateway
**Sjekk:**
1. App kjører på riktig port (process.env.PORT)
2. Health check path er korrekt i App Service
3. Startup Command er korrekt

## Logs

### Se live logs
```bash
az webapp log tail \
  --name <app-name> \
  --resource-group <resource-group-name>
```

### Last ned logs
```bash
az webapp log download \
  --name <app-name> \
  --resource-group <resource-group-name> \
  --log-file logs.zip
```

## Mer informasjon

- [Express.js Documentation](https://expressjs.com/)
- [node-postgres Documentation](https://node-postgres.com/)
- [Azure App Service Node.js](https://learn.microsoft.com/en-us/azure/app-service/quickstart-nodejs)
