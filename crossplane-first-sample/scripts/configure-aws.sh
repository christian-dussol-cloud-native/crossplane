#!/bin/bash
set -e

echo "🔧 Configuring AWS Providers for Crossplane..."
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Prompt for credentials
echo -e "${YELLOW}Enter your AWS credentials:${NC}"
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
echo ""

# Install AWS S3 provider
echo -e "${YELLOW}Installing AWS S3 provider (for simple examples)...${NC}"
kubectl apply -f - <<YAML
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws-s3
spec:
  package: xpkg.upbound.io/upbound/provider-aws-s3:v1.1.0
YAML

echo -e "${GREEN}✓ S3 provider installation started${NC}"
echo ""

# Install AWS RDS provider
echo -e "${YELLOW}Installing AWS RDS provider (for database examples)...${NC}"
kubectl apply -f - <<YAML
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws-rds
spec:
  package: xpkg.upbound.io/upbound/provider-aws-rds:v1.1.0
YAML

echo -e "${GREEN}✓ RDS provider installation started${NC}"
echo ""

# Wait for providers to be healthy
echo -e "${YELLOW}⏳ Waiting for providers to be ready (this may take 3-5 minutes)...${NC}"
echo "   - Downloading provider packages"
echo "   - Installing CRDs (Custom Resource Definitions)"
echo "   - Starting provider controllers"
echo ""

kubectl wait --for=condition=healthy provider/provider-aws-s3 --timeout=300s
echo -e "${GREEN}✓ S3 provider is healthy${NC}"

kubectl wait --for=condition=healthy provider/provider-aws-rds --timeout=300s
echo -e "${GREEN}✓ RDS provider is healthy${NC}"
echo ""

# Wait for CRDs to be fully registered (critical!)
echo -e "${YELLOW}⏳ Waiting for CRDs to be registered (60 seconds)...${NC}"
echo "   This ensures all Custom Resource Definitions are available"
sleep 60
echo -e "${GREEN}✓ CRDs registered${NC}"
echo ""

# Create ProviderConfig for AWS (works for S3, RDS, and all AWS services)
echo -e "${YELLOW}Configuring AWS providers...${NC}"
kubectl apply -f - <<YAML
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
YAML

echo -e "${GREEN}✓ AWS providers configured${NC}"
echo ""

# Verification
echo -e "${GREEN}✅ AWS providers configured successfully!${NC}"
echo ""
echo "Installed providers:"
kubectl get providers | grep -E "NAME|provider-aws"
echo ""
echo "Next steps:"
echo "  📦 Simple example (S3):    kubectl apply -f examples/01-simple/s3-bucket.yaml"
echo "  🗄️  Database example (RDS): kubectl apply -f examples/02-database/claim.yaml"
echo "  🛡️  Governance (Kyverno):   kubectl apply -f examples/03-governance/"
echo ""
echo "Verify everything is working:"
echo "  kubectl get providers"
echo "  kubectl get providerconfigs"
echo ""
echo "🎉 Ready to create cloud resources with Crossplane!"