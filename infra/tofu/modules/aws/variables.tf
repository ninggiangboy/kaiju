# Inputs are deliberately few. Anything an operator would have to look up twice
# belongs in the environment's own tfvars, not here.

variable "name" {
  description = "Environment name, used only as a resource name prefix. NOTHING branches on it (CON-67)."
  type        = string
}

variable "domain" {
  description = "Mail domain to verify with SES, e.g. kaiju.example.com."
  type        = string
}

variable "db_instance_class" {
  description = "Managed PostgreSQL instance class."
  type        = string
}

variable "db_allocated_storage" {
  description = "Allocated storage in GiB."
  type        = number
  default     = 20
}

variable "db_multi_az" {
  description = "Run a standby in a second availability zone. True for tier 4."
  type        = bool
  default     = false
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Subnets the database lives in. Private ones."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups permitted to reach the database."
  type        = list(string)
  default     = []
}
