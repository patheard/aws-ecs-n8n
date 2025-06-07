#
# Load balancer WAF ACL
#
resource "aws_wafv2_web_acl" "n8n" {
  name  = "n8n_lb"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "InvalidHost"
    priority = 1

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          byte_match_statement {
            field_to_match {
              single_header {
                name = "host"
              }
            }
            text_transformation {
              priority = 1
              type     = "COMPRESS_WHITE_SPACE"
            }
            text_transformation {
              priority = 2
              type     = "LOWERCASE"
            }
            positional_constraint = "EXACTLY"
            search_string         = var.domain
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "InvalidHost"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "CanadaOnlyGeoRestriction"
    priority = 5

    action {
      block {
        custom_response {
          response_code = 403
          response_header {
            name  = "waf-block"
            value = "CanadaOnlyGeoRestriction"
          }
        }
      }
    }

    statement {
      not_statement {
        statement {
          geo_match_statement {
            country_codes = ["CA"]
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CanadaOnlyGeoRestriction"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimitersRuleGroup"
    priority = 20

    override_action {
      none {}
    }

    statement {
      rule_group_reference_statement {
        arn = aws_wafv2_rule_group.rate_limiters_group.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate_limiters_rule_group"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 30
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesLinuxRuleSet"
    priority = 40
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesLinuxRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 50

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "n8n"
    sampled_requests_enabled   = true
  }

  tags = local.common_tags
}

resource "aws_wafv2_rule_group" "rate_limiters_group" {
  capacity = 32
  name     = "RateLimitersGroup"
  scope    = "REGIONAL"

  rule {
    name     = "BlanketRequestLimit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"

      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlanketRequestLimit"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "PostRequestLimit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 200
        aggregate_key_type = "IP"
        scope_down_statement {
          regex_match_statement {
            field_to_match {
              method {}
            }
            regex_string = "^(put|post)$"
            text_transformation {
              priority = 1
              type     = "LOWERCASE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "PostRequestRateLimit"
      sampled_requests_enabled   = true
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "RateLimitersGroup"
    sampled_requests_enabled   = false
  }

  tags = local.common_tags
}

resource "aws_wafv2_web_acl_association" "n8n" {
  resource_arn = aws_lb.n8n.arn
  web_acl_arn  = aws_wafv2_web_acl.n8n.arn
}
