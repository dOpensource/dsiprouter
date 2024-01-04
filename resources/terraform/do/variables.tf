variable "pvt_key_path" {
  type = string
}

variable "pub_key_name" {
  type = string
}
variable "node_name" {
  type = string
  default = "demo"
}

variable "dns_demo_domain" {
  type = string
  default = ""
}

variable "dns_demo_enabled" {
  type = number
  default = 0
}

variable "dns_demo_hostname" {
  type = string
  default = "demo"
}

variable "number_of_environments" {
  type = number
  default = "1"
}

variable "dsip_ver" {
  type = string
  default = "master"
}

variable "dsip_dir" {
  type = string
  default = "/opt/dsiprouter"
}

variable "dsip_repo" {
  type = string
  default = "https://github.com/dOpensource/dsiprouter.git"
}

variable "dsip_options" {
  type = string
  default = "install -all"
}

variable "image" {
  type = string
  default = "debian-12-x64"
}

variable "additional_commands" {
  type = string
  default = "echo ''"
}
