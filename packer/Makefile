.DEFAULT_GOAL := help

IMG_VERSION=1.0
DOCKER?=docker
PACKER?=packer

.PHONY: setup
setup: ## setup CI/CD environment
	$(PACKER) init .

.PHONY: lint
lint: setup ## lint packer template
	$(PACKER) fmt .
	$(PACKER) validate .

####
## The policy document provides the minimal set permissions necessary for the Amazon plugin to work: https://www.packer.io/plugins/builders/amazon#iam-task-or-instance-role
####
.PHONY: build-aws-image
build-aws-image: setup ## build AWS AMI image
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
