# PostgreSQL on GCP with Terraform and GitHub Actions

This repository contains a complete infrastructure-as-code solution for deploying PostgreSQL on Google Cloud Platform (GCP) using Terraform, with automated CI/CD deployment via GitHub Actions.

## 📋 Features

- **Infrastructure as Code**: Complete Terraform configuration for PostgreSQL deployment
- **High Availability**: Optional REGIONAL setup with automatic failover
- **Security**: 
  - Private networking with VPC
  - Secret Manager integration for password storage
  - IAM authentication support
  - SSL/TLS ready configuration
- **Automated Backups**: Point-in-time recovery (PITR) enabled
- **Performance Monitoring**: Query Insights enabled by default
- **CI/CD Pipeline**: Automated deployment via GitHub Actions
- **Testing**: Automated database connection testing
- **Notifications**: Slack integration for deployment status
- **Scalability**: Auto-resizing disk support

## 🗂️ Project Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy-postgres.yml      # GitHub Actions CI/CD pipeline
├── terraform/
│   ├── main.tf                      # Primary Terraform configuration
│   ├── variables.tf                 # Variable definitions
│   ├── outputs.tf                   # Output definitions
│   ├── terraform.tfvars             # Default values (rename and customize)
│   └── .gitignore                   # Git ignore for Terraform files
├── SETUP.md                         # Detailed setup instructions
├── README.md                        # This file
└── scripts/
    ├── setup-gcp.sh                 # GCP setup automation
    └── destroy.sh                   # Infrastructure cleanup
```

## 🚀 Quick Start

### 1. Prerequisites

- Terraform >= 1.0
- Google Cloud SDK
- PostgreSQL Client (optional, for testing)
- GitHub account with repository access

### 2. Initial Setup

Follow the detailed setup instructions in [SETUP.md](./SETUP.md):

```bash
# Clone repository
git clone <your-repo-url>
cd gcp-postgres

# Set up GCP service account
bash scripts/setup-gcp.sh

# Configure GitHub secrets
# (See SETUP.md for instructions)
```

### 3. Local Deployment

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply configuration
terraform apply
```

### 4. GitHub Actions Deployment

1. Push to `main` branch
2. GitHub Actions automatically:
   - Validates Terraform configuration
   - Creates a plan
   - Applies on main branch
   - Tests database connection
   - Sends Slack notification

## 📝 Configuration

### Basic Configuration (terraform.tfvars)

```hcl
# GCP Configuration
gcp_project_id = "your-project-id"
gcp_region     = "us-central1"

# PostgreSQL Configuration
instance_name    = "my-postgres"
postgres_version = "POSTGRES_15"
machine_type     = "db-f1-micro"
availability_type = "REGIONAL"  # or "ZONAL"

# Storage
disk_size       = 20      # GB
disk_autoresize = true

# Network
network_cidr    = "10.0.0.0/24"
enable_public_ip = false  # Keep private for security

# Backups
enable_backups  = true
enable_pitr     = true

# Monitoring
enable_query_insights = true
```

### Advanced Configuration

See [variables.tf](./terraform/variables.tf) for all available options including:
- Database flags customization
- Backup schedules
- Maintenance windows
- Public network access (if needed)

## 📊 Architecture

```
┌─────────────────────────────────────────────┐
│         GCP Project                         │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  VPC Network (10.0.0.0/24)           │  │
│  │                                      │  │
│  │  ┌────────────────────────────────┐ │  │
│  │  │  Subnet (10.0.0.0/24)          │ │  │
│  │  │                                │ │  │
│  │  │  ┌──────────────────────────┐ │ │  │
│  │  │  │  Cloud SQL PostgreSQL    │ │ │  │
│  │  │  │  - Private IP only       │ │ │  │
│  │  │  │  - REGIONAL HA setup     │ │ │  │
│  │  │  │  - Automated backups     │ │ │  │
│  │  │  │  - Query Insights        │ │ │  │
│  │  │  └──────────────────────────┘ │ │  │
│  │  │                                │ │  │
│  │  └────────────────────────────────┘ │  │
│  │                                      │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  Secret Manager                      │  │
│  │  - Database Password                 │  │
│  └──────────────────────────────────────┘  │
│                                             │
└─────────────────────────────────────────────┘
```

## 🔗 GitHub Actions Workflow

