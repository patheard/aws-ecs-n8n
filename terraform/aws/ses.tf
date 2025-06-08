#
# Send email using a SES SMTP server
#
resource "aws_ses_domain_identity" "n8n" {
  domain = var.domain
}

resource "aws_ses_domain_dkim" "n8n" {
  domain = aws_ses_domain_identity.n8n.domain
}

resource "aws_ses_domain_identity_verification" "n8n" {
  domain     = aws_ses_domain_identity.n8n.id
  depends_on = [aws_route53_record.n8n_ses_verification_TXT]
}

resource "aws_iam_user" "n8n_send_email" {
  # checkov:skip=CKV_AWS_273: SES IAM user is required to confirgure SMTP credentials
  name = "n8n_send_email"
}

resource "aws_iam_group" "n8n_send_email" {
  name = "n8n_send_email"
}

resource "aws_iam_group_membership" "n8n_send_email" {
  name  = aws_iam_user.n8n_send_email.name
  group = aws_iam_group.n8n_send_email.name
  users = [
    aws_iam_user.n8n_send_email.name
  ]
}

resource "aws_iam_group_policy_attachment" "n8n_send_email" {
  group      = aws_iam_user.n8n_send_email.name
  policy_arn = aws_iam_policy.n8n_send_email.arn
}

data "aws_iam_policy_document" "n8n_send_email" {
  statement {
    effect = "Allow"
    actions = [
      "ses:SendRawEmail"
    ]
    resources = [
      aws_ses_domain_identity.n8n.arn
    ]
    condition {
      test     = "ForAllValues:StringLike"
      variable = "ses:Recipients"
      values   = ["*@cds-snc.ca"]
    }
  }
}

resource "aws_iam_policy" "n8n_send_email" {
  name   = "n8n_send_email"
  policy = data.aws_iam_policy_document.n8n_send_email.json
}

resource "aws_iam_access_key" "n8n_send_email" {
  user = aws_iam_user.n8n_send_email.name
}
