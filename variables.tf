variable "location" {
  type        = string
  default     = "westus3"
  description = "Primary Azure region for the demo."
}

variable "demo_name" {
  type        = string
  default     = "apim-demo"
  description = "Prefix used for resource names."
}

variable "publisher_email" {
  type        = string
  default     = "demo-admin@contoso.example"
  description = "Publisher email used by APIM."
}

variable "publisher_name" {
  type        = string
  default     = "Contoso Demo"
  description = "Publisher name shown in the developer portal."
}

variable "apim_sku_name" {
  type        = string
  default     = "StandardV2"
  description = "APIM SKU for the v2 deployment."

  validation {
    condition     = var.apim_sku_name == "StandardV2"
    error_message = "This refactor is locked to APIM Standard v2. Set apim_sku_name to StandardV2."
  }
}

variable "entra_client_id" {
  type        = string
  description = "Client ID of the Entra app used for developer portal / OAuth demo."

  validation {
    condition     = length(trimspace(var.entra_client_id)) > 0
    error_message = "Set entra_client_id via tfvars or TF_VAR_entra_client_id."
  }
}

variable "entra_client_secret" {
  type        = string
  sensitive   = true
  description = "Client secret for the Entra app used in APIM OAuth configuration."

  validation {
    condition     = length(trimspace(var.entra_client_secret)) > 0
    error_message = "Set entra_client_secret via tfvars or TF_VAR_entra_client_secret. Do not hardcode secrets in source."
  }
}

variable "tenant_id" {
  type        = string
  default     = null
  description = "Optional tenant ID used for Entra auth and Key Vault access."
}
