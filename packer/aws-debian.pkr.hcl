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
  default = ""
}

source "amazon-ebs" "debian" {
  ami_name      = "packer-demo-${var.img_version}"
  instance_type = "t2.micro"
  region        = "us-west-2"
  source_ami    = "ami-07437ddc77ba01a60"
  ssh_username  = "admin"
}

build {
  name = "packer-demo"
  sources = [
    "source.amazon-ebs.debian"
  ]
}
