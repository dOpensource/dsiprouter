terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.60.0"
    }
  }
}

provider "digitalocean" {}

data "digitalocean_ssh_key" "ssh_key" {
  name = var.pub_key_name
}

resource "digitalocean_reserved_ip" "floating_ip" {
  region = var.region
}

resource "digitalocean_record" "dns_record" {
  domain = var.dns_domain
  type = "A"
  name = var.dns_hostname
  value = digitalocean_reserved_ip.floating_ip.ip_address
}

resource "digitalocean_droplet" "dsiprouter" {
  name = digitalocean_record.dns_record.fqdn
  region = var.region
  size = var.image_size	
  image = var.image
  ssh_keys = [data.digitalocean_ssh_key.ssh_key.fingerprint]
}

# we w for the assignment to complete and then run provisioner
# this allows for us to have a valid DNS record prior to install
resource "digitalocean_reserved_ip_assignment" "floating_ip_assn" {
  ip_address = digitalocean_reserved_ip.floating_ip.ip_address
  droplet_id = digitalocean_droplet.dsiprouter.id

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "root"
      host = digitalocean_reserved_ip.floating_ip.ip_address
      private_key = file(var.pvt_key_path)
      timeout = "5m"
    }

    inline = [
      "for i in `seq 0 10`; do [ $i -eq 10 ] && { echo 'failed waiting on cloud-init boot'; exit 1; } || { [ -f /var/lib/cloud/instance/boot-finished ] && break; sleep 3; }; done",
      "apt-get update -y",
      "for i in `seq 0 10`; do [ $i -eq 10 ] && { echo 'failed waiting on DNS record'; exit 1; } || { getent hosts ${digitalocean_record.dns_record.fqdn} >/dev/null && break; sleep 3; }; done",
      "apt-get install -y git",
      var.pull_request != "" ? "git clone https://github.com/dOpensource/dsiprouter.git /opt/dsiprouter && cd /opt/dsiprouter && git fetch origin pull/${var.pull_request}/head:pr_${var.pull_request}; git switch pr_${var.pull_request}" : "git clone -b ${var.branch}  https://github.com/dOpensource/dsiprouter.git /opt/dsiprouter",
      "/opt/dsiprouter/dsiprouter.sh install -all",
      "${var.additional_commands}"
    ]
  }
}
