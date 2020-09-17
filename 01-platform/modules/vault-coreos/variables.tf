
variable "trusted_principals" {
  type        = set(string)
  description = "AWS accounts or roles that can assume the Vault server role"
  default     = []
}

variable "trusted_services" {
  type        = set(string)
  description = "AWS services to allow the Vault server role to be assumed from"
  default     = []
}

variable "table_name" {
  type        = string
  description = "DynamoDB table to use as Vault's storage backend (https://www.vaultproject.io/docs/configuration/storage/dynamodb.html)"
  default     = "vault-data"
}

variable "read_capacity" {
  type        = number
  description = "Provisioned read capacity units for Vault storage table"
  default     = 5
}

variable "write_capacity" {
  type        = number
  description = "Provisioned write capacity units for Vault storage table"
  default     = 5
}

variable "vpc_id" {
  type = string
}

variable "client_ingress_cidrs" {
  type    = set(string)
  default = []
}

variable "name" {
  type = string
}

variable "subnet_ids" {
  type = set(string)
}

variable "cert_validity_period_hours" {
  default = "8760"
}

variable "cert_organization" {
  type = string
}

variable "server_port" {
  default = "8200"
}

variable "ssh_ingress_cidrs" {
  type = set(string)
  default = []
}

variable "peer_ingress_cidrs" {
  type = set(string)
  default = []
}

variable "cluster_port" {
  default = "8201"
}

variable "server_count" {
  default = 3
}

variable "instance_type" {
  default = "t3.medium"
}

variable "ssh_user" {
  default = "user"
}

variable "vault_version" {
  default = "1.3.2"
}

variable "s3_authorized_keys_bucket_path" {}

variable "hosted_zone" {}

variable "is_public" {
  type        = bool
  description = "Whether or not the load balancer is public"
  default     = false
}
