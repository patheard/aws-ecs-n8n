resource "aws_acm_certificate" "n8n" {
  domain_name               = var.domain
  subject_alternative_names = ["*.${var.domain}"]
  validation_method         = "DNS"

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "n8n_validation" {
  zone_id = aws_route53_zone.n8n.zone_id

  for_each = {
    for dvo in aws_acm_certificate.n8n.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
  ttl             = 60
}

resource "aws_acm_certificate_validation" "n8n" {
  certificate_arn         = aws_acm_certificate.n8n.arn
  validation_record_fqdns = [for record in aws_route53_record.n8n_validation : record.fqdn]
}