### Workflow Stages

1. **terraform-plan** (on PR and push):
   - Checkout code
   - Setup Terraform
   - Authenticate to GCP
   - Validate configuration
   - Create terraform plan
   - Comment plan on PR

2. **terraform-apply** (on main push only):
   - Apply Terraform changes
   - Save outputs
   - Upload to artifacts

3. **test-connection** (after apply):
   - Download Terraform outputs
   - Install PostgreSQL client
   - Test database connectivity
   - Verify database is operational

4. **notify** (always):
   - Send Slack notification with status

## 📤 Outputs

After deployment, Terraform provides:

- `instance_name`: Cloud SQL instance name
- `instance_connection_name`: Connection string for Cloud SQL Proxy
- `private_ip_address`: Private IP of PostgreSQL instance
- `public_ip_address`: Public IP (if enabled)
- `database_name`: Default database name
- `database_username`: Database admin username
- `database_password`: Database password (sensitive)
- `database_password_secret`: Secret Manager secret ID
- `connection_string`: Full PostgreSQL connection string
- `vpc_network_id`: VPC network ID
- `vpc_subnet_id`: Subnet ID

View outputs:
```bash
terraform output
```

Get specific output:
```bash
terraform output instance_connection_name
```

## 🔐 Security

### Key Security Features

1. **Private Networking**: PostgreSQL only accessible via private VPC
2. **Secret Management**: Passwords stored in Google Secret Manager
3. **IAM Authentication**: Optional Cloud SQL IAM database authentication
4. **Encryption**: Data encrypted at rest and in transit
5. **Backups**: Automated daily backups with point-in-time recovery
6. **Network Policies**: Firewall rules restrict access

### Connecting Securely

From a VM in the same VPC:
```bash
psql -h PRIVATE_IP -U postgres -d postgres
```

From outside VPC (using Cloud SQL Proxy):
```bash
# Set up proxy in background
cloud_sql_proxy -instances=PROJECT:REGION:INSTANCE &

# Connect via localhost
psql -h 127.0.0.1 -U postgres -d postgres
```

## 🔄 Maintenance

### Common Operations

**Get database password:**
```bash
gcloud secrets versions access latest \
  --secret="my-postgres-db-password"
```

**Connect to database:**
```bash
gcloud sql connect my-postgres-xxxxx \
  --user=postgres
```

**Create backup:**
```bash
gcloud sql backups create \
  --instance=my-postgres-xxxxx
```

**View recent backups:**
```bash
gcloud sql backups list \
  --instance=my-postgres-xxxxx
```

## 🗑️ Cleanup

### Destroy Infrastructure

```bash
cd terraform

# Show what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Or use the provided script
bash ../scripts/destroy.sh
```

⚠️ **Warning**: This will delete the PostgreSQL instance and associated data.

## 🐛 Troubleshooting

### Issue: Terraform apply fails with permission error

**Solution**: Ensure the service account has required IAM roles:
```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member=serviceAccount:SA_EMAIL \
  --role=roles/cloudsql.admin
```

### Issue: Cannot connect to database

**Possible causes**:
1. Not connected to VPC or not using Cloud SQL Proxy
2. Firewall rules blocking access
3. Database instance still initializing
4. Wrong credentials

**Solution**: Check network configuration and firewall rules

### Issue: GitHub Actions failing with authentication error

**Solution**: Verify GitHub secrets are set correctly:
```bash
# Test locally first
gcloud auth activate-service-account --key-file=terraform-key.json
gcloud sql instances list --project=YOUR_PROJECT_ID
```

## 📚 Additional Resources

- [Terraform Google Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Google Cloud SQL Documentation](https://cloud.google.com/sql/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## 📄 License

This project is provided as-is for educational and deployment purposes.

## 🤝 Support

For issues or questions:
1. Check [SETUP.md](./SETUP.md) for detailed setup instructions
2. Review GitHub Actions logs
3. Check GCP Cloud SQL instance details in the console
4. Enable Terraform debug logging: `TF_LOG=DEBUG terraform apply`

## 📝 Changelog

### v1.0 (Initial Release)
- Complete Terraform configuration for PostgreSQL on GCP
- GitHub Actions CI/CD pipeline
- Security best practices implemented
- Automated testing and notifications
- Comprehensive documentation

---

**Last Updated**: November 2025
