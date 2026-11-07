variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Short name used for naming and tagging resources."
  type        = string
  default     = "tf-student-alb"
}

variable "vm_count" {
  description = "How many VMs to put behind the load balancer. 3 for the lab. Every extra VM is extra instance-hours."
  type        = number
  default     = 3

  validation {
    condition     = var.vm_count >= 1 && var.vm_count <= 3
    error_message = "Keep vm_count between 1 and 3 for this lab."
  }
}

variable "instance_type" {
  description = "EC2 instance type. Keep t3.micro (or t2.micro) to stay on free-tier eligible types."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t2.micro", "t3.micro", "t4g.micro"], var.instance_type)
    error_message = "Only t2.micro, t3.micro and t4g.micro are free-tier eligible."
  }
}

variable "ssh_public_key_path" {
  description = "Path to YOUR public SSH key."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH into the VMs. Set to <your-ip>/32 for better security."
  type        = string
  default     = "0.0.0.0/0"
}
