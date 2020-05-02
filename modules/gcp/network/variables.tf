# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------
variable "gcp_project" {
  type        = string
  description = "Name of your gcp project"
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+-[a-z]{3,8}$", var.gcp_project))
    error_message = "Must be of this format: org-project-env. e.g. org-project-dev."
  }
}

# ------------------------------------------
# Optionals
# ------------------------------------------
variable "random_suffix" {
  type        = bool
  description = "Whether to add a random suffix in resource names or not. Default is false."
  default     = false
}

variable "region" {
  type        = string
  description = "Region for the vpc network. If not given, default will be used."
  default     = "asia-southeast1"
}

variable "bastion_allowed_members" {
  type        = list(string)
  description = "The emails allowed to access bastion host. For users, use \"user:<email>\", for groups, use \"group:<email>\""
  default     = []
}