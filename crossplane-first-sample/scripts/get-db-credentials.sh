#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Database Connection Credentials                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if connection secret exists
if ! kubectl get secret my-app-db-connection &>/dev/null; then
  echo -e "${RED}❌ Connection secret 'my-app-db-connection' not found.${NC}"
  echo ""
  echo -e "${YELLOW}Make sure the database is deployed and ready:${NC}"
  echo "  kubectl get databaseinstance my-app-database"
  echo ""
  echo "Status should show READY=True"
  exit 1
fi

# Check if password secret exists
if ! kubectl get secret rds-database-password -n crossplane-system &>/dev/null; then
  echo -e "${RED}❌ Password secret 'rds-database-password' not found.${NC}"
  echo ""
  echo -e "${YELLOW}Create the password secret first:${NC}"
  echo "  ./scripts/create-db-password.sh"
  exit 1
fi

echo -e "${GREEN}✓ Secrets found${NC}"
echo ""

# Extract credentials from connection secret
USERNAME=$(kubectl get secret my-app-db-connection -o jsonpath='{.data.username}' | base64 -d 2>/dev/null)
ENDPOINT=$(kubectl get secret my-app-db-connection -o jsonpath='{.data.endpoint}' | base64 -d 2>/dev/null)
PORT=$(kubectl get secret my-app-db-connection -o jsonpath='{.data.port}' | base64 -d 2>/dev/null)
DATABASE=$(kubectl get secret my-app-db-connection -o jsonpath='{.data.database}' | base64 -d 2>/dev/null)

# Extract host from endpoint (remove :port if present)
HOST="${ENDPOINT%%:*}"

# Extract password from source secret
PASSWORD=$(kubectl get secret rds-database-password -n crossplane-system -o jsonpath='{.data.password}' | base64 -d 2>/dev/null)

# Display credentials
echo -e "${BLUE}Connection Details:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Host:${NC}     ${HOST}"
echo -e "${GREEN}Port:${NC}     ${PORT}"
echo -e "${GREEN}Database:${NC} ${DATABASE}"
echo -e "${GREEN}Username:${NC} ${USERNAME}"
echo -e "${GREEN}Password:${NC} ${PASSWORD}"
echo ""

# Connection string
echo -e "${BLUE}Connection String:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "postgresql://${USERNAME}:${PASSWORD}@${HOST}:${PORT}/${DATABASE}"
echo ""

# psql command
echo -e "${BLUE}psql Command:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DATABASE}"
echo ""
echo -e "${YELLOW}When prompted, use password:${NC} ${PASSWORD}"
echo ""

# Environment variables export
echo -e "${BLUE}Environment Variables (copy-paste to export):${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat <<EOF
export PGHOST="${HOST}"
export PGPORT="${PORT}"
export PGUSER="${USERNAME}"
export PGPASSWORD="${PASSWORD}"
export PGDATABASE="${DATABASE}"
EOF
echo ""

# Direct connection with environment variable
echo -e "${BLUE}Direct Connection (one-liner):${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PGPASSWORD='${PASSWORD}' psql -h ${HOST} -p ${PORT} -U ${USERNAME} -d ${DATABASE}"
echo ""

# Connect from pod
echo -e "${BLUE}Connect from Kubernetes Pod:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat <<'EOF'
kubectl run psql-client --rm -it --image=postgres:15 \
  --env="PGHOST=<HOST>" \
  --env="PGPORT=<PORT>" \
  --env="PGUSER=<USERNAME>" \
  --env="PGPASSWORD=<PASSWORD>" \
  --env="PGDATABASE=<DATABASE>" \
  -- psql
EOF
echo ""
echo -e "${YELLOW}Replace <HOST>, <PORT>, etc. with values above${NC}"
echo ""

# Security note
echo -e "${YELLOW}⚠️  Security Notes:${NC}"
echo "• Password is stored in rds-database-password secret (crossplane-system)"
echo "• Connection details are in my-app-db-connection secret (default)"
echo "• Database is not publicly accessible (publiclyAccessible: false)"
echo "• Connect from within the Kubernetes cluster or set up port-forwarding"
echo ""

# Port forwarding tip
echo -e "${BLUE}💡 Tip: Connect from your local machine${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "For testing, you can temporarily enable public access:"
echo ""
echo "1. Edit composition.yaml:"
echo "   publiclyAccessible: true"
echo ""
echo "2. Update the database:"
echo "   kubectl apply -f examples/02-database/composition.yaml"
echo "   kubectl delete -f examples/02-database/claim.yaml"
echo "   kubectl apply -f examples/02-database/claim.yaml"
echo ""
echo "3. Wait for READY=True, then connect with psql from your PC"
echo ""
echo -e "${YELLOW}⚠️  Don't forget to set back to false for production!${NC}"
echo ""
