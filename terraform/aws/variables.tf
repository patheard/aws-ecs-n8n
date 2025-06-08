variable "domain" {
  description = "The domain name for n8n."
  type        = string
}

variable "n8n_encryption_key" {
  description = "n8n's encryption key for securing credentials."
  type        = string
  sensitive   = true
}

variable "env" {
  description = "Environment name (e.g. prod, staging)."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
  default     = "ca-central-1"
}

variable "account_id" {
  description = "AWS account ID."
  type        = string
}

variable "billing_code" {
  description = "Billing code tag value."
  type        = string
}

variable "n8n_database_instances_count" {
  description = "The number of instances in the database cluster."
  type        = number
}

variable "n8n_database_instance_class" {
  description = "The instance class to use for the database."
  type        = string
}

variable "n8n_database_max_capacity" {
  description = "The maximum capacity for the serverless database."
  type        = number
}

variable "n8n_database_min_capacity" {
  description = "The minimum capacity for the serverless database."
  type        = number
}

variable "n8n_database_username" {
  description = "The username to use for the database."
  type        = string
  sensitive   = true
}

variable "n8n_database_password" {
  description = "The password to use for the database."
  type        = string
  sensitive   = true
}

variable "n8n_smtp_pass" {
  description = "SMTP password for n8n."
  type        = string
  sensitive   = true
}

variable "n8n_smtp_user" {
  description = "SMTP user for n8n."
  type        = string
  sensitive   = true
}

variable "product_name" {
  description = "(Required) The name of the product you are deploying."
  type        = string
}