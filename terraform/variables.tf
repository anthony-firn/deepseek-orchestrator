############################################
#  DeepSeek Orchestrator – variables.tf
############################################

variable "project" {
  description = "Project prefix used in names/tags for all resources."
  type        = string
  default     = "deepseek-orchestrator"
}

variable "aws_region" {
  description = "AWS region to deploy GPU infrastructure in."
  type        = string
  default     = "us-east-1"
}

# ──────────────────────────────────────────
#  Networking
# ──────────────────────────────────────────
variable "vpc_cidr" {
  description = "CIDR block for the project VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet (GPU instance lives here)."
  type        = string
  default     = "10.0.1.0/24"
}

variable "ssh_ingress_cidrs" {
  description = "CIDR blocks allowed to SSH to the GPU instance (tighten for prod!)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ──────────────────────────────────────────
#  EC2 / GPU host
# ──────────────────────────────────────────
variable "instance_type" {
  description = <<EOF
EC2 GPU instance type for training/serving.
For heavy workloads use p5.48xlarge (H100); cheaper options include p4d.24xlarge (A100) or g5.12xlarge (A10G) for smaller models.
EOF
  type        = string
  default     = "p5.48xlarge"
}

variable "root_volume_gb" {
  description = "Size (GiB) of the root EBS volume attached to the instance."
  type        = number
  default     = 500
}

variable "key_pair_name" {
  description = "Name of an **existing** EC2 key‑pair for SSH access."
  type        = string
}

# ──────────────────────────────────────────
#  AMI selection
# ──────────────────────────────────────────
variable "ami_name_filter" {
  description = "Name filter for AWS Deep Learning AMI (override if you have a custom AMI)."
  type        = string
  default     = "Deep Learning AMI GPU PyTorch 2.1.0*Ubuntu 22.04*"
}

# ──────────────────────────────────────────
#  Tags (optional bells & whistles)
# ──────────────────────────────────────────
variable "extra_tags" {
  description = "Map of extra tags applied to all resources (e.g., cost‑center, owner)."
  type        = map(string)
  default     = {}
}
