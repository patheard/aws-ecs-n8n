resource "aws_route53_zone" "n8n" {
  name = var.domain
  tags = local.common_tags
}

resource "aws_route53_record" "n8n_A" {
  zone_id = aws_route53_zone.n8n.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_lb.n8n.dns_name
    zone_id                = aws_lb.n8n.zone_id
    evaluate_target_health = false
  }
}
