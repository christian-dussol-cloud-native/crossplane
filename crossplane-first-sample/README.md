# Crossplane Learning Journey - MVP Edition
## Simple, Educational, Production-Ready

> **Part of the CNCF Project Focus Series** - Learn Crossplane through practical examples

[![CNCF Project](https://img.shields.io/badge/CNCF-Graduated-blue)](https://www.cncf.io/projects/crossplane/)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)

---

## 🎯 What is This?

A practical learning repository for **Crossplane** - CNCF's universal control plane for multi-cloud infrastructure.

**Focus:** Production-ready examples, not theoretical tutorials.

**Who it's for:** Platform Engineers, DevOps teams, and SREs managing multi-cloud infrastructure.

---

## ⚡ Quick Start (10 minutes)

```bash
# 1. Clone repository
git clone https://github.com/YOUR_USERNAME/crossplane-learning-journey
cd crossplane-learning-journey

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

## 🎓 What You'll Learn

### Step 1: The Basics (30 minutes)
- Install Crossplane on Kubernetes
- Configure cloud provider credentials
- Create simple resources (S3 bucket, Storage Account)
- Understand managed resources

### Step 2: Custom APIs (1 hour)
- Build a multi-cloud database composition
- Create your own platform API
- Switch between AWS/Azure/GCP without code changes

### Step 3: Governance (1 hour)
- Enforce cost allocation tags with Kyverno
- Require encryption and backups
- Implement security policies

### Step 4: Cost Optimization (30 minutes)
- Calculate potential savings
- Compare multi-cloud costs
- Understand the FinOps value

---

## 📁 Repository Structure

```
crossplane-learning-journey/
│
├── README.md                    # You are here
├── scripts/
│   ├── setup-cluster.sh         # Create local k8s cluster
│   ├── install-crossplane.sh    # Install Crossplane
│   ├── configure-aws.sh         # AWS provider setup
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
│   └── 03-governance/
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

### The Problem
You're managing infrastructure across multiple clouds:
- AWS team uses Terraform
- Azure team uses ARM Templates
- GCP team uses Deployment Manager

**Result:** 
- 5+ different tools
- Duplicate code for each cloud
- 2-5 days to provision resources
- No standardization

### The Crossplane Solution

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
- ✅ Vendor neutrality - no lock-in
- ✅ Kubernetes-native - use kubectl
- ✅ GitOps ready - works with ArgoCD/Flux
- ✅ Self-service - developers provision their own infrastructure
- ✅ Governance - enforce policies with Kyverno

---

## 🚀 Example: Multi-Cloud Database

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

**Result:** All databases must have cost allocation tags. No exceptions.

See more policies in `examples/03-governance/`

---

## 💰 Cost Optimization

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

### Level 1: Getting Started (1 hour)
1. Read [Why Crossplane?](docs/why-crossplane.md)
2. Run Quick Start above
3. Deploy simple S3 bucket
4. Understand managed resources

### Level 2: Compositions (2 hours)
1. Read [Compositions Guide](docs/compositions-guide.md)
2. Study the database example
3. Deploy multi-cloud database
4. Try switching between providers

### Level 3: Governance (1 hour)
1. Install Kyverno
2. Apply cost tagging policy
3. Test policy enforcement
4. Create your own policies

### Level 4: Production (2 hours)
1. Read [Multi-Cloud Patterns](docs/multi-cloud.md)
2. Calculate ROI for your use case
3. Design your platform API
4. Plan migration strategy

---

## 🔧 Prerequisites

- **Kubernetes cluster** - Local minikube (recommended) or cloud cluster (AKS/EKS/GKE)
- **kubectl** >= 1.28
- **helm** >= 3.12
- **minikube** - [Install guide](https://minikube.sigs.k8s.io/docs/start/)
- **Cloud provider account** (AWS, Azure, or GCP)

Optional but recommended:
- **Kyverno** (for governance)
- **ArgoCD** (for GitOps)

---

## 🤝 Contributing

Found an issue? Have a better example? Contributions welcome!

**Guidelines:**
- All examples must be tested and working
- Focus on production readiness, not toy examples
- Include clear documentation
- Follow Kubernetes best practices

---

## 📖 Additional Resources

### Official Documentation
- [Crossplane Docs](https://docs.crossplane.io/)
- [CNCF Crossplane](https://www.cncf.io/projects/crossplane/)
- [Kyverno Docs](https://kyverno.io/)

### Related Articles
- [Why Crossplane for Multi-Cloud Infrastructure](https://medium.com/@...) *(coming soon)*
- Episode #1: [Knative - Serverless on Kubernetes](https://github.com/...)

### Community
- [Crossplane Slack](https://crossplane.slack.com/)
- [CNCF Slack #crossplane](https://cloud-native.slack.com/)

---

## 🎯 What Makes This Different?

**Most Crossplane tutorials:**
- ❌ Cloud provider specific (vendor lock-in from day one)
- ❌ Theoretical "Hello World" examples
- ❌ No governance or cost considerations
- ❌ Missing production patterns

**This repository:**
- ✅ Multi-cloud from the start
- ✅ Production-ready examples
- ✅ FinOps and governance integrated
- ✅ Real-world patterns from financial services

---

## 💬 Questions or Feedback?

- **Issues:** [Open an issue](../../issues)
- **LinkedIn:** [Christian Dussol](https://linkedin.com/in/christiandussol)
- **Email:** [your-email]

---

## 📝 License

Apache License 2.0 - See [LICENSE](LICENSE) file for details.

---

**Part of the CNCF Project Focus Series**  
Educational content for production cloud-native technologies.

**Author:** Christian Dussol  
**Experience:** 20+ years in financial services technology, Senior Engineering Manager at Finastra

---

## ⭐ Star This Repository

If you find this helpful, please star the repository and share with your team!

**Keywords:** Crossplane, CNCF, Kubernetes, Multi-Cloud, Platform Engineering, FinOps, GitOps, Infrastructure as Code, Kyverno, Cloud Native, DevOps, AWS, Azure, GCP
