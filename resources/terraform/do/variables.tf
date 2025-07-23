variable "pvt_key_path" {
	type=string
}

variable "pub_key_name" {
	type=string
}

variable "dns_domain" {
	type=string
	default=""
}

variable "dns_hostname" {
	type=string
	default="demo"
}

variable "branch" {
	type=string
	default="master"
}

variable "pull_request" {
	type=string
	default=""
}

variable "region" {
	type=string
	default="tor1"
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
