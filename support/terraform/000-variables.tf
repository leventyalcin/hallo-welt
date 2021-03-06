variable "aws_region" {
  description = "EC2 Region for the VPC"
}

variable "aws_key_name" {
  description = "SSH Keypair name"
}

variable "coreos_ami_id" {
  description = "AMI ID of CoreOS"
}

variable "vpc_id" {
  description = "VPC ID of the app"
}

variable "vpc_cidr" {
  descripton = "Will be used in security groups"
}

variable "private_subnet_ids" {
  descripton = "Private subnet ids to create the ASGs"
}

variable "public_subnet_ids" {
  descripton = "Public subnet ids to create the ELBs"
}

variable "instance_type" {
  descripton = "Instance type for CoreOS instances"
}

variable "public_domain_zoneid" {
  descripton = "Zone ID of public domain name"
}

variable "public_domain" {
  description = "Top level domain to use; trainz.io or eurostar.com"
}

variable "service_name" {
  description = "What docker image we will deploy"
}

variable "service_version" {
  description = "Docker image tag"
}

variable "service_port" {
  description = "Service port number"
}

variable "service_asg_max" {
  description = "ASG size for the service"
}

variable "service_dns" {
  description = "Service DNS record. Will be calculated in the Makefile"
}

variable "dockerhub_account" {
  description = "docker box name will be generated by dockerhub_account+service_name+service_version in user_data"
}
