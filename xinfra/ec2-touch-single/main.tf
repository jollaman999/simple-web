provider "aws" {
  region = "ap-northeast-2"
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "ec2_key" {
  key_name = "ish-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_security_group" "sg_nginx" {
  name_prefix = "nginx-" # AWS can't start name with 'sg-'

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all of outbouds traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "instance_nginx" {
  ami             = "ami-0c63ba386d57a6296" # Amazon Linux 2 AMI (리전별로 AMI ID가 다를 수 있음)
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.ec2_key.key_name # AWS에서 생성한 SSH 키 적용
  security_groups = [aws_security_group.sg_nginx.name]

  # EC2 시작 시 Nginx 설치 및 실행을 위한 User Data
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install nginx1 -y
              systemctl start nginx
              systemctl enable nginx
              EOF
  tags = {
    Name = "nginx-server"
  }
}

output "public_ip_nginx" {
  value       = aws_instance.instance_nginx.public_ip
  description = "Public IP of the Nginx EC2 instance"
}

output "ssh_private_key_pem" {
  value       = tls_private_key.ssh_key.private_key_pem
  description = "Private key for SSH access"
  sensitive   = true
}
