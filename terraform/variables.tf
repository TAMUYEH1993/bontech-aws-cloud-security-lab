variable "aws_region" {
  description = "AWS region for the lab."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet."
  type        = string
  default     = "10.10.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet."
  type        = string
  default     = "10.10.2.0/24"
}

variable "trusted_ssh_cidr" {
  description = "Trusted public IPv4 CIDR allowed to SSH to the bastion, for example 203.0.113.10/32."
  type        = string
}

variable "key_name" {
  description = "Existing EC2 key-pair name. Do not commit the private key."
  type        = string
}
