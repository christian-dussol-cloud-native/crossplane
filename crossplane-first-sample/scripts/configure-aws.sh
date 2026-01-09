#!/bin/bash
# scripts/configure-aws.sh
# Simple AWS provider configuration for Crossplane

set -e

echo "🔧 Configuring AWS Provider for Crossplane..."
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check Crossplane is installed
if ! kubectl get namespace crossplane-system &> /dev/null; then
    echo -e "${RED}Crossplane not found. Please run ./scripts/install-crossplane.sh first.${NC}"
    exit 1
fi

# Get AWS credentials
echo "Enter your AWS credentials:"
read -p "AWS Access Key ID: " AWS_KEY_ID
read -sp "AWS Secret Access Key: " AWS_SECRET_KEY
echo ""
echo ""

# Create secret
echo -e "${YELLOW}Creating AWS credentials secret...${NC}"
kubectl create secret generic aws-credentials \
  -n crossplane-system \
  --from-literal=credentials="[default]
aws_access_key_id = ${AWS_KEY_ID}
aws_secret_access_key = ${AWS_SECRET_KEY}" \
  --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✓ Secret created${NC}"

# Install AWS S3 provider
echo -e "${YELLOW}Installing AWS S3 provider...${NC}"
kubectl apply -f - <<EOF
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws-s3
spec:
  package: xpkg.upbound.io/upbound/provider-aws-s3:v1.1.0
EOF

echo -e "${YELLOW}Waiting for provider to be ready (this may take 1-2 minutes)...${NC}"
sleep 10
kubectl wait --for=condition=healthy provider/provider-aws-s3 --timeout=300s

echo -e "${GREEN}✓ Provider installed${NC}"

# Create ProviderConfig
echo -e "${YELLOW}Creating ProviderConfig...${NC}"
kubectl apply -f - <<EOF
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-credentials
      key: credentials
EOF

echo -e "${GREEN}✓ ProviderConfig created${NC}"
echo ""
echo -e "${GREEN}✅ AWS provider configured successfully!${NC}"
echo ""
echo "Test it with:"
echo "  kubectl apply -f examples/01-simple/s3-bucket.yaml"
echo "  kubectl get bucket"
echo ""
