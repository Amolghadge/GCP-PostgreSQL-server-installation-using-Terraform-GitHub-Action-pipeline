# If you get "Secret already exists" error, import the existing secret using this command:
# 
# terraform import google_secret_manager_secret.db_password_secret my-postgres-db-password
#
# This will import the existing secret into your Terraform state without trying to recreate it.
# After importing, run: terraform apply
#
# To check if the secret needs to be imported:
# terraform plan | grep -i "secret"
# If you see "will be created", you need to import first.

# To import the secret:
# cd terraform
# terraform import google_secret_manager_secret.db_password_secret my-postgres-db-password
# terraform apply
