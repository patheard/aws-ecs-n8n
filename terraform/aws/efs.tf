resource "aws_efs_file_system" "n8n" {
  encrypted = true
  tags      = local.common_tags
}

resource "aws_efs_file_system_policy" "n8n" {
  file_system_id = aws_efs_file_system.n8n.id
  policy         = data.aws_iam_policy_document.efs_access_point_secure.json
}

data "aws_iam_policy_document" "efs_access_point_secure" {
  statement {
    sid    = "AllowAccessThroughAccessPoint"
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
    ]
    resources = [aws_efs_file_system.n8n.arn]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values = [
        aws_efs_access_point.n8n.arn
      ]
    }
  }

  statement {
    sid       = "DenyNonSecureTransport"
    effect    = "Deny"
    actions   = ["*"]
    resources = [aws_efs_file_system.n8n.arn]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
}

resource "aws_efs_backup_policy" "n8n" {
  file_system_id = aws_efs_file_system.n8n.id
  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_efs_mount_target" "n8n" {
  for_each = toset(module.vpc.private_subnet_ids)

  file_system_id = aws_efs_file_system.n8n.id
  subnet_id      = each.value
  security_groups = [
    aws_security_group.n8n_efs.id
  ]
}

resource "aws_efs_access_point" "n8n" {
  file_system_id = aws_efs_file_system.n8n.id
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    path = "/n8n"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 775
    }
  }
  tags = local.common_tags
}
