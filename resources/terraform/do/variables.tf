variable "pvt_key" {
	type=string
}

variable "pub_key_name" {
	type=string
}
variable "dsiprouter_prefix" {
	type=string
}

variable "number_of_environments" {
	type=number
}

variable "branch" {
	type=string
	default="master"
}

variable "image" {
	type=string
	default="debian-10-x64"
}
