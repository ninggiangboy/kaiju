# Transactional mail.
#
# THIS IS NOT A PERIPHERAL SERVICE. Magic link is the only way to sign in
# (ADR-0009), so mail is on the critical path of authentication - as critical as
# the database. Mail down means nobody signs in.
#
# The application speaks SMTP, never the SES SDK. That is what keeps tiers 1-2
# (a local mail catcher) running the exact same code path as tier 4, and what
# makes the provider swappable by changing environment variables.

resource "aws_ses_domain_identity" "main" {
  domain = var.domain
}

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

# A custom MAIL FROM subdomain aligns SPF with the visible From address. Without
# it, DMARC alignment rests on DKIM alone.
resource "aws_ses_domain_mail_from" "main" {
  domain           = aws_ses_domain_identity.main.domain
  mail_from_domain = "mail.${var.domain}"
}

# AWS suspends an account above roughly 5% bounces or 0.1% complaints. For magic
# link that ratio is not theoretical: addresses are typed by hand at sign-in, so
# a mistyped domain is a hard bounce. Feedback has to be consumed from day one.
resource "aws_sesv2_configuration_set" "main" {
  configuration_set_name = "kaiju-${var.name}"

  delivery_options { tls_policy = "REQUIRE" }

  reputation_options { reputation_metrics_enabled = true }

  suppression_options {
    suppressed_reasons = ["BOUNCE", "COMPLAINT"]
  }
}

# Bounce and complaint notifications are delivered over HTTPS straight to the
# application. Deliberately no queue in between: a queue here would look like an
# internal message broker in the architecture diagram, and ADR-0005 rules those
# out. This is an inbound third-party webhook, which is a different thing, and
# keeping it visibly different is the point.
resource "aws_sns_topic" "mail_feedback" {
  name = "kaiju-${var.name}-mail-feedback"
}

resource "aws_ses_identity_notification_topic" "bounce" {
  topic_arn                = aws_sns_topic.mail_feedback.arn
  notification_type        = "Bounce"
  identity                 = aws_ses_domain_identity.main.domain
  include_original_headers = true
}

resource "aws_ses_identity_notification_topic" "complaint" {
  topic_arn                = aws_sns_topic.mail_feedback.arn
  notification_type        = "Complaint"
  identity                 = aws_ses_domain_identity.main.domain
  include_original_headers = true
}
