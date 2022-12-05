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
        name = "${var.dsiprouter_prefix}-dsip-${var.branch}${count.index}"
        count = var.number_of_environments
        region = "tor1"
        size="1gb"
        image=var.image
      	ssh_keys = [ data.digitalocean_ssh_key.ssh_key.fingerprint ]

        connection {
        host = self.ipv4_address
        user = "root"
        type = "ssh"
        private_key = file(var.pvt_key_path)
        timeout = "5m"
        }

        provisioner "remote-exec" {
          inline = [
		"apt-get update -y && sleep 30 && apt-get install -y git && cd /opt && git clone https://github.com/dOpensource/dsiprouter.git -b ${var.branch} && cd dsiprouter && ./dsiprouter.sh install -all && ${var.additional_commands}"
        ]
      }
}


resource "digitalocean_record" "dns_demo_record" {
  count = var.dns_demo_enabled
  domain = var.dns_demo_domain
  type = "A"
  name = var.dns_demo_hostname
  value = digitalocean_droplet.dsiprouter.*.ipv4_address[count.index]
}
