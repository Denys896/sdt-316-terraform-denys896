variable "aws_region" {
  description = "AWS region to deploy into. Free-tier eligibility is the same in all regions, but prices for anything outside the free tier differ."
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Short name used for naming and tagging resources."
  type        = string
  default     = "tf-student-demo"
}

variable "instance_type" {
  description = "EC2 instance type. Keep t3.micro (or t2.micro in older regions) to stay inside the free tier."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t2.micro", "t3.micro", "t4g.micro"], var.instance_type)
    error_message = "Only t2.micro, t3.micro and t4g.micro are free-tier eligible. Change this validation only if you accept being billed."
  }
}

variable "ssh_public_key_path" {
  description = "Path to YOUR public SSH key. It is uploaded to AWS so you can log in to the VM."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH into the VM. 0.0.0.0/0 means 'anyone'. Set it to <your-ip>/32 for better security."
  type        = string
  default     = "0.0.0.0/0"
}
