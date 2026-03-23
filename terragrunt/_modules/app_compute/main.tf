terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

variable "instance_name" { type = string }
variable "vpc_id"        { type = string }
variable "subnet_id"     { type = string }

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-6.1-x86_64"]
  }
}

resource "aws_security_group" "app" {
  name        = "${var.instance_name}-sg"
  vpc_id      = var.vpc_id
  # Permitir tráfico del puerto 80
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.nano"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.app.id]
  
  # SEGURIDAD SENIOR: Sin IP pública (Tier Privado)
  associate_public_ip_address = false

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)
              echo "<h1>FinNow API - Region: $REGION (Secure Tier)</h1>" > /var/www/html/index.html
              EOF

  tags = { 
    Name    = var.instance_name
    Project = "finnow-drx" 
  }
}

output "instance_id" { value = aws_instance.app.id }
