###########################################################
#  DeepSeek Orchestrator – root module (main.tf)
#  Spin up a GPU instance + networking/IAM scaffolding
###########################################################

terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }
}

#############################
#  Providers & Remote State
#############################
provider "aws" {
  region = var.aws_region
}

#############################
#  VPC & Subnet (minimal)
#############################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project}-subnet-public"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#############################
#  Security Group
#############################
resource "aws_security_group" "instance_sg" {
  name        = "${var.project}-sg"
  description = "Allow SSH and HTTP(s) for DeepSeek Orchestrator"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_ingress_cidrs
  }

  ingress {
    description = "HTTP inference / custom ports"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-sg"
  }
}

#############################
#  IAM role for EC2
#############################
resource "aws_iam_role" "ec2_role" {
  name               = "${var.project}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

#############################
#  GPU EC2 Instance
#############################
resource "aws_instance" "gpu" {
  ami                    = data.aws_ami.dlami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  associate_public_ip_address = true
  security_groups        = [aws_security_group.instance_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  key_name               = var.key_pair_name

  # bootstrap – call your setup_env.sh
  user_data = file("${path.module}/user_data/bootstrap.sh")

  root_block_device {
    volume_size = var.root_volume_gb
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project}-gpu-node"
  }
}

#############################
#  Data Sources
#############################
data "aws_availability_zones" "available" {}

# Deep Learning Base AMI (CUDA 12, Ubuntu 22.04) – change if preferred
data "aws_ami" "dlami" {
  most_recent = true
  owners      = ["679593333241"] # AWS Deep Learning AMIs

  filter {
    name   = "name"
    values = ["Deep Learning AMI GPU PyTorch 2.1.0*Ubuntu 22.04*"]
  }
}

#############################
#  Outputs
#############################
output "gpu_public_ip" {
  description = "Public IP of the GPU instance"
  value       = aws_instance.gpu.public_ip
}

###########################################################
# Variables (move to variables.tf if preferred)
###########################################################
variable "project" {
  description = "Project prefix for naming"
  type        = string
  default     = "deepseek-orchestrator"
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "GPU instance type"
  type        = string
  default     = "p5.48xlarge"          # adjust to p4d.24xlarge or similar
}

variable "root_volume_gb" {
  description = "Size of root EBS volume"
  type        = number
  default     = 500
}

variable "key_pair_name" {
  description = "Existing EC2 Key Pair for SSH"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "ssh_ingress_cidrs" {
  description = "List of CIDR blocks allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
