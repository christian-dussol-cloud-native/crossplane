# Multi-Cloud Database Composition

Learn to create custom APIs that work across AWS, Azure, and GCP.

## What's This About?

Instead of deploying AWS RDS directly, you create a **platform API** that abstracts the cloud provider details.

Developers just say "I need a medium PostgreSQL database" and it gets deployed to whichever cloud you configure.

## Files in This Directory

- `definition.yaml` - Defines your **DatabaseInstance** API
- `composition.yaml` - Implements it using AWS RDS
- `claim.yaml` - Example of how developers use it

## Quick Start

### 1. Install the Definition and Composition

```bash
kubectl apply -f definition.yaml
kubectl apply -f composition.yaml
```

Wait for the composition to be ready:
```bash
kubectl get compositeresourcedefinition
kubectl get composition
```

### 2. Create a Database

```bash
kubectl apply -f claim.yaml
```

### 3. Watch It Being Created

```bash
# Watch the claim
kubectl get databaseinstance my-app-database -w

# Check detailed status
kubectl describe databaseinstance my-app-database
```

It will take 5-10 minutes for AWS to provision the RDS instance.

### 4. Get Connection Details

Once `READY` is `True`:

```bash
# View the secret
kubectl get secret my-app-db-connection -o yaml

# Decode the password
kubectl get secret my-app-db-connection \
  -o jsonpath='{.data.password}' | base64 -d
```

## The Multi-Cloud Magic

**Same DatabaseInstance YAML works on different clouds!**

Just change this line in `claim.yaml`:
```yaml
compositionSelector:
  matchLabels:
    provider: aws  # Change to 'azure' or 'gcp'
```

Your application doesn't change. The connection secret format stays the same.

## Using in Your Application

### As Environment Variables

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: app
    image: myapp:latest
    env:
    - name: DB_HOST
      valueFrom:
        secretKeyRef:
          name: my-app-db-connection
          key: endpoint
    - name: DB_PORT
      valueFrom:
        secretKeyRef:
          name: my-app-db-connection
          key: port
    - name: DB_USER
      valueFrom:
        secretKeyRef:
          name: my-app-db-connection
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: my-app-db-connection
          key: password
```

### As Mounted Files

```yaml
spec:
  containers:
  - name: app
    volumeMounts:
    - name: db-credentials
      mountPath: /etc/db
      readOnly: true
  volumes:
  - name: db-credentials
    secret:
      secretName: my-app-db-connection
```

## What You're Learning

**Composition**: Combining multiple cloud resources into a single API.

**Abstraction**: Hiding cloud-specific complexity from developers.

**Portability**: Same API works across AWS, Azure, GCP.

**Self-Service**: Developers provision their own databases without tickets.

## Customizing

### Change Database Size

Edit `claim.yaml`:
```yaml
spec:
  parameters:
    size: large  # small, medium, or large
```

### Enable High Availability

```yaml
spec:
  parameters:
    highAvailability: true  # Enables Multi-AZ
```

### Use MySQL Instead of Postgres

```yaml
spec:
  parameters:
    engine: mysql
    version: "8.0"
```

## Cost Optimization

Notice the **required tags** in the definition:
```yaml
tags:
  cost-center: "engineering"
  project: "learning-crossplane"
  environment: "development"
```

These tags enable:
- Cost allocation and chargeback
- Filtering by team/project in AWS Cost Explorer
- Automated shutdown of dev/staging environments
- Budget alerts per cost-center

See `examples/03-governance/` to enforce these tags with policies.

## Adding More Cloud Providers

To add Azure or GCP support:

1. Create `composition-azure.yaml` (similar to `composition.yaml` but using Azure resources)
2. Label it with `provider: azure`
3. Apply it: `kubectl apply -f composition-azure.yaml`

Now developers can choose `provider: azure` in their claims!

## Troubleshooting

### DatabaseInstance stays in "Creating" state

```bash
# Check composition status
kubectl describe databaseinstance my-app-database

# Check underlying RDS resource
kubectl get instance -A
kubectl describe instance -n crossplane-system
```

### "No Composition found" error

Make sure the composition exists and has the right labels:
```bash
kubectl get composition
kubectl describe composition xdatabase.aws.platform.example.com
```

### Connection secret not created

The secret only appears when the database is fully provisioned (`READY=True`).

Check the status:
```bash
kubectl get databaseinstance my-app-database -o jsonpath='{.status.conditions}'
```

## Cleanup

```bash
# Delete the claim (this deletes the AWS RDS instance!)
kubectl delete -f claim.yaml

# Verify deletion
kubectl get databaseinstance
kubectl get instance -A
```

**Warning**: Deleting the claim will delete the actual database in AWS.

## Next Steps

- Add governance policies: `examples/03-governance/`
- Calculate cost savings: `scripts/cost-calculator.py`
- Add Azure/GCP compositions
- Integrate with ArgoCD for GitOps
