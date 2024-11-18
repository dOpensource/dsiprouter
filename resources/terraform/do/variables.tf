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

variable "dns_domain" {
	type=string
	default=""
}

variable "dns_hostname" {
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

variable "pull_request" {
	type=string
	default=""
}

variable "image" {
	type=string
	default="debian-12-x64"
}

variable "image_size" {
	type=string
	default="2gb"
}

variable "additional_commands" {
	type=string
	default="echo"
}
