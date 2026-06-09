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

variable "allowed_ip_addresses" {
  type        = list(string)
  default     = ["167.220.149.220"]
  description = "IP addresses or ranges allowed to reach the public APIM ingress for the demo. Use your public IPv4/IPv6 address for the first run."
}

variable "entra_client_id" {
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
  description = "Client ID of the Entra app used for developer portal / OAuth demo."
}

variable "entra_client_secret" {
  type        = string
  default     = "replace-me"
  sensitive   = true
  description = "Client secret for the Entra app used in APIM OAuth configuration."
}

variable "tenant_id" {
  type        = string
  default     = null
  description = "Optional tenant ID used for Entra auth and Key Vault access."
}
