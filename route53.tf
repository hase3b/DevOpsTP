# Data source for existing hosted zone
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# A Record for app subdomain pointing to ALB
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "haseeb-app.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# A Record for BI tool subdomain pointing to ALB
resource "aws_route53_record" "bi" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "haseeb-bi.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# ACM Certificate for only subdomains (e.g., app.example.com, bi.example.com)
resource "aws_acm_certificate" "main" {
  domain_name       = "*.${var.domain_name}"       # e.g., *.example.com
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-cert"
  }
}

# Certificate validation DNS record for *.example.com
resource "aws_route53_record" "cert_validation" {
  name    = tolist(aws_acm_certificate.main.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.main.domain_validation_options)[0].resource_record_type
  ttl     = 60
  records = [tolist(aws_acm_certificate.main.domain_validation_options)[0].resource_record_value]
  zone_id = data.aws_route53_zone.main.zone_id

  allow_overwrite = true
}

# Certificate validation resource
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]

  timeouts {
    create = "5m"
  }
}