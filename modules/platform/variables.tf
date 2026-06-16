variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "log_analytics_name" {
  type = string
}

variable "key_vault_name" {
  type = string
}

variable "ai_service_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "tenant_id" {
  type = string
}

variable "deployer_object_id" {
  type = string
}

variable "demo_secret_value" {
  type      = string
  sensitive = true
}
