#!/bin/bash
set -e

echo "🚀 Setting up minikube cluster for Crossplane..."

CLUSTER_NAME="crossplane-demo"
MEMORY="4096"
CPUS="2"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v minikube &> /dev/null; then
    echo -e "${RED}minikube not found. Please install minikube first.${NC}"
    echo "Visit: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl not found. Please install kubectl first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites OK${NC}"

# Start minikube
echo -e "${YELLOW}Starting minikube cluster...${NC}"
minikube start \
  --profile ${CLUSTER_NAME} \
  --memory ${MEMORY} \
  --cpus ${CPUS} \
  --kubernetes-version stable

# Enable useful addons
echo -e "${YELLOW}Enabling useful addons...${NC}"
minikube addons enable metrics-server -p ${CLUSTER_NAME}

# Wait for cluster to be ready
echo -e "${YELLOW}Waiting for cluster to be ready...${NC}"
kubectl wait --for=condition=ready node --all --timeout=300s

echo ""
echo -e "${GREEN}✅ Minikube cluster created successfully!${NC}"
echo ""
kubectl get nodes
echo ""
echo "Useful commands:"
echo "  minikube dashboard -p ${CLUSTER_NAME}  # Open Kubernetes dashboard"
echo "  minikube profile ${CLUSTER_NAME}       # Set as default profile"
echo ""
echo "Next step: ./scripts/install-crossplane.sh"
