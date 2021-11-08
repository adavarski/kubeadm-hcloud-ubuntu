# These are the settings used for production deployments
# Please set secrets as environment variables (TF_VAR_nameofvar) or in terraform.tfvars file.
# IMPORTANT: Do not include any secrets in here!

hcloud_token = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCqFdiPMnTznEllqgARCXMfAtcv24GCV8rvPg6vpvG+6CHJGkP7cRbTtywgV6/fHRQkgz9htj2R0BncDhvfjTNFyUG0Jf5bdQyK38FKs+W/7ZoSgl6w/zsgc2hoguaPYRYQOcYwHVZ2bmRtjXSrspRv1+B8a0MjqfyfK1wRAdCcxF5R53kfwOzDFFoW0LJ6JCBpIHjsyGAioFaWHt7TIca2tTUuZprR+OpDn6hCazsU6DjzcRfD0kzPBAiJBmUlzx4eDAZLYB3AASKx5EY3Q9lw44OM5s82QjSqQUxQhRAHSlBmPdc2hkQPbhy9LhC0rf8nCUJ681tWMJqbtP9EmKa7 davar@carbon"

ssh_private_key_path = "~/.ssh/hcloud"

ssh_public_key_path = "~/.ssh/hcloud.pub"

# Hetzner variables
master_type  = "cpx11"
master_count = 1
node_type    = "cx21"
node_count   = 2

# Kubernetes variables
kubernetes_version = "1.20.2"
