#!/bin/bash

# Setup script for GCP PostgreSQL Terraform deployment
# This script automates the setup of service accounts, IAM roles, and initial configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI is not installed. Please install it from https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    
    if ! command -v terraform &> /dev/null; then
        log_warn "Terraform is not installed. Please install it from https://www.terraform.io/downloads"
    fi
    
    log_info "Prerequisites check passed!"
}

# Get or confirm GCP project
setup_gcp_project() {
    log_info "Setting up GCP project..."
    
    # Try to get current project
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
    
    if [ -z "$CURRENT_PROJECT" ]; then
        log_error "No GCP project configured. Run: gcloud init"
        exit 1
    fi
    
    read -p "Use GCP project '$CURRENT_PROJECT'? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter GCP project ID: " CURRENT_PROJECT
        gcloud config set project $CURRENT_PROJECT
    fi
    
    GCP_PROJECT_ID=$CURRENT_PROJECT
    log_info "Using project: $GCP_PROJECT_ID"
}

# Enable required APIs
enable_apis() {
    log_info "Enabling required GCP APIs..."
    
    APIS=(
        "sqladmin.googleapis.com"
        "servicenetworking.googleapis.com"
        "secretmanager.googleapis.com"
        "compute.googleapis.com"
    )
    
    for api in "${APIS[@]}"; do
        log_info "Enabling $api..."
        gcloud services enable $api --project=$GCP_PROJECT_ID
    done
    
    log_info "All APIs enabled successfully!"
}

# Create service account
create_service_account() {
    log_info "Creating service account for Terraform..."
    
    SA_NAME="terraform-postgres"
    SA_DISPLAY_NAME="Terraform PostgreSQL Deployment"
    
    # Check if service account already exists
    if gcloud iam service-accounts describe ${SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com \
        --project=$GCP_PROJECT_ID &>/dev/null; then
        log_warn "Service account already exists: ${SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
        SA_EMAIL="${SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
    else
        log_info "Creating new service account..."
        gcloud iam service-accounts create $SA_NAME \
            --display-name="$SA_DISPLAY_NAME" \
            --project=$GCP_PROJECT_ID
        
        SA_EMAIL="${SA_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
        log_info "Service account created: $SA_EMAIL"
    fi
    
    echo $SA_EMAIL
}

# Grant IAM roles to service account
grant_iam_roles() {
    local SA_EMAIL=$1
    log_info "Granting IAM roles to service account..."
    
    ROLES=(
        "roles/cloudsql.admin"
        "roles/compute.networkAdmin"
        "roles/secretmanager.admin"
        "roles/iam.serviceAccountUser"
    )
    
    for role in "${ROLES[@]}"; do
        log_info "Granting $role..."
        gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
            --member=serviceAccount:$SA_EMAIL \
            --role=$role \
            --condition=None \
            --project=$GCP_PROJECT_ID 2>/dev/null || true
    done
    
    log_info "All IAM roles granted!"
}

# Create service account key
create_service_account_key() {
    local SA_EMAIL=$1
    log_info "Creating service account key..."
    
    KEY_FILE="terraform-key.json"
    
    if [ -f "$KEY_FILE" ]; then
        read -p "Key file already exists. Overwrite? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_warn "Skipping key creation"
            return
        fi
    fi
    
    gcloud iam service-accounts keys create $KEY_FILE \
        --iam-account=$SA_EMAIL \
        --project=$GCP_PROJECT_ID
    
    log_info "Service account key created: $KEY_FILE"
    log_warn "⚠️  Keep this file secure! It contains sensitive credentials."
}

# Create GCS bucket for Terraform state
create_state_bucket() {
    log_info "Setting up Terraform state bucket..."
    
    BUCKET_NAME="${GCP_PROJECT_ID}-terraform-state"
    
    if gsutil ls -b gs://$BUCKET_NAME &>/dev/null; then
        log_warn "Bucket already exists: gs://$BUCKET_NAME"
    else
        log_info "Creating GCS bucket: gs://$BUCKET_NAME"
        gsutil mb -p $GCP_PROJECT_ID gs://$BUCKET_NAME
        
        log_info "Enabling versioning..."
        gsutil versioning set on gs://$BUCKET_NAME
        
        log_info "Setting bucket lifecycle policy..."
        cat > /tmp/lifecycle.json << EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {"numNewerVersions": 10}
      }
    ]
  }
}
EOF
        gsutil lifecycle set /tmp/lifecycle.json gs://$BUCKET_NAME
        rm /tmp/lifecycle.json
    fi
    
    log_info "State bucket setup complete: gs://$BUCKET_NAME"
}

# Create terraform directory and initialize
init_terraform() {
    log_info "Initializing Terraform..."
    
    if [ ! -d "terraform" ]; then
        mkdir -p terraform
        log_info "Created terraform directory"
    fi
    
    cd terraform
    
    if [ ! -f ".terraform.lock.hcl" ]; then
        terraform init
    fi
    
    cd ..
    log_info "Terraform initialized!"
}

# Display summary
display_summary() {
    log_info "Setup complete! 🎉"
    echo ""
    echo "============================================"
    echo "Setup Summary"
    echo "============================================"
    echo "Project ID:        $GCP_PROJECT_ID"
    echo "Service Account:   $SA_EMAIL"
    echo "State Bucket:      gs://${GCP_PROJECT_ID}-terraform-state"
    echo "Key File:          terraform-key.json"
    echo ""
    echo "Next steps:"
    echo "1. Add to GitHub Secrets:"
    echo "   - GCP_SA_KEY: $(cat terraform-key.json | base64 | head -c 50)..."
    echo "   - GCP_PROJECT_ID: $GCP_PROJECT_ID"
    echo ""
    echo "2. Update terraform.tfvars with your settings"
    echo ""
    echo "3. Run: terraform plan -chdir=terraform"
    echo ""
    echo "============================================"
}

# Main execution
main() {
    log_info "Starting GCP PostgreSQL Terraform setup..."
    echo ""
    
    check_prerequisites
    setup_gcp_project
    enable_apis
    
    SA_EMAIL=$(create_service_account)
    grant_iam_roles $SA_EMAIL
    create_service_account_key $SA_EMAIL
    create_state_bucket
    init_terraform
    
    display_summary
}

# Run main function
main
