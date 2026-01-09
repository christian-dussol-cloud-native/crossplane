# Simple Examples

Basic Crossplane managed resources to get started.

## Prerequisites

- Kubernetes cluster running
- Crossplane installed (`./scripts/install-crossplane.sh`)
- AWS provider configured (`./scripts/configure-aws.sh`)

## S3 Bucket Example

The simplest possible Crossplane resource - an S3 bucket.

### Deploy

```bash
kubectl apply -f s3-bucket.yaml
```

### Check Status

```bash
# List all buckets
kubectl get bucket

# Get detailed status
kubectl describe bucket my-first-crossplane-bucket

# Watch for ready condition
kubectl get bucket -w
```

Expected output when ready:
```
NAME                          READY   SYNCED   EXTERNAL-NAME                    AGE
my-first-crossplane-bucket    True    True     crossplane-tutorial-USER-12345   2m
```

### Verify in AWS

You can verify the bucket was created in your AWS account:
```bash
aws s3 ls | grep crossplane-tutorial
```

### Delete

```bash
kubectl delete -f s3-bucket.yaml
```

The bucket will be deleted from AWS as well.

## What You're Learning

**Managed Resources**: Crossplane creates and manages the cloud resource directly.

**Declarative**: You declare what you want, Crossplane ensures it exists.

**Kubernetes-native**: Uses kubectl and standard Kubernetes patterns.

**Status Conditions**: 
- `READY` - Resource is fully provisioned
- `SYNCED` - Crossplane is actively managing it

## Troubleshooting

**Bucket not becoming ready?**
```bash
# Check events
kubectl describe bucket my-first-crossplane-bucket

# Check provider logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-aws-s3
```

**"Bucket name already taken" error?**

Change the `external-name` in the YAML to something unique. S3 bucket names must be globally unique across ALL AWS accounts.

## Next Steps

Move to `examples/02-database/` to learn about:
- Composite resources
- Custom APIs
- Multi-cloud compositions
