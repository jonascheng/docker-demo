variable "suser" {
  type    = string
  default = "root"
}

variable "spass" {
  type    = string
  default = "txone"
}

variable "fpuser" {
  type    = string
  default = "admin"
}

variable "fppass" {
  type    = string
  default = "txone"
}

// https://www.packer.io/plugins/builders/amazon/ebs
source "vagrant" "debian" {
  communicator = "ssh"
  source_path  = "debian/stretch64"
  output_dir   = "./artifacts"
  provider     = "virtualbox"
}

build {
  name = "packer-demo"
  sources = [
    "source.vagrant.debian"
  ]

  provisioner "ansible" {
    extra_arguments = [
      "-vvvv",
      "--extra-vars", "suser=${var.suser}", "spass=${var.spass}", "fpuser=${var.fpuser}", "fppass=${var.fppass}"
    ]

    playbook_file = "./ansible-playbook.yml"
  }
}
