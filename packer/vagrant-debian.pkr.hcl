variable "img_version" {
  type    = string
  default = "nil"
}

variable "suser" {
  type    = string
}

variable "spass" {
  type    = string
}

variable "fpuser" {
  type    = string
}

variable "fppass" {
  type    = string
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

    playbook_file = "./playbook.yml"
  }
}
