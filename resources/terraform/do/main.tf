terraform {
  required_providers {
    digitalocean = { source = "digitalocean/digitalocean" }
  }
}

data "digitalocean_ssh_key" "ssh_key" {
  name = var.pub_key_name
}

resource "digitalocean_droplet" "dsiprouter" {
  name = var.node_name
  count = var.number_of_environments
  region = "nyc1"
  size = "1gb"
  image = var.image
  ssh_keys = [data.digitalocean_ssh_key.ssh_key.fingerprint]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.pvt_key_path)
    timeout = "5m"
  }
  provisioner "file" {
    content = templatefile("${path.module}/install.tftpl", {
      dsip_ver = var.dsip_ver
      dsip_dir = var.dsip_dir
      dsip_repo = var.dsip_repo
      build_options = var.dsip_options
      additional_commands = var.additional_commands
    })
    destination = "/tmp/build_dsip.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 3; done",
      "chmod +x /tmp/build_dsip.sh",
      "sudo /tmp/build_dsip.sh",
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
