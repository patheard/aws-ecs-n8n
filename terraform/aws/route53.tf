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

# SES domain validation
resource "aws_route53_record" "n8n_ses_verification_TXT" {
  zone_id = aws_route53_zone.n8n.zone_id
  name    = "_amazonses.${aws_ses_domain_identity.n8n.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.n8n.verification_token]
}

# Email sending
resource "aws_route53_record" "n8n_spf_TXT" {
  zone_id = aws_route53_zone.n8n.zone_id
  name    = var.domain
  type    = "TXT"
  ttl     = "300"
  records = [
    "v=spf1 include:amazonses.com -all"
  ]
}

resource "aws_route53_record" "n8n_dkim_CNAME" {
  count   = 3
  zone_id = aws_route53_zone.n8n.zone_id
  name    = "${element(aws_ses_domain_dkim.n8n.dkim_tokens, count.index)}._domainkey.${var.domain}"
  type    = "CNAME"
  ttl     = "300"
  records = [
    "${element(aws_ses_domain_dkim.n8n.dkim_tokens, count.index)}.dkim.amazonses.com",
  ]
}

resource "aws_route53_record" "n8n_dmarc_TXT" {
  zone_id = aws_route53_zone.n8n.zone_id
  name    = "_dmarc.${var.domain}"
  type    = "TXT"
  ttl     = "300"
  records = [
    "v=DMARC1; p=reject; sp=reject; pct=100; rua=mailto:CDS.SECURITY-SECURITE.SNC@servicecanada.gc.ca"
  ]
}
