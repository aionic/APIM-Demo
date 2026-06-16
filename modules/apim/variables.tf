variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "apim_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "apim_sku_name" {
  type = string
}

variable "apim_is_v2_sku" {
  type = bool
}

variable "publisher_email" {
  type = string
}

variable "publisher_name" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "entra_client_id" {
  type = string
}

variable "entra_client_secret" {
  type      = string
  sensitive = true
}

variable "named_values" {
  type = map(any)
}

variable "apis" {
  type = map(any)
}

variable "products" {
  type = map(any)
}

variable "subscriptions" {
  type = map(any)
}

variable "global_policy" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "cognitive_account_id" {
  type = string
}

variable "current_user_object_id" {
  type = string
}
