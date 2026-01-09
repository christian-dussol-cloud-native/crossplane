# Quick Troubleshooting

Common issues and how to fix them.

## Crossplane Installation Issues

### Provider not becoming healthy

**Symptom:**
```bash
kubectl get providers
# Shows: HEALTHY=Unknown or False
```

**Check:**
```bash
# View provider logs
kubectl logs -n crossplane-system \
  -l pkg.crossplane.io/provider=provider-aws-s3

# Check provider status
kubectl describe provider provider-aws-s3
```

**Common causes:**
- Network connectivity issues
- Invalid credentials
- Rate limiting from cloud provider

**Fix:**
- Wait 2-3 minutes (providers take time to install)
- Check credentials are correct
- Verify network allows HTTPS to cloud APIs

### ProviderConfig not working

**Symptom:**
```bash
kubectl get providerconfig default
# Shows error or doesn't exist
```

**Check:**
```bash
# Verify secret exists
kubectl get secret aws-credentials -n crossplane-system

# Check ProviderConfig details
kubectl describe providerconfig default
```

**Fix:**
```bash
# Re-create credentials
./scripts/configure-aws.sh
```

## Resource Creation Issues

### S3 Bucket stuck in "Creating"

**Symptom:**
```bash
kubectl get bucket
# READY=False, SYNCED=True for 5+ minutes
```

**Diagnose:**
```bash
# Check resource events
kubectl describe bucket my-first-bucket

# Look for errors in status
kubectl get bucket my-first-bucket -o yaml
```

**Common causes:**
- Bucket name already taken (globally)
- Invalid AWS region
- Insufficient IAM permissions
- Invalid configuration

**Fix:**
```bash
# Change bucket name to something unique
kubectl edit bucket my-first-bucket
# Update metadata.annotations.crossplane.io/external-name
```

### Database not becoming ready

**Symptom:**
```bash
kubectl get databaseinstance
# Stays in "Creating" for 10+ minutes
```

**Diagnose:**
```bash
# Check claim status
kubectl describe databaseinstance my-app-database

# Check underlying RDS resource
kubectl get instance -A
kubectl describe instance -n crossplane-system [instance-name]
```

**Common causes:**
- AWS RDS provisioning is slow (normal: 5-10 min)
- Invalid RDS configuration
- No available subnets
- IAM permissions missing

**Fix:**
- Wait longer (RDS creation takes time)
- Check AWS Console for actual RDS status
- Verify provider has necessary IAM permissions

## Composition Issues

### "No Composition found" error

**Symptom:**
```bash
kubectl apply -f claim.yaml
# Error: no composition found
```

**Check:**
```bash
# Verify composition exists
kubectl get composition

# Check labels match
kubectl describe composition xdatabase.aws.platform.example.com
```

**Fix:**
```bash
# Apply composition first
kubectl apply -f examples/02-database/definition.yaml
kubectl apply -f examples/02-database/composition.yaml

# Wait for them to be ready
kubectl get xrd
kubectl get composition
```

### Composition not matching claim

**Symptom:**
Claim created but no resources provisioned.

**Check:**
```bash
# View claim details
kubectl describe databaseinstance my-app-database

# Check compositionSelector matches composition labels
kubectl get composition -o yaml | grep -A5 labels
```

**Fix:**
Ensure claim's `compositionSelector` matches composition labels:
```yaml
# In claim
compositionSelector:
  matchLabels:
    provider: aws

# In composition
metadata:
  labels:
    provider: aws
```

## Kyverno Policy Issues

### Policy not enforcing

**Symptom:**
Non-compliant resource is allowed through.

**Check:**
```bash
# Verify policy exists and is ready
kubectl get clusterpolicy

# Check validation action
kubectl get clusterpolicy require-cost-tags-database \
  -o jsonpath='{.spec.validationFailureAction}'
```

**Common causes:**
- Policy in `audit` mode instead of `enforce`
- Resource kind doesn't match
- Background scanning disabled

**Fix:**
```bash
# Switch to enforce mode
kubectl patch clusterpolicy require-cost-tags-database \
  --type=merge \
  -p '{"spec":{"validationFailureAction":"enforce"}}'
```

### Policy reports not showing

**Symptom:**
```bash
kubectl get policyreport
# No resources found
```

**Check:**
```bash
# Verify Kyverno is running
kubectl get pods -n kyverno

# Check if background scanning is enabled
kubectl get clusterpolicy -o jsonpath='{.items[*].spec.background}'
```

**Fix:**
- Ensure Kyverno is installed and running
- Policies need `background: true` for reports

## Connection Secret Issues

### Secret not created

**Symptom:**
```bash
kubectl get secret my-app-db-connection
# Error: not found
```

**Check:**
```bash
# Verify database is ready
kubectl get databaseinstance my-app-database

# Check writeConnectionSecretToRef
kubectl get databaseinstance my-app-database \
  -o jsonpath='{.spec.writeConnectionSecretToRef}'
```

**Common causes:**
- Database not fully provisioned yet
- Typo in secret reference
- Missing writeConnectionSecretToRef

**Fix:**
- Wait for database to be READY=True
- Verify secret reference in claim
- Check composition has connectionDetails defined

### Connection details empty

**Symptom:**
Secret exists but has no data.

**Check:**
```bash
kubectl get secret my-app-db-connection -o yaml
```

**Fix:**
- Composition must specify connectionDetails
- Check composition YAML has proper fromConnectionSecretKey mappings

## General Debugging Commands

### View all Crossplane resources

```bash
# All managed resources
kubectl get managed

# All composite resources
kubectl get composite

# All claims
kubectl get claim -A
```

### Check Crossplane controller logs

```bash
kubectl logs -n crossplane-system \
  -l app=crossplane \
  --tail=100 \
  --follow
```

### Check provider logs

```bash
# List all providers
kubectl get providers

# Logs for specific provider
kubectl logs -n crossplane-system \
  -l pkg.crossplane.io/provider=provider-aws-s3 \
  --tail=100
```

### Verbose resource status

```bash
kubectl get <resource> -o yaml
# Look at status.conditions for detailed errors
```

## Performance Issues

### Slow reconciliation

**Symptom:**
Resources take very long to update.

**Check:**
```bash
# Check if provider is overwhelmed
kubectl top pods -n crossplane-system

# Check for many resources
kubectl get managed -A --no-headers | wc -l
```

**Mitigation:**
- Increase provider replicas (if supported)
- Check cloud API rate limits
- Reduce reconciliation frequency

## Cloud Provider Specific

### AWS: "Rate exceeded" errors

**Symptom:**
Resources fail with throttling errors.

**Fix:**
- Add delays between resource creation
- Request AWS rate limit increase
- Use multiple AWS accounts

### AWS: IAM permission denied

**Symptom:**
"User is not authorized" errors.

**Fix:**
```bash
# Verify IAM policy includes:
# - s3:CreateBucket, s3:DeleteBucket
# - rds:CreateDBInstance, rds:DeleteDBInstance
# - ec2:Describe*, ec2:Create*, ec2:Delete*
```

## Still Stuck?

### 1. Check official docs
https://docs.crossplane.io/troubleshoot/

### 2. Search existing issues
https://github.com/crossplane/crossplane/issues

### 3. Ask the community
- [Crossplane Slack](https://crossplane.slack.com/)
- [CNCF Slack #crossplane](https://cloud-native.slack.com/)

### 4. Open an issue
Provide:
- Crossplane version: `kubectl crossplane version`
- Resource YAML (sanitized)
- Describe output
- Provider logs
