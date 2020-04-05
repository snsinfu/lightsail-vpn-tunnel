variable "server_name" {
  type = string
}

variable "server_zone" {
  type = string
}

variable "server_blueprint" {
  type = string
}

variable "server_bundle" {
  type = string
}

variable "admin_user" {
  type = string
}

variable "admin_public_keys" {
  type = list(string)
}

variable "admin_password_hash" {
  type = string
}
