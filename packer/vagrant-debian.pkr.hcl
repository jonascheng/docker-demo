packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "img_version" {
  type    = string
  default = "nil"
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
}
