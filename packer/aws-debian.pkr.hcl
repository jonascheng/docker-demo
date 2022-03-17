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

// https://www.packer.io/plugins/builders/amazon/ebs
source "amazon-ebs" "debian" {
  // If true, Packer will not create the AMI. Useful for setting to true during a build test stage.
  skip_create_ami = true

  // The name of the resulting AMI that will appear when managing AMIs in the AWS console or via APIs. This must be unique.
  ami_name = "packer-demo-${var.img_version}"
  // The description to set for the resulting AMI(s).
  ami_description = "packer-demo-${var.img_version}"

  instance_type = "t2.micro"
  region        = "us-west-2"
  source_ami    = "ami-07437ddc77ba01a60"
  ssh_username  = "admin"

  // Force Packer to first deregister an existing AMI if one with the same name already exists.
  force_deregister = true
  // Force Packer to delete snapshots associated with AMIs, which have been deregistered by force_deregister.
  force_delete_snapshot = true
}

build {
  name = "packer-demo"
  sources = [
    "source.amazon-ebs.debian"
  ]
}
