locals {
  prefix = "cds"
  common_tags = {
    Terraform  = "true"
    CostCentre = var.billing_code
  }
}

module "vpc" {
  source = "github.com/cds-snc/terraform-modules//vpc?ref=v10.4.6"
  name   = "n8n-space-${var.env}"

  enable_flow_log                  = true
  availability_zones               = 2
  cidrsubnet_newbits               = 8
  single_nat_gateway               = true
  allow_https_request_out          = true
  allow_https_request_out_response = true
  allow_https_request_in           = true
  allow_https_request_in_response  = true

  billing_tag_value = var.billing_code
}

#
# Security groups
#

# ECS
resource "aws_security_group" "n8n_ecs" {
  description = "NSG for n8n ECS Tasks"
  name        = "n8n_ecs"
  vpc_id      = module.vpc.vpc_id
  tags        = local.common_tags
}

resource "aws_security_group_rule" "n8n_ecs_egress_all" {
  type              = "egress"
  protocol          = "-1"
  to_port           = 0
  from_port         = 0
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.n8n_ecs.id
}

resource "aws_security_group_rule" "n8n_ecs_ingress_lb" {
  description              = "Ingress from load balancer to n8n ECS task"
  type                     = "ingress"
  from_port                = 5678
  to_port                  = 5678
  protocol                 = "tcp"
  security_group_id        = aws_security_group.n8n_ecs.id
  source_security_group_id = aws_security_group.n8n_lb.id
}

# Load balancer
resource "aws_security_group" "n8n_lb" {
  name        = "n8n_lb"
  description = "NSG for n8n load balancer"
  vpc_id      = module.vpc.vpc_id
  tags        = local.common_tags
}

resource "aws_security_group_rule" "n8n_lb_ingress_internet_https" {
  description       = "Ingress from internet to load balancer (HTTPS)"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.n8n_lb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "n8n_lb_egress_ecs" {
  description              = "Egress from load balancer to n8n ECS task"
  type                     = "egress"
  from_port                = 5678
  to_port                  = 5678
  protocol                 = "tcp"
  security_group_id        = aws_security_group.n8n_lb.id
  source_security_group_id = aws_security_group.n8n_ecs.id
}

# Database
resource "aws_security_group" "n8n_db" {
  name        = "n8n_db"
  description = "NSG for n8n database"
  vpc_id      = module.vpc.vpc_id
  tags        = local.common_tags
}

resource "aws_security_group_rule" "n8n_db_ingress_ecs" {
  description              = "Ingress from n8n ECS task to database"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.n8n_db.id
  source_security_group_id = aws_security_group.n8n_ecs.id
}

# EFS
resource "aws_security_group" "n8n_efs" {
  name        = "n8n_efs"
  description = "Allow access to EFS from n8n ECS tasks"
  vpc_id      = module.vpc.vpc_id
  tags        = local.common_tags
}

resource "aws_security_group_rule" "n8n_efs_ingress_ecs" {
  description              = "Allow NFS traffic from n8n ECS tasks"
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.n8n_efs.id
  source_security_group_id = aws_security_group.n8n_ecs.id
}