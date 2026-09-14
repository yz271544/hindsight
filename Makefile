SHELL := /bin/sh

IMAGE_NAME ?= hindsight-api
IMAGE_TAG ?= local-$(shell git rev-parse --short=9 HEAD)
IMAGE := $(IMAGE_NAME):$(IMAGE_TAG)

DOCKERFILE ?= docker/standalone/Dockerfile
DOCKER_TARGET ?= api-only
DOCKER_PLATFORM ?= linux/amd64
DOCKER_BUILD_ARGS ?=

# Proxy arguments are optional. Set them on the command line or in the
# environment when the builder needs a proxy, for example:
#   make docker-build HTTP_PROXY=http://172.17.0.1:10808 HTTPS_PROXY=http://172.17.0.1:10808
PROXY_BUILD_ARGS :=
ifneq ($(strip $(HTTP_PROXY)),)
PROXY_BUILD_ARGS += --build-arg http_proxy=$(HTTP_PROXY)
endif
ifneq ($(strip $(HTTPS_PROXY)),)
PROXY_BUILD_ARGS += --build-arg https_proxy=$(HTTPS_PROXY)
endif
ifneq ($(strip $(NO_PROXY)),)
PROXY_BUILD_ARGS += --build-arg no_proxy=$(NO_PROXY)
endif

.DEFAULT_GOAL := help

.PHONY: help docker-build docker-inspect

help:
	@echo "Hindsight Docker targets:"
	@echo "  make docker-build    Build the current source as an API-only image"
	@echo "  make docker-inspect  Show the resulting image ID and size"
	@echo
	@echo "Defaults:"
	@echo "  IMAGE=$(IMAGE)"
	@echo "  DOCKER_TARGET=$(DOCKER_TARGET)"
	@echo "  DOCKER_PLATFORM=$(DOCKER_PLATFORM)"

docker-build:
	docker build \
		--platform $(DOCKER_PLATFORM) \
		--target $(DOCKER_TARGET) \
		--file $(DOCKERFILE) \
		--tag $(IMAGE) \
		$(PROXY_BUILD_ARGS) \
		$(DOCKER_BUILD_ARGS) \
		.

docker-inspect:
	docker image inspect $(IMAGE) \
		--format 'image={{index .RepoTags 0}} id={{.Id}} size={{.Size}} architecture={{.Architecture}}'
