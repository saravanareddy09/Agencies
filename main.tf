# Set up the Infrastructure

# Configure the AWS provider
provider "aws" {
  region = "eu-west-1"
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MyVPC"
  }
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet"
  }
}

# Create a private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-1a"

  tags = {
    Name = "PrivateSubnet"
  }
}

# KMS configure
resource "aws_kms_key" "s3_encryption_key" {
  description             = "KMS key for S3 bucket encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

# Create an S3 bucket for the data lake storage
resource "aws_s3_bucket" "data_lake_bucket" {
  bucket = var.data_lake_bucket_name

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.s3_encryption_key.arn
      }
    }
  }

  tags = {
    Name = "DataLakeBucket"
  }
}

# Create an IAM role for SFTP access to the S3 bucket
resource "aws_iam_role" "sftp_role" {
  name = "SFTPRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "transfer.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach an IAM policy to the SFTP role
resource "aws_iam_role_policy_attachment" "sftp_role_policy_attachment" {
  role       = aws_iam_role.sftp_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Create an AWS Transfer for SFTP server
resource "aws_transfer_server" "sftp_server" {
  identity_provider_type = "SERVICE_MANAGED"
  endpoint_type          = "PUBLIC"
  tags = {
    Name = "SFTP Server"
  }
}

# Create the security group for the SFTP server
resource "aws_security_group" "sftp_sg" {
  #vpc_id  = "vpc-019c61f4f37199e31"  # Replace with your VPC ID
  name        = "sftp-security-group"
  description = "Security group for SFTP server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["103.186.41.125/32"] # Replace with actual agency IP addresses
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Associate the security group with the SFTP server
resource "aws_security_group_rule" "sftp_server_sg_rule" {
  security_group_id = aws_security_group.sftp_sg.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = aws_security_group.sftp_sg.id
}

# Associate the security group with the SFTP server
resource "aws_security_group_rule" "sftp_server_sg_rule1" {
  security_group_id = aws_security_group.sftp_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  source_security_group_id = aws_security_group.sftp_sg.id
}


# Output the SFTP server endpoint
output "sftp_server_endpoint" {
  value = aws_transfer_server.sftp_server.endpoint
}
