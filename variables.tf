variable "admin_username" {
  type        = string
  description = "Virtual machine administrator username."
}

variable "admin_password" {
  type        = string
  description = "Virtual machine administrator password."
}

variable "administrator_login" {
  type        = string
  description = "Azure SQL Database server administrator account."
}

variable "administrator_login_password" {
  type        = string
  description = "Azure SQL Database server administrator password."
}