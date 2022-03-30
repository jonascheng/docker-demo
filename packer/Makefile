.DEFAULT_GOAL := help

IMG_VERSION=1.0
DOCKER?=docker
PACKER?=packer

.PHONY: setup
setup: ## setup CI/CD environment
	## required package
	sudo apt-get update -y && sudo apt-get install -y curl software-properties-common apt-transport-https dirmngr --install-recommends
	## install packer
	curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
	sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(shell lsb_release -cs) main"
	sudo apt-get update -y && sudo apt-get install -y packer
	## install virtualbox and vagrant
	wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
	sudo apt-add-repository "deb [arch=amd64] http://download.virtualbox.org/virtualbox/debian $(shell lsb_release -cs) contrib"
	curl -O https://releases.hashicorp.com/vagrant/2.2.19/vagrant_2.2.19_x86_64.deb
	sudo apt-get update -y && sudo apt-get install -y virtualbox-6.0
	sudo apt-get install -y ./vagrant_2.2.19_x86_64.deb
	rm *.deb
	## install ansible
	sudo apt-add-repository "deb http://ppa.launchpad.net/ansible/ansible/ubuntu xenial main"
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
	sudo apt-get update -y && sudo apt-get -y install ansible

.PHONY: init
init: ## init packer
	@for hcl in $(shell ls *.hcl); do $(PACKER) init $${hcl}; done

.PHONY: lint
lint: init ## lint packer template
	@for hcl in $(shell ls *.hcl); do $(PACKER) fmt $${hcl}; done
	@for hcl in $(shell ls *.hcl); do $(PACKER) validate $${hcl}; done

.PHONY: build-box-image
build-box-image: init ## build VBox image
	@echo "[INFO] Start to build OVA image..."
	$(PACKER) build \
		--force \
		vagrant-debian.pkr.hcl

####
## The policy document provides the minimal set permissions necessary for the Amazon plugin to work: https://www.packer.io/plugins/builders/amazon#iam-task-or-instance-role
####
.PHONY: build-aws-image
build-aws-image: init ## build AWS AMI image
ifndef AWS_ACCESS_KEY_ID
	$(error AWS_ACCESS_KEY_ID not set on environment variables)
endif
ifndef AWS_SECRET_ACCESS_KEY
	$(error AWS_SECRET_ACCESS_KEY not set on environment variables)
endif
	@echo "[INFO] Start to build AWS AMI image..."
	$(PACKER) build \
		--force \
		-var "img_version=$(IMG_VERSION)" \
		aws-debian.pkr.hcl

.PHONY: help
help: ## prints this help message
	@echo "Usage: \n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
