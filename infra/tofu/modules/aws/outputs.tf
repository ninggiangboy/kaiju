# THIS FILE IS THE CONTRACT.
#
# Every cloud module exposes exactly these outputs, whatever it builds behind
# them. That is what makes the choice of cloud swappable - not some abstraction
# over the resources themselves, which genuinely cannot be abstracted (ADR-0014).
#
# A module for another cloud is a sibling directory implementing this same list.

output "db_url" {
  description = "Ordinary reads and writes. Goes through the pooler where one exists."
  value       = "postgresql://${aws_db_instance.main.address}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
}

output "db_direct_url" {
  description = <<-TEXT
    The notification listener's connection, and the migration runner's.

    This is a SEPARATE value from db_url and stays separate even when the two
    point at the same place (CON-25). Two independent reasons:

      - LISTEN/NOTIFY does not survive transaction pooling, and RDS Proxy does
        not forward it either. The listener must reach the instance directly.
      - The migration changelog lock is session-scoped and is held for the whole
        run, so it cannot go through a pooler either (CON-62).
  TEXT
  value       = "postgresql://${aws_db_instance.main.address}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
}

output "object_storage_endpoint" {
  value = "https://s3.${data.aws_region.current.id}.amazonaws.com"
}

output "object_storage_bucket" {
  value = aws_s3_bucket.attachments.id
}

output "mail_host" {
  description = "SMTP, not the SES SDK - see the note in ses.tf."
  value       = "email-smtp.${data.aws_region.current.id}.amazonaws.com"
}

output "mail_port" {
  value = 587
}

output "mail_dns_records" {
  description = <<-TEXT
    Records to publish for the mail domain: DKIM, SPF, DMARC and the custom
    MAIL FROM subdomain.

    Returned rather than created, because the domain's DNS may well not live in
    this cloud account. Getting these wrong produces NO error at all - mail
    simply lands in spam, and the symptom users report is "signing in does not
    work".
  TEXT
  value = {
    dkim = [
      for t in aws_ses_domain_dkim.main.dkim_tokens :
      { name = "${t}._domainkey.${var.domain}", type = "CNAME", value = "${t}.dkim.amazonses.com" }
    ]
    mail_from_mx  = { name = "mail.${var.domain}", type = "MX", value = "10 feedback-smtp.${data.aws_region.current.id}.amazonses.com" }
    mail_from_spf = { name = "mail.${var.domain}", type = "TXT", value = "v=spf1 include:amazonses.com ~all" }
    dmarc         = { name = "_dmarc.${var.domain}", type = "TXT", value = "v=DMARC1; p=quarantine; rua=mailto:dmarc@${var.domain}" }
  }
}
