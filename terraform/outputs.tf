############################################
#  DeepSeek Orchestrator – outputs.tf
############################################

output "project_name" {
  description = "Prefix tag used for all resources in this stack."
  value       = var.project
}

# ──────────────────────────────────────────
#  Networking
# ──────────────────────────────────────────
output "vpc_id" {
  description = "ID of the VPC created for DeepSeek Orchestrator."
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet hosting the GPU instance."
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "Primary security‑group ID (SSH + inference port rules)."
  value       = aws_security_group.instance_sg.id
}

# ──────────────────────────────────────────
#  GPU EC2 Instance
# ──────────────────────────────────────────
output "gpu_instance_id" {
  description = "EC2 instance ID of the GPU node."
  value       = aws_instance.gpu.id
}

output "gpu_instance_type" {
  description = "EC2 instance type used for the GPU node."
  value       = aws_instance.gpu.instance_type
}

output "gpu_public_ip" {
  description = "Public IPv4 address for SSH / inference (if enabled)."
  value       = aws_instance.gpu.public_ip
}

output "ssh_connect_command" {
  description = "Handy one‑liner for SSH access (adjust key file path!)."
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ubuntu@${aws_instance.gpu.public_ip}"
}

# ──────────────────────────────────────────
#  IAM / Instance Profile
# ──────────────────────────────────────────
output "ec2_instance_profile" {
  description = "Name of the EC2 instance profile attached to the GPU node."
  value       = aws_iam_instance_profile.ec2_profile.name
}
