#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Create RDS Database Password Secret                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if secret already exists
if kubectl get secret rds-database-password -n crossplane-system &>/dev/null; then
  echo -e "${YELLOW}Secret 'rds-database-password' already exists.${NC}"
  read -p "Do you want to recreate it? (yes/no): " -r
  if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    kubectl delete secret rds-database-password -n crossplane-system
    echo -e "${GREEN}✓ Old secret deleted${NC}"
  else
    echo -e "${YELLOW}Keeping existing secret.${NC}"
    exit 0
  fi
fi

echo ""
echo -e "${YELLOW}Password Requirements (AWS RDS):${NC}"
echo "  • 8-128 characters"
echo "  • Must contain letters and numbers"
echo "  • Can contain: ! # \$ % ^ & * ( ) _ + - = [ ] { } | '"
echo "  • Cannot contain: / @ \" ' \` or space"
echo "  • Cannot be 'admin', 'root', or contain username"
echo ""

# Option 1: Let user enter password
echo -e "${BLUE}Option 1: Enter your own password${NC}"
echo -e "${BLUE}Option 2: Generate a secure password automatically${NC}"
echo ""
read -p "Choose option (1 or 2): " OPTION

if [ "$OPTION" = "1" ]; then
  # User enters password
  read -sp "Enter database password: " PASSWORD
  echo ""
  read -sp "Confirm password: " PASSWORD_CONFIRM
  echo ""
  
  if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
    echo -e "${YELLOW}Passwords don't match. Exiting.${NC}"
    exit 1
  fi
  
  # Basic validation
  if [ ${#PASSWORD} -lt 8 ]; then
    echo -e "${YELLOW}Password too short (minimum 8 characters). Exiting.${NC}"
    exit 1
  fi
  
elif [ "$OPTION" = "2" ]; then
  # Generate secure password
  # Format: Letters + Numbers + Safe symbols (no /, @, ", ', `, space)
  PASSWORD=$(LC_ALL=C tr -dc 'A-Za-z0-9!#$%^&*()_+\-=[]{}|' </dev/urandom | head -c 16)
  
  echo -e "${GREEN}Generated password: ${PASSWORD}${NC}"
  echo -e "${YELLOW}⚠️  Save this password securely! You won't see it again.${NC}"
  echo ""
  read -p "Press Enter to continue..."
  
else
  echo -e "${YELLOW}Invalid option. Exiting.${NC}"
  exit 1
fi

# Create the secret
echo ""
echo -e "${BLUE}Creating secret...${NC}"

kubectl create secret generic rds-database-password \
  -n crossplane-system \
  --from-literal=password="${PASSWORD}"

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓ Secret created successfully!${NC}"
  echo ""
  echo -e "${BLUE}Secret details:${NC}"
  echo "  Name: rds-database-password"
  echo "  Namespace: crossplane-system"
  echo "  Key: password"
  echo ""
  echo -e "${GREEN}✅ You can now deploy the database example!${NC}"
  echo ""
  echo -e "${BLUE}Next steps:${NC}"
  echo "  ./scripts/deploy-database.sh"
  echo ""
else
  echo -e "${YELLOW}Failed to create secret.${NC}"
  exit 1
fi
