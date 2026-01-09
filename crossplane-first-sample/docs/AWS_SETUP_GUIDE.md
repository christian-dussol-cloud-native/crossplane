# Getting AWS Access for Crossplane

This guide will help you set up AWS access to use this Crossplane repository. You will create an AWS account with Free Tier, which is **completely free** for learning and testing.

---

## Why AWS Free Tier?

- **Free for 12 months** - Perfect for learning
- **No credit card charges** if you stay within limits
- **More than enough** for this tutorial (S3, RDS, etc.)
- **Real AWS experience** - Not a simulation
- **750 hours/month** of RDS database (our main example)

**Estimated cost for this tutorial: $0.00**

---

## Prerequisites

Before you start, you need:
- A valid personal email address
- A phone number (for verification)
- A credit/debit card (for identity verification only - **you won't be charged**)

---

## Step 1: Create AWS Free Tier Account

### 1.1 Sign Up

1. Go to https://aws.amazon.com/free/
2. Click **"Create a Free Account"** or **"Create an AWS Account"**
3. Enter your email and choose a password
4. Choose an AWS account name (e.g., "crossplane-learning")

### 1.2 Contact Information

1. Account type: **Personal**
2. Fill in your personal details:
   - Full name
   - Phone number
   - Address

### 1.3 Payment Information

⚠️ **Important:** Your card will NOT be charged if you stay within Free Tier limits.

1. Enter your credit/debit card details
2. This is only for identity verification
3. AWS may place a temporary $1 authorization (refunded immediately)

### 1.4 Identity Verification

1. Choose verification method: **Text message (SMS)** or **Voice call**
2. Enter the verification code you receive
3. Complete the verification

### 1.5 Choose Support Plan

1. Select **"Basic Support - Free"**
2. Click **"Complete sign up"**

### 1.6 Wait for Activation

- Account activation can take a few minutes
- You'll receive a confirmation email
- Sign in to the AWS Console: https://console.aws.amazon.com/

✅ **You now have an AWS account!**

---

## 🔑 Step 2: Create IAM Access Keys

Crossplane needs programmatic access to AWS. We'll create credentials for this.

### 2.1 Access IAM Console

1. Sign in to AWS Console: https://console.aws.amazon.com/
2. In the search bar, type **"IAM"**
3. Click on **IAM (Identity and Access Management)**

### 2.2 Create a New User

1. In the left menu, click **"Users"**
2. Click **"Create user"**
3. Username: `crossplane-demo`
4. Click **"Next"**

### 2.3 Set Permissions

For this learning environment, we'll use admin access (⚠️ **only for learning!**):

1. Select **"Attach policies directly"**
2. In the search box, type: `AdministratorAccess`
3. Check the box next to **AdministratorAccess**
4. Click **"Next"**
5. Click **"Create user"**

### 2.4 Create Access Keys

1. Click on the user you just created: `crossplane-demo`
2. Go to the **"Security credentials"** tab
3. Scroll down to **"Access keys"**
4. Click **"Create access key"**
5. Select use case: **"Command Line Interface (CLI)"**
6. Check the confirmation box
7. Click **"Next"**
8. (Optional) Add a description: "Crossplane learning"
9. Click **"Create access key"**

### 2.5 Save Your Credentials

⚠️ **CRITICAL:** This is your only chance to see the Secret Access Key!

You'll see:
```
Access key ID: AKIAIOSFODNN7EXAMPLE
Secret access key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

**Save these credentials securely:**
1. Click **"Download .csv file"** (recommended)
2. Or copy both values to a secure location (password manager)
3. Click **"Done"**

✅ **You now have AWS credentials for Crossplane!**

---

## 🔒 Step 3: Security Best Practices

### 3.1 Enable Multi-Factor Authentication (MFA)

Protect your account with MFA:

1. Go to IAM → Dashboard
2. Click on your username (top right) → **"Security credentials"**
3. Scroll to **"Multi-factor authentication (MFA)"**
4. Click **"Assign MFA device"**
5. Choose **"Authenticator app"**
6. Use Google Authenticator, Authy, or similar app
7. Scan the QR code
8. Enter two consecutive MFA codes
9. Click **"Add MFA"**

### 3.2 Set Up Billing Alerts

Get notified if you exceed Free Tier:

1. Go to **Billing Dashboard**: https://console.aws.amazon.com/billing/
2. Click **"Budgets"** in the left menu
3. Click **"Create budget"**
4. Choose **"Use a template"**
5. Select **"Zero spend budget"**
6. Enter your email
7. Click **"Create budget"**

You'll receive an email if ANY charges occur (even $0.01).

---

## Step 4: Use Credentials with Crossplane (2 minutes)

### 4.1 When Running the Configure Script

When you run `./scripts/configure-aws.sh`, you'll be prompted:

```bash
AWS Access Key ID: [Paste your Access Key ID here]
AWS Secret Access Key: [Paste your Secret Access Key here]
```

### 4.2 Your Credentials Are Safe

- They're stored in a Kubernetes secret
- They never appear in code or git
- The `.gitignore` file protects them
- Only Crossplane can access them

---

## What's Included in Free Tier?

### For This Tutorial

**S3 (Simple Storage):**
- 5 GB of storage
- 20,000 GET requests
- 2,000 PUT requests
- **More than enough for examples**

**RDS (Database):**
- 750 hours/month of db.t3.micro (entire month!)
- 20 GB of SSD storage
- 20 GB of backup storage
- **Perfect for database composition example**

**EC2 (if you expand later):**
- 750 hours/month of t2.micro or t3.micro
- Linux or Windows

**Full details:** https://aws.amazon.com/free/

---

## Cost Protection

### Will I Be Charged?

**NO, if you:**
- ✅ Use only Free Tier eligible services (S3, RDS db.t3.micro)
- ✅ Stay within Free Tier limits (750 hours/month for RDS)
- ✅ Delete resources after testing
- ✅ Follow this tutorial's examples

**Estimated cost for this tutorial: $0.00**

### Even if You Exceed Free Tier

If you accidentally leave a small resource running:
- S3 bucket (empty): ~$0.023/month
- RDS db.t3.micro (24h): ~$0.41
- **Your billing alert will notify you**

### How to Avoid Any Charges

```bash
# After testing, delete all resources
kubectl delete -f examples/01-simple/s3-bucket.yaml
kubectl delete -f examples/02-database/claim.yaml

# Verify nothing is running
kubectl get managed
```

---

## 🌍 Alternatives to AWS

### If You Can't Use AWS

**Option 1: Azure Free Account**
- Similar Free Tier offering
- Follow Azure provider setup instead
- https://azure.microsoft.com/free/

**Option 2: GCP Free Tier**
- $300 credit for 90 days
- Always Free tier afterward
- https://cloud.google.com/free

---

## Troubleshooting

### "My account is not activated yet"

Wait 5-10 minutes. Check your email for confirmation. If it takes longer than 24 hours, contact AWS support.

### "I can't create IAM access keys"

Make sure you're signed in as the root user (not IAM user) to create the first IAM user with access keys.

### "I lost my Secret Access Key"

You cannot retrieve it. Delete the old access key and create a new one:
1. IAM → Users → crossplane-demo → Security credentials
2. Delete old access key
3. Create new access key
4. Save the new credentials

### "I'm getting charged"

1. Check AWS Billing Dashboard
2. Identify which service is charging
3. Delete the resource:
   ```bash
   kubectl get managed
   kubectl delete [resource-type] [resource-name]
   ```
4. Verify in AWS Console it's deleted

---

## Ready to Go!

You now have:
- AWS Free Tier account
- IAM credentials for Crossplane
- MFA enabled (security)
- Billing alerts configured
- Understanding of costs (zero!)

**Next step:** Return to the main README and continue with the Quick Start!

---

## 📚 Additional Resources

- [AWS Free Tier](https://aws.amazon.com/free/)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS Billing and Cost Management](https://docs.aws.amazon.com/awsaccountbilling/)
- [Crossplane AWS Provider](https://marketplace.upbound.io/providers/upbound/provider-aws)