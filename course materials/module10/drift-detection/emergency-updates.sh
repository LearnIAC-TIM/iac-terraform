#!/bin/bash

RESOURCE_GROUP="timlab-dev-rg"
APP_SERVICE_PLAN="timlab-dev-asp"
WEBAPP_NAME="timlab-dev-webapp"

# Scale up App Service Plan (can be changed without replacement)
az appservice plan update \
    --name $APP_SERVICE_PLAN \
    --resource-group $RESOURCE_GROUP \
    --sku P1v2 > /dev/null 2>&1

# Update Web App configurations
az webapp config set \
    --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP \
    --number-of-workers 4 \
    --min-tls-version 1.2 \
    --http20-enabled true \
    --always-on true \
    --websockets-enabled true > /dev/null 2>&1

# Add/Update application settings
az webapp config appsettings set \
    --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP \
    --settings \
    WEBSITE_NODE_DEFAULT_VERSION="~20" \
    SCM_DO_BUILD_DURING_DEPLOYMENT="true" \
    WEBSITE_RUN_FROM_PACKAGE="1" \
    WEBSITES_ENABLE_APP_SERVICE_STORAGE="true" \
    NODE_ENV="production" > /dev/null 2>&1

# Update general Web App settings
az webapp update \
    --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP \
    --client-affinity-enabled false > /dev/null 2>&1

# Update tags
az webapp update \
    --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP \
    --set tags.environment=production \
    tags.modified_by=emergency-response \
    tags.incident_id=INC$(date +%Y%m%d) > /dev/null 2>&1