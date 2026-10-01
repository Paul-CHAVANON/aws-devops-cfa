output "instance_id" {
  value = aws_instance.web.id
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

output "private_ip" {
  value = aws_instance.web.private_ip
}

output "instance_type" {
  value = aws_instance.web.instance_type
}

output "security_group_id" {
  value = aws_security_group.novashop_sg.id
}

output "instance_state" {
  value = aws_instance.web.instance_state
}
