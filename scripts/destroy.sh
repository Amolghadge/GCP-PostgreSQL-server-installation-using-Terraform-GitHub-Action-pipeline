#!/bin/bash

# Destroy script for GCP PostgreSQL Terraform deployment
# This script safely destroys all infrastructure

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

# Confirm destruction
confirm_destroy() {
    echo ""
    log_warn "⚠️  WARNING: This will destroy ALL PostgreSQL infrastructure!"
    echo ""
    echo "Resources that will be destroyed:"
    echo "  - Cloud SQL PostgreSQL instance"
    echo "  - VPC network and subnet"
    echo "  - Secret Manager secret"
    echo "  - Firewall rules"
    echo ""
    
    read -p "Are you SURE you want to proceed? Type 'destroy' to confirm: " confirmation
    
    if [ "$confirmation" != "destroy" ]; then
        log_info "Destruction cancelled"
        exit 0
    fi
}

# Perform destruction
destroy_infrastructure() {
    log_info "Destroying infrastructure..."
    
    if [ ! -d "terraform" ]; then
        log_error "terraform directory not found"
        exit 1
    fi
    
    cd terraform
    
    if [ ! -f ".terraform/terraform.tfstate" ] && [ ! -f "terraform.tfstate" ]; then
        log_error "No Terraform state found. Nothing to destroy."
        cd ..
        exit 1
    fi
    
    # Show what will be destroyed
    log_info "Planning destruction..."
    terraform plan -destroy -out=destroy.plan
    
    # Confirm one more time
    read -p "Proceed with destruction? (type 'yes' to confirm): " final_confirm
    
    if [ "$final_confirm" != "yes" ]; then
        log_info "Destruction cancelled"
        rm -f destroy.plan
        cd ..
        exit 0
    fi
    
    # Apply destruction
    log_info "Destroying resources... This may take several minutes."
    terraform apply destroy.plan
    
    log_info "Deletion complete!"
    cd ..
}

# Cleanup local files
cleanup_local_files() {
    read -p "Remove local terraform state files? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleaning up local files..."
        
        rm -f terraform/.terraform.lock.hcl
        rm -rf terraform/.terraform
        rm -f terraform/destroy.plan
        rm -f terraform/tfplan
        
        log_info "Local files cleaned up"
    fi
}

# Main execution
main() {
    log_warn "PostgreSQL Infrastructure Destruction Script"
    echo ""
    
    confirm_destroy
    destroy_infrastructure
    cleanup_local_files
    
    log_info "Destruction complete! ✓"
}

# Run main function
main
