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

variable "region" {
  type    = string
  default = "us-west-2"
}

data "amazon-ami" "debian" {
  filters = {
    virtualization-type = "hvm"
    // Refer product code from https://wiki.debian.org/Cloud/AmazonEC2Image/Marketplace
    product-code        = "55q52qvgjfpdj2fpfy9mb1lo4"
    root-device-type    = "ebs"
  }
  region      = "${var.region}"
  owners      = ["aws-marketplace"]
  most_recent = true
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
  region        = "${var.region}"
  source_ami    = data.amazon-ami.debian.id
  // The username to connect to SSH with.
  ssh_username = "admin"

  // Force Packer to first deregister an existing AMI if one with the same name already exists.
  force_deregister = true
  // Force Packer to delete snapshots associated with AMIs, which have been deregistered by force_deregister.
  force_delete_snapshot = true

  // Add one or more block devices before the Packer build starts.
  launch_block_device_mappings {
    // Intent to resize root device
    device_name           = "xvda"
    volume_size           = 25
    volume_type           = "gp2"
    delete_on_termination = true
  }
}

build {
  name = "packer-demo"
  sources = [
    "source.amazon-ebs.debian"
  ]
}
