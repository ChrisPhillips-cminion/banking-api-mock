#!/bin/bash

# Script to expose the banking-api-mock deployment as a service and route with HTTPS edge termination
# Usage: ./expose-service.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="banking-api-mock"
PORT=3000
ROUTE_NAME="banking-api-mock"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Exposing Banking API Mock Service${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if oc is installed
if ! command -v oc &> /dev/null; then
    echo -e "${RED}Error: OpenShift CLI (oc) is not installed${NC}"
    echo "Please install oc from: https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html"
    exit 1
fi

# Check if logged in to OpenShift
if ! oc whoami &> /dev/null; then
    echo -e "${RED}Error: Not logged in to OpenShift${NC}"
    echo "Please login using: oc login <cluster-url>"
    exit 1
fi

# Get current project
CURRENT_PROJECT=$(oc project -q)
echo -e "${YELLOW}Current project: ${CURRENT_PROJECT}${NC}"
echo ""

# Check if deployment/deploymentconfig exists
echo -e "${YELLOW}Checking for deployment...${NC}"
if oc get dc/${APP_NAME} &> /dev/null; then
    RESOURCE_TYPE="dc"
    echo -e "${GREEN}✓ Found DeploymentConfig: ${APP_NAME}${NC}"
elif oc get deployment/${APP_NAME} &> /dev/null; then
    RESOURCE_TYPE="deployment"
    echo -e "${GREEN}✓ Found Deployment: ${APP_NAME}${NC}"
else
    echo -e "${RED}Error: No deployment or deploymentconfig found with name: ${APP_NAME}${NC}"
    echo "Please ensure the application is deployed first."
    exit 1
fi
echo ""

# Create or update service
echo -e "${YELLOW}Creating/updating service...${NC}"
if oc get svc/${APP_NAME} &> /dev/null; then
    echo -e "${YELLOW}Service already exists, updating...${NC}"
    oc delete svc/${APP_NAME}
fi

oc expose ${RESOURCE_TYPE}/${APP_NAME} \
    --port=${PORT} \
    --target-port=${PORT} \
    --name=${APP_NAME} \
    --labels="app=${APP_NAME},app.kubernetes.io/name=${APP_NAME},app.kubernetes.io/component=backend"

echo -e "${GREEN}✓ Service created: ${APP_NAME}${NC}"
echo ""

# Create or update route with HTTPS edge termination
echo -e "${YELLOW}Creating/updating route with HTTPS edge termination...${NC}"
if oc get route/${ROUTE_NAME} &> /dev/null; then
    echo -e "${YELLOW}Route already exists, updating...${NC}"
    oc delete route/${ROUTE_NAME}
fi

oc create route edge ${ROUTE_NAME} \
    --service=${APP_NAME} \
    --port=${PORT} \
    --insecure-policy=Redirect

# Add labels to the route
oc label route/${ROUTE_NAME} \
    app=${APP_NAME} \
    app.kubernetes.io/name=${APP_NAME} \
    app.kubernetes.io/component=backend

echo -e "${GREEN}✓ Route created with HTTPS edge termination${NC}"
echo ""

# Get route URL
ROUTE_URL=$(oc get route/${ROUTE_NAME} -o jsonpath='{.spec.host}')

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Service and Route Created Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Service Details:${NC}"
oc get svc/${APP_NAME}
echo ""
echo -e "${YELLOW}Route Details:${NC}"
oc get route/${ROUTE_NAME}
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Access URLs:${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "HTTPS URL: ${GREEN}https://${ROUTE_URL}${NC}"
echo -e "Health Check: ${GREEN}https://${ROUTE_URL}/health${NC}"
echo -e "API Documentation: ${GREEN}https://${ROUTE_URL}/api-docs${NC}"
echo ""
echo -e "${YELLOW}Testing the endpoint...${NC}"
if command -v curl &> /dev/null; then
    echo ""
    curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" https://${ROUTE_URL}/health || true
    echo ""
else
    echo -e "${YELLOW}curl not found, skipping endpoint test${NC}"
fi

echo -e "${GREEN}Done!${NC}"

# Made with Bob
