# Week 11 classwork: the Terraform loop with the `local` provider.
# Nothing here touches a cloud account or costs anything; it writes one file
# on your own machine. See README.md for the steps.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

variable "student_name" {
  description = "Your name. Change the default in step 5 and watch what plan says."
  type        = string
  default     = "student"
}

resource "local_file" "hello" {
  filename = "${path.module}/hello.txt"
  content  = "Hello, ${var.student_name}! This file is managed by Terraform.\n"
}
