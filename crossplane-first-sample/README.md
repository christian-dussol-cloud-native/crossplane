# Crossplane learning journey - First sample

> **Part of the CNCF Project Focus Series** - Learn Crossplane through practical examples

[![CNCF Project](https://img.shields.io/badge/CNCF-Graduated-blue)](https://www.cncf.io/projects/crossplane/)
[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC%20BY--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)

---

## 🎯 What is this?

A practical learning repository for **Crossplane** - CNCF's universal control plane for multi-cloud infrastructure.

**Who it's for:** Platform Engineers, DevOps teams and SREs managing multi-cloud infrastructure.

---

## ⚡ Quick Start

```bash
# 1. Clone repository
git clone https://github.com/christian-dussol-cloud-native/crossplane.git
cd crossplane-first-sample

# 2. Create local Kubernetes cluster
./scripts/setup-cluster.sh

# 3. Install Crossplane
./scripts/install-crossplane.sh

# 4. Configure AWS provider (or Azure/GCP)
./scripts/configure-aws.sh

# 5. Deploy your first resource
kubectl apply -f examples/s3-bucket.yaml

# 6. Verify
kubectl get bucket
```

**That's it!** You have Crossplane running with your first cloud resource.

---

## 🎓 What You will Learn

### Step 1: The Basics
- Install Crossplane on Kubernetes
- Configure cloud provider credentials
- Create simple resources (S3 bucket, Storage Account)
- Understand managed resources

### Step 2: Custom APIs
- Build a multi-cloud database composition
- Create your own platform API
- Switch between AWS/Azure/GCP without code changes

### Step 3: Governance
- Enforce cost allocation tags with Kyverno
- Require encryption and backups
- Implement security policies

### Step 4: Cost Optimization
- Calculate potential savings
- Compare multi-cloud costs
- Understand the FinOps value

---

## 📁 Repository Structure

```
crossplane-first-sample/
│
├── README.md                    # You are here
├── scripts/
│   ├── setup-cluster.sh         # Create local k8s cluster
│   ├── install-crossplane.sh    # Install Crossplane
│   ├── configure-aws.sh         # AWS provider setup
│   ├── create-db-password.sh    # Create AWS DB password for 02-database example
│   ├── get-db-credentials.sh    # Get AWS DB credentials for 02-database example
│   └── cost-calculator.py       # ROI calculator
│
├── examples/
│   ├── 01-simple/
│   │   ├── s3-bucket.yaml       # Basic S3 bucket
│   │   └── README.md
│   │
│   ├── 02-database/
│   │   ├── definition.yaml      # Database API definition
│   │   ├── composition.yaml     # Multi-cloud composition
│   │   ├── claim.yaml           # How to use it
│   │   └── README.md
│   │
│   └── 03-governance/           # Kyverno policies
│       ├── require-tags.yaml    # Cost allocation policy
│       ├── require-backup.yaml  # Backup enforcement
│       └── README.md
│
└── docs/
    ├── why-crossplane.md        # When to use Crossplane
    ├── compositions-guide.md    # Building compositions
    └── multi-cloud.md           # Multi-cloud patterns
```

---

## 💡 Why Crossplane?

### Context
You are managing infrastructure across multiple clouds:
- AWS team uses Terraform
- Azure team uses ARM Templates
- GCP team uses Deployment Manager

**Result:** 
- 5+ different tools
- Duplicate code for each cloud
- 2-5 days to provision resources
- No standardization

### Crossplane solution

**One API for all clouds:**
```yaml
apiVersion: database.example.com/v1alpha1
kind: DatabaseInstance
metadata:
  name: my-database
spec:
  size: medium
  engine: postgres
  provider: aws  # Change to 'azure' or 'gcp' - that's it!
```

**Benefits:**
- Vendor neutrality - no lock-in
- Kubernetes-native - use kubectl
- GitOps ready - works with ArgoCD/Flux
- Self-service - developers provision their own infrastructure
- Governance - enforce policies with Kyverno

---

## Example: Multi-Cloud Database

**One definition, three cloud providers:**

The same database specification works on:
- AWS RDS
- Azure Database for PostgreSQL
- GCP Cloud SQL

**How it works:**

1. Define what you want (business level):
```yaml
apiVersion: database.example.com/v1alpha1
kind: DatabaseInstance
metadata:
  name: production-db
spec:
  size: medium
  engine: postgres
  backup: true
  tags:
    cost-center: engineering
    project: customer-portal
```

2. Choose your cloud:
```yaml
  compositionSelector:
    matchLabels:
      provider: aws  # or azure, or gcp
```

3. Deploy:
```bash
kubectl apply -f database.yaml
```

**Switch providers?** Just change the label. No application code changes needed.

See the complete example in `examples/02-database/`

---

## 🛡️ Governance with Kyverno

Crossplane provisions infrastructure. **Kyverno ensures compliance.**

**Example: Require cost allocation tags**

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-cost-tags
spec:
  validationFailureAction: enforce
  rules:
  - name: check-tags
    match:
      any:
      - resources:
          kinds:
          - DatabaseInstance
    validate:
      message: "Cost center tag required"
      pattern:
        spec:
          tags:
            cost-center: "?*"
```

**Result:** All databases must have cost allocation tags. No exceptions (whatever the cloud provider)

See more policies in `examples/03-governance/`

---

## Cost Optimization

**Traditional Kubernetes:**
- Development database runs 24/7 (168 hours/week)
- Actual usage: 9am-6pm weekdays (45 hours/week)
- Waste: 73% of compute time

**With Crossplane + proper governance:**
- Right-sized instances
- Mandatory tagging for cost allocation
- Multi-cloud cost comparison
- Policy-enforced budgets

**Calculate your savings:**
```bash
python3 scripts/cost-calculator.py \
  --environment development \
  --size medium \
  --replicas 2
```

**Example output:**
```
Traditional cost: $2,520/month (168h/week)
Optimized cost:   $  675/month (45h/week)
Savings:          $1,845/month (73%)
```

---

## 📚 Learning Path

### Level 1: Getting Started
1. Read [Why Crossplane?](docs/why-crossplane.md)
2. Run Quick Start above
3. Deploy simple S3 bucket
4. Understand managed resources

### Level 2: Compositions
1. Read [Compositions Guide](docs/compositions-guide.md)
2. Study the database example
3. Deploy multi-cloud database
4. Try switching between providers

### Level 3: Governance
1. Install Kyverno
2. Apply cost tagging policy
3. Test policy enforcement
4. Create your own policies

### Level 4: Production
1. Read [Multi-Cloud Patterns](docs/multi-cloud.md)
2. Calculate ROI for your use case
3. Design your platform API
4. Plan migration strategy

---

## Prerequisites

- **Kubernetes cluster** - Local minikube (recommended) or cloud cluster (AKS/EKS/GKE)
- **kubectl** >= 1.28
- **helm** >= 3.12
- **minikube** - [Install guide](https://minikube.sigs.k8s.io/docs/start/)
- **Cloud provider account** (AWS, Azure, or GCP)
  - 👉 **New to AWS?** See [AWS Setup Guide](docs/AWS_SETUP_GUIDE.md) for step-by-step account creation (Free Tier, $0 cost)

Optional but recommended:
- **Kyverno** (for governance)

---

## 📖 Additional Resources

### Official Documentation
- [Crossplane Docs](https://docs.crossplane.io/)
- [CNCF Crossplane](https://www.cncf.io/projects/crossplane/)
- [Kyverno Docs](https://kyverno.io/)

### Related Articles
- Episode #1: [Knative - Serverless on Kubernetes](https://github.com/christian-dussol-cloud-native/knative/tree/main)

---

## 📝 License
This repository is licensed under Creative Commons Attribution-ShareAlike 4.0 International License.

[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC%20BY--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)

---

## 📌 Related Projects in "CNCF Project Focus" Series

This is **#2 in the series**. Future projects will explore other CNCF graduated projects.

---

## ⭐ Star This Repository

If you find this helpful, please star the repository and share with your team!