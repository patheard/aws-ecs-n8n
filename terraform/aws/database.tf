#
# RDS Postgress cluster
#
module "n8n_db" {
  source = "github.com/cds-snc/terraform-modules//rds?ref=v10.4.6"
  name   = "n8n-${var.env}"

  database_name  = "n8n"
  engine         = "aurora-postgresql"
  engine_version = "15.10"
  instances      = var.n8n_database_instances_count
  instance_class = var.n8n_database_instance_class
  username       = var.n8n_database_username
  password       = var.n8n_database_password
  use_proxy      = false

  backup_retention_period      = 14
  preferred_backup_window      = "02:00-04:00"
  performance_insights_enabled = false

  cloudwatch_log_exports_retention_in_days = 7

  serverless_min_capacity = var.n8n_database_min_capacity
  serverless_max_capacity = var.n8n_database_max_capacity

  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.n8n_db.id]

  billing_tag_value = var.billing_code
}

resource "aws_ssm_parameter" "n8n_database_host" {
  name  = "n8n_database_host"
  type  = "SecureString"
  value = module.n8n_db.rds_cluster_endpoint
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "n8n_database_username" {
  name  = "n8n_database_username"
  type  = "SecureString"
  value = var.n8n_database_username
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "n8n_database_password" {
  name  = "n8n_database_password"
  type  = "SecureString"
  value = var.n8n_database_password
  tags  = local.common_tags
}
