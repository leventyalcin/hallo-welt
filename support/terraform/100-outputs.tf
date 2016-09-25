output "service_endpoint" {
  value = "http://${aws_route53_record.service.name}.${var.public_domain}"
}
