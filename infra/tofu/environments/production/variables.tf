variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "domain" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "allowed_security_group_ids" {
  type    = list(string)
  default = []
}

variable "db_instance_class" {
  type = string
}

variable "db_multi_az" {
  type    = bool
  default = false
}
