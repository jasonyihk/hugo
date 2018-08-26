DBG_MAKEFILE ?=
ifeq ($(DBG_MAKEFILE),1)
    $(warning ***** starting Makefile for goal(s) "$(MAKECMDGOALS)")
    $(warning ***** $(shell date))
else
# If we're not debugging the Makefile, don't echo recipes.
MAKEFLAGS += -s
endif

SHELL := /bin/bash

MAKEFLAGS += --no-builtin-rules

.EXPORT_ALL_VARIABLES:
APP_NAME = om-hubot
IMAGE_TAG ?= $(shell git rev-parse --short=8 HEAD)
BUILD_DIR = ./build
DEPLOY_DIR ?= ./deploy
ECR ?= registry.example.com
SSL ?= hugo-ssl-cert-secret
DOMAIN ?= hubot.example.com
DOCKER_FILE ?= Dockerfile

.PHONY: clean
.PHONY: build kube-build
.PHONY: docker-build docker-clean

define BUILD_KUBE_FILE
	mkdir -p $(BUILD_DIR)/ ;
	for file in $(DEPLOY_DIR)/kube/*.yaml ; do \
		newFile=$$(basename "$$file")  \
		domain=$(1) ; ecr=$(2) ; ssl=$(3) ; image_tag=$(4) ; \
		sed "s/{{ECR}}/$$ecr/g; s/{{DOMAIN}}/$$domain/g; \
			s/{{IMAGE_TAG}}/$$image_tag/g; s/{{SSL}}/$$ssl/g; \
		" $$file > $(BUILD_DIR)/$(APP_NAME)-$$newFile ; \
	done ;

	#generate secret
	secretFile=$(BUILD_DIR)/$(APP_NAME)-secret.yaml ; \
	cat $(DEPLOY_DIR)/config/process.json \
		| jq -r 'to_entries \
		| map("  \(.key): " + @base64 "\(.value)")|.[]' \
	>> $$secretFile
endef

clean:
	rm -rf $(BUILD_DIR)

build:
	npm install

kube-build:
	$(call BUILD_KUBE_FILE,$(DOMAIN),$(ECR),$(SSL),$(IMAGE_TAG))

docker-clean:
	docker rmi $(APP_NAME):$(IMAGE_TAG)

docker-build:
	docker build --network=host -f $(DEPLOY_DIR)/docker/$(DOCKER_FILE) -t $(APP_NAME):$(IMAGE_TAG) .
