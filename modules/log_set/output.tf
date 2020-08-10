output "kinesis_arn" {
  description = "kinesis ARN"
  value       = "${aws_kinesis_stream.stream.arn}"
}

output "nginx_public_ip" {
  description = "NGINX EC2 Public IP"
  value       = "${aws_instance.nginx.public_ip}"
}

output "nginx_private_ip" {
  description = "NGINX EC2 Private IP"
  value       = "${aws_instance.nginx.private_ip}"
}
