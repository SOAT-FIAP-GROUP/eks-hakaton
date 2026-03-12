variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "active_profile" {
  default = "develop"  
}

variable "bucket" {
  default = "meu-terraform-states-soat-948512815388"  
}

variable "local_name" {
  description = "Infra stack/cluster name and Environent for resources local name"
  type        = map(string)
  default = {
    name = "hakaton-app",
    env  = "dev"
  }

  # Load balancer names must be no more than 32 characters long, and can only contain a limited set of characters.
  validation {
    condition     = length(var.local_name["name"]) <= 16 && length(regexall("[^a-zA-Z0-9-]", var.local_name["name"])) == 0
    error_message = "The project tag must be no more than 16 characters, and only contain letters, numbers, and hyphens."
  }

  validation {
    condition     = length(var.local_name["env"]) <= 8 && length(regexall("[^a-zA-Z0-9-]", var.local_name["env"])) == 0
    error_message = "The environment tag must be no more than 8 characters, and only contain letters, numbers, and hyphens."
  }
}

variable "vpc_cidr_block" {
  description = "Main VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_subnets_count" {
  description = "no. of subnets to launch"
  type        = number
  default     = 2 # For EKS, you need at least two availability zones??
}
