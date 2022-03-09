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
