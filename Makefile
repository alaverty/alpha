
# Infrastructure
REGISTRY = lavertyws

# Application
PROJECT_NAME = alpha

# VERSIONING Variables
VERSION_FILE = Dockerfile
VERSION_REGEX = LABEL version=(.*)
APP_VERSION = $(shell perl -ne '/$(VERSION_REGEX)/ && print $$1' $(VERSION_FILE))

# Generated
PROJECT_CONTAINER_NAME = $(PROJECT_NAME)
PROJECT_IMAGE_NAME = $(REGISTRY)/$(PROJECT_NAME)

PROJECT_DOCKER_STRING = $(PROJECT_IMAGE_NAME):$(APP_VERSION)

# Compatability to run docker-tag pre and post docker 1.12.x
DOCKER_VERSION=$(shell docker version --format '{{.Server.Version}}' | cut -d"." -f1-2)
DOCKER_VERSION_ISNEW=$(shell echo $(DOCKER_VERSION)'>='1.12 | bc -l)

ifeq ("$(DOCKER_VERSION_ISNEW)","1")
  CMD_DOCKER_TAG := tag
else
  CMD_DOCKER_TAG := tag -f
endif

.PHONY: docker-build
build:
	$(info Now Building: ${PROJECT_DOCKER_STRING} )
	docker build -t ${PROJECT_DOCKER_STRING} -f ./Dockerfile .
	docker $(CMD_DOCKER_TAG) ${PROJECT_DOCKER_STRING} $(PROJECT_IMAGE_NAME):latest

.PHONY: docker-run
run:
	$(info Now Running: ${PROJECT_DOCKER_STRING} )
	docker run -p 5000:5000 -v $(CURDIR)/app:/opt/app ${PROJECT_DOCKER_STRING}

.PHONY: docker-push
push:
	$(info Now Pushing: ${PROJECT_DOCKER_STRING} )
	@docker push ${PROJECT_DOCKER_STRING}
	$(info Now Pushing: $(PROJECT_IMAGE_NAME):latest )
	@docker push $(PROJECT_IMAGE_NAME):latest

.PHONY: create_links
create_links: _clean_links
	@ln -sf $(CURDIR)/roles $(CURDIR)/tests/roles
	@ln -sf $(CURDIR)/group_vars $(CURDIR)/tests/group_vars
	@ln -sf $(CURDIR)/site.yml $(CURDIR)/tests/site.yml

.PHONY: vagrant-up
vagrant-up:
	@cd tests && vagrant up --no-provision

.PHONY: vagrant-provision-vm
vagrant-provision-vm:
	@cd tests && vagrant provision --provision-with shell,pre,deploy ${vm}

.PHONY: vagrant-provision
vagrant-provision:
	make vagrant-provision-vm vm=dns

.PHONY: test
test: vagrant-up vagrant-provision
	@cd tests && vagrant provision --provision-with test slb

.PHONY: prepare
prepare: create_links

.PHONY: ssh
ssh:
	@cd tests && vagrant ssh ${vm} -c "sudo -i"
