variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets"
  type        = list(string)
}

variable "security_group_ids" {
  description = "IDs of the security groups"
  type        = list(string)
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "app_port" {
  description = "Port on which the application runs"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Health check path for ALB"
  type        = string
  default     = "/health"
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Enable WAF for ALB"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}