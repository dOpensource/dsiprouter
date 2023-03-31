variable "pvt_key_path" {
	type=string
}

variable "pub_key_name" {
	type=string
}
variable "dsiprouter_prefix" {
	type=string
	default=""
}

variable "dns_demo_domain" {
	type=string
	default=""
}

variable  "dns_demo_enabled" {
	type=number
	default=0
}

variable "dns_demo_hostname" {
	type=string
	default="demo"
}

variable "number_of_environments" {
	type=number
	default="1"
}

variable "branch" {
	type=string
	default="master"
}

variable "image" {
	type=string
	default="debian-10-x64"
}

variable "additional_commands" {
	type=string
	default="echo"
}
