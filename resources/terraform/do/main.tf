terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.17.0"
    }
  }
}

provider "digitalocean" {
}

data "digitalocean_ssh_key" "ssh_key" {
  name = var.pub_key_name
}


resource "digitalocean_droplet" "dsiprouter" {
  name = "${var.dns_hostname}.${var.dns_domain}"
  count = var.number_of_environments
  region = "tor1"
  size = var.image_size	
  image = var.image
  ssh_keys = [data.digitalocean_ssh_key.ssh_key.fingerprint]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.pvt_key_path)
    timeout = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update -y",
      "sleep 30",
      "apt-get install -y git",
      var.pull_request != "" ? "git clone https://github.com/dOpensource/dsiprouter.git /opt/dsiprouter && cd /opt/dsiprouter && git fetch origin pull/${var.pull_request}/head:pr_${var.pull_request}; git switch pr_${var.pull_request}" : "git clone -b ${var.branch}  https://github.com/dOpensource/dsiprouter.git /opt/dsiprouter",
      "/opt/dsiprouter/dsiprouter.sh install -all",
      "${var.additional_commands}"
    ]
  }
}


resource "digitalocean_record" "dns_record" {
  count = var.number_of_environments
  domain = var.dns_domain
  type = "A"
  name = var.dns_hostname
  value = digitalocean_droplet.dsiprouter.*.ipv4_address[count.index]
}
