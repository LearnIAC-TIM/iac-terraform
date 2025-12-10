variable "student_name" {
  description = "Student's name or identifier (will be used in resource naming)"
  type        = string
  default     = "timlab"

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.student_name))
    error_message = "Student name must contain only lowercase letters and numbers, no spaces or special characters."
  }
}

variable "location" {
  description = "The Azure region to deploy to"
  type        = string
  default     = "westeurope"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "student-lab"
}
