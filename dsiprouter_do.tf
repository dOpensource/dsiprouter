variable "hostname" {
}

variable "dropletname" {
	default="dsiprouter"
}
variable "number_of_servers" {
	default=1
}
variable "prefix" {
	
}
variable "branch" {
	default="master"
}
variable "installopt" {
	default="-all"
}
variable "repo" {
	default="https://github.com/dOpensource/dsiprouter.git"
}

variable "dc" {
	default="tor1"
}

provider "digitalocean" {
}


resource "template_file" "userdata_web" {
	template = "${file("${path.module}/../templates/dsiprouter.tpl")}"
	
	vars {
		userdata_giturl = "${var.repo}"
		userdata_branch = "${var.branch}"
		userdata_installopt = "${var.installopt}"
		userdata_hostname = "${var.hostname}"
	}
}

data "digitalocean_ssh_key" "jump" {
  name = "Jump"
}

resource "digitalocean_droplet" "dsiprouterDroplet" {
        name = "${var.hostname}"
        #name = "${var.prefix}-${var.dropletname}-${count.index}"
        count = "${var.number_of_servers}"
        region = "${var.dc}"
        size="1gb"
        image="debian-9-x64"
	ssh_keys = [ "${data.digitalocean_ssh_key.jump.fingerprint}" ]
	user_data = "${template_file.userdata_web.rendered}"
}

output "ip" {
  value = "${digitalocean_droplet.dsiprouterDroplet.*.ipv4_address}"
}

output "dsiprouter_gui_password" {
  value = "${digitalocean_droplet.dsiprouterDroplet.*.id}"
}
