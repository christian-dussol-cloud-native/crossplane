#!/bin/bash
# scripts/install-crossplane.sh
# Install Crossplane on your Kubernetes cluster

set -e

echo "🚀 Installing Crossplane..."

# Configuration
CROSSPLANE_VERSION="1.14.5"
CROSSPLANE_NAMESPACE="crossplane-system"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl not found. Please install kubectl first.${NC}"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo -e "${RED}helm not found. Please install helm first.${NC}"
    exit 1
fi

# Check cluster connectivity
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Cannot connect to Kubernetes cluster. Please check your kubeconfig.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites OK${NC}"

# Add Crossplane Helm repository
echo -e "${YELLOW}Adding Crossplane Helm repository...${NC}"
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

# Create namespace
echo -e "${YELLOW}Creating namespace ${CROSSPLANE_NAMESPACE}...${NC}"
kubectl create namespace ${CROSSPLANE_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Install Crossplane
echo -e "${YELLOW}Installing Crossplane ${CROSSPLANE_VERSION}...${NC}"
helm upgrade --install crossplane \
  crossplane-stable/crossplane \
  --namespace ${CROSSPLANE_NAMESPACE} \
  --version ${CROSSPLANE_VERSION} \
  --set args='{--enable-composition-functions}' \
  --wait

# Wait for Crossplane pods to be ready
echo -e "${YELLOW}Waiting for Crossplane pods to be ready...${NC}"
kubectl wait --for=condition=ready pod \
  -l app=crossplane \
  -n ${CROSSPLANE_NAMESPACE} \
  --timeout=300s

# Verify installation
echo -e "${YELLOW}Verifying installation...${NC}"
kubectl get pods -n ${CROSSPLANE_NAMESPACE}

# Install Crossplane CLI (optional but recommended)
echo -e "${YELLOW}Installing Crossplane CLI...${NC}"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    curl -sL "https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh" | sh
    sudo mv crossplane /usr/local/bin/
elif [[ "$OSTYPE" == "darwin"* ]]; then
    brew install crossplane/tap/crossplane
else
    echo -e "${YELLOW}Crossplane CLI installation skipped (unsupported OS)${NC}"
    echo -e "${YELLOW}Manual installation: https://docs.crossplane.io/latest/cli/${NC}"
fi

echo ""
echo -e "${GREEN}✅ Crossplane installed successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Configure a provider: kubectl apply -f examples/00-providers/[aws|azure|gcp]/"
echo "2. Verify providers: kubectl get providers"
echo "3. Deploy your first resource: kubectl apply -f examples/01-basics/"
echo ""
echo "For monitoring: kubectl get crossplane -n ${CROSSPLANE_NAMESPACE}"
