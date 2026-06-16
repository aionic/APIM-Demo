variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "grafana_name" {
  type = string
}

variable "tags" {
  type = map(string)
}
