# Governance with Kyverno

Enforce policies on your Crossplane resources automatically.

## What's this about?

**Crossplane provisions infrastructure. Kyverno ensures compliance.**

Instead of manual reviews and approval processes, you define policies that are automatically enforced.

## Policies included

### require-tags.yaml
**Enforces cost allocation tags on all databases.**

Every database must have:
- `cost-center` - For chargeback
- `project` - For tracking
- `environment` - production, staging, or development

### require-backup.yaml
**Ensures production databases have backups enabled.**

If `environment: production`, then `backup: true` is mandatory.

Development and staging databases can skip backups (to save costs).

## Prerequisites

### Install Kyverno

Installation Guide: https://kyverno.io/docs/installation/

```bash
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.13.0/install.yaml
```

Wait for Kyverno to be ready:
```bash
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=kyverno \
  -n kyverno \
  --timeout=300s
```

## Quick Start

### 1. Apply Policies

```bash
kubectl apply -f require-tags.yaml
kubectl apply -f require-backup.yaml
```

### 2. Verify Policies

```bash
kubectl get clusterpolicy
```

Expected output:
```
NAME                            BACKGROUND   VALIDATE ACTION   READY
require-cost-tags-database      true         Enforce           True
production-database-backup      true         Enforce           True
```

### 3. Test Policy Enforcement

Try creating a database **without tags** - it should be REJECTED:

```bash
kubectl apply -f - <<EOF
apiVersion: platform.example.com/v1alpha1
kind: DatabaseInstance
metadata:
  name: bad-db
spec:
  parameters:
    size: small
    engine: postgres
    version: "15"
    # Missing tags!
  compositionSelector:
    matchLabels:
      provider: aws
EOF
```

You should see an error like:
```
Error from server: admission webhook denied the request:
Database instance must have cost allocation tags: cost-center, project, environment
```

### 4. Test Compliant Database

Now try with proper tags - it should be ACCEPTED:

```bash
kubectl apply -f ../02-database/claim.yaml
```

This works because it has all required tags!

## Understanding Policy Reports

After creating resources, Kyverno generates policy reports:

```bash
# List all policy reports
kubectl get policyreport -A

# View details for your namespace
kubectl describe policyreport -n default
```

Policy reports show:
- Which resources passed validation
- Which resources failed (and why)
- Policy enforcement statistics

## Testing Policy Enforcement

### Test 1: Missing Tags (Should Fail)

```bash
kubectl apply -f - <<EOF
apiVersion: platform.example.com/v1alpha1
kind: DatabaseInstance
metadata:
  name: test-no-tags
spec:
  parameters:
    size: small
    engine: postgres
EOF
```

**Expected:** ❌ Rejected by `require-cost-tags-database` policy

### Test 2: Production Without Backup (Should Fail)

```bash
kubectl apply -f - <<EOF
apiVersion: platform.example.com/v1alpha1
kind: DatabaseInstance
metadata:
  name: test-prod-no-backup
spec:
  parameters:
    size: medium
    engine: postgres
    version: "15"
    backup: false
    tags:
      cost-center: engineering
      project: test
      environment: production
  compositionSelector:
    matchLabels:
      provider: aws
EOF
```

**Expected:** ❌ Rejected by `production-database-backup` policy

### Test 3: Dev Without Backup (Should Pass)

```bash
kubectl apply -f - <<EOF
apiVersion: platform.example.com/v1alpha1
kind: DatabaseInstance
metadata:
  name: test-dev-no-backup
spec:
  parameters:
    size: small
    engine: postgres
    version: "15"
    backup: false
    tags:
      cost-center: engineering
      project: test
      environment: development
  compositionSelector:
    matchLabels:
      provider: aws
EOF
```

**Expected:** ✅ Accepted (dev doesn't need backups)

## Why This Matters

### Cost Optimization

**Without policies:**
- Inconsistent tagging
- No cost allocation
- Can't identify waste
- No chargeback possible

**With policies:**
- 100% tag compliance
- Accurate cost allocation per team/project
- Easy to identify and eliminate waste
- Chargeback to cost centers

### Security & Compliance

**Automated enforcement of:**
- Backup requirements
- Encryption standards
- Network isolation
- Resource naming conventions
- Region restrictions

No manual reviews needed. No human error.

### Platform Engineering

**Self-service with guardrails:**
- Developers can provision infrastructure
- But only compliant infrastructure
- Platform team sets policies once
- Policies enforce automatically

## Audit Mode vs Enforce Mode

Policies can run in two modes:

### Enforce Mode (Default)
```yaml
spec:
  validationFailureAction: enforce
```
Non-compliant resources are **rejected**.

### Audit Mode
```yaml
spec:
  validationFailureAction: audit
```
Non-compliant resources are **allowed** but flagged in policy reports.

**Use audit mode when:**
- Testing new policies
- Gradual rollout
- Non-critical policies

**Use enforce mode for:**
- Critical compliance requirements
- Security policies
- Cost governance

To switch a policy to audit mode:
```bash
kubectl patch clusterpolicy require-cost-tags-database \
  --type=merge \
  -p '{"spec":{"validationFailureAction":"audit"}}'
```

## Creating Your Own Policies

### Example: Restrict Database Sizes

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: limit-database-size
spec:
  validationFailureAction: enforce
  rules:
  - name: no-large-dev-databases
    match:
      any:
      - resources:
          kinds:
          - DatabaseInstance
    validate:
      message: "Development databases must use 'small' or 'medium' size"
      pattern:
        spec:
          parameters:
            tags:
              environment: development
            size: "small|medium"
```

### Example: Require Encryption

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-encryption
spec:
  validationFailureAction: enforce
  rules:
  - name: database-encryption
    match:
      any:
      - resources:
          kinds:
          - DatabaseInstance
    validate:
      message: "Databases must have encryption enabled"
      pattern:
        spec:
          parameters:
            encryption: true
```

## Monitoring Policy Compliance

### Prometheus Metrics

Kyverno exposes metrics for monitoring:

```
kyverno_policy_results_total{policy="require-cost-tags-database",result="pass"}
kyverno_policy_results_total{policy="require-cost-tags-database",result="fail"}
```

### Grafana Dashboard

Create alerts for:
- Policy violation trends
- Repeated violations (training opportunity)
- Tag compliance percentage

## Troubleshooting

### Policy not enforcing

```bash
# Check policy status
kubectl get clusterpolicy require-cost-tags-database -o yaml

# Check Kyverno logs
kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno
```

### Policy reports not appearing

```bash
# Check if background scanning is enabled
kubectl get clusterpolicy -o jsonpath='{.items[*].spec.background}'

# Trigger manual scan
kubectl annotate databaseinstance my-db policy.kyverno.io/last-applied-configuration-
```

### Resource allowed despite policy

Check if policy is in `audit` mode:
```bash
kubectl get clusterpolicy -o jsonpath='{.items[*].spec.validationFailureAction}'
```

## Next Steps

- Calculate cost savings: `scripts/cost-calculator.py`
- Add more policies (encryption, naming, regions)
- Integrate with alerting (Prometheus + Grafana)
- Set up policy as code in Git
- Implement policy testing in CI/CD

## Learn More

- [Kyverno Documentation](https://kyverno.io/docs/)
- [Policy Library](https://kyverno.io/policies/)
- [Best Practices](https://kyverno.io/docs/writing-policies/best-practices/)
