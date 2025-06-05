locals {
  container_env = [
    {
      "name"  = "N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS"
      "value" = "true"
    },
    {
      "name"  = "N8N_RUNNERS_ENABLED"
      "value" = "true"
    },
    {
      "name"  = "N8N_HOST"
      "value" = var.domain
    },
    {
      "name"  = "N8N_PORT"
      "value" = "5678"
    },
    {
      "name"  = "N8N_PROTOCOL"
      "value" = "http"
    },
    {
      "name"  = "NODE_ENV"
      "value" = "production"
    },
    {
      "name"  = "WEBHOOK_URL"
      "value" = "https://${var.domain}/"
    },
    {
      "name"  = "N8N_DIAGNOSTICS_ENABLED"
      "value" = "false"
    },
    {
      "name"  = "N8N_HIDE_USAGE_PAGE"
      "value" = "true"
    },
    {
      "name"  = "N8N_HIRING_BANNER_ENABLED"
      "value" = "false"
    },
    {
      "name"  = "N8N_PERSONALIZATION_ENABLED"
      "value" = "false"
    },
    {
      "name"  = "DB_TYPE"
      "value" = "postgresdb"
    },
    {
      "name"  = "DB_POSTGRESDB_PORT"
      "value" = "5432"
    },
    {
      "name"  = "DB_POSTGRESDB_DATABASE"
      "value" = "n8n"
    },
    {
      "name"  = "DB_POSTGRESDB_SSL_ENABLED"
      "value" = "true"
    }
  ]
  container_secrets = [
    {
      "name"      = "N8N_ENCRYPTION_KEY"
      "valueFrom" = aws_ssm_parameter.n8n_encryption_key.arn
    },
    {
      "name"      = "DB_POSTGRESDB_USER"
      "valueFrom" = aws_ssm_parameter.n8n_database_username.arn
    },
    {
      "name"      = "DB_POSTGRESDB_PASSWORD"
      "valueFrom" = aws_ssm_parameter.n8n_database_password.arn
    },
    {
      "name"      = "DB_POSTGRESDB_HOST"
      "valueFrom" = aws_ssm_parameter.n8n_database_host.arn
    },
  ]
}

module "n8n_ecs" {
  source = "github.com/cds-snc/terraform-modules//ecs?ref=v10.4.6"

  cluster_name = "n8n"
  service_name = "n8n"
  task_cpu     = 2048
  task_memory  = 4096

  service_use_latest_task_def = true

  # Scaling
  enable_autoscaling       = true
  desired_count            = 1
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 2

  # Task definition
  container_image                     = "n8nio/n8n:1.97.0"
  container_host_port                 = 5678
  container_port                      = 5678
  container_environment               = local.container_env
  container_secrets                   = local.container_secrets
  container_read_only_root_filesystem = false

  task_exec_role_policy_documents = [
    data.aws_iam_policy_document.ecs_task_ssm_parameters.json
  ]

  task_role_policy_documents = [
    data.aws_iam_policy_document.efs_mount.json
  ]


  container_mount_points = [{
    sourceVolume  = "n8n-data"
    containerPath = "/home/node/.n8n"
    readOnly      = false
  }]

  task_volume = [{
    name = "n8n-data"
    efs_volume_configuration = {
      file_system_id          = aws_efs_file_system.n8n.id
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2049
      authorization_config = {
        access_point_id = aws_efs_access_point.n8n.id
        iam             = "ENABLED"
      }
    }
  }]

  # Networking
  lb_target_group_arn = aws_lb_target_group.n8n.arn
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.n8n_ecs.id]

  billing_tag_value = var.billing_code
}

#
# IAM policies
#
data "aws_iam_policy_document" "ecs_task_ssm_parameters" {
  statement {
    sid    = "GetSSMParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      aws_ssm_parameter.n8n_encryption_key.arn,
      aws_ssm_parameter.n8n_database_host.arn,
      aws_ssm_parameter.n8n_database_username.arn,
      aws_ssm_parameter.n8n_database_password.arn,
    ]
  }
}

data "aws_iam_policy_document" "efs_mount" {
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:DescribeMountTargets",
    ]
    resources = [
      aws_efs_file_system.n8n.arn
    ]
  }
}

#
# SSM parameters
#
resource "aws_ssm_parameter" "n8n_encryption_key" {
  name  = "n8n_encryption_key"
  type  = "SecureString"
  value = var.n8n_encryption_key
  tags  = local.common_tags
}
