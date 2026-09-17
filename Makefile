SHELL := /bin/sh

IMAGE_NAME ?= hindsight-api
IMAGE_TAG ?= local-$(shell git rev-parse --short=9 HEAD)
IMAGE := $(IMAGE_NAME):$(IMAGE_TAG)

DOCKERFILE ?= docker/standalone/Dockerfile
DOCKER_TARGET ?= api-only
DOCKER_PLATFORM ?= linux/amd64
DOCKER_BUILD_ARGS ?=

# Proxy arguments are deliberately separate from the host's HTTP_PROXY
# variables. A host proxy such as 127.0.0.1:10808 points back to the build
# container when passed through, and therefore cannot be reached from Docker.
# Set these explicitly when the builder needs the host proxy, for example:
#   make docker-build DOCKER_HTTP_PROXY=http://172.17.0.1:10808 \
#     DOCKER_HTTPS_PROXY=http://172.17.0.1:10808
DOCKER_HTTP_PROXY ?=
DOCKER_HTTPS_PROXY ?=
DOCKER_NO_PROXY ?=

PROXY_BUILD_ARGS :=
ifneq ($(strip $(DOCKER_HTTP_PROXY)),)
PROXY_BUILD_ARGS += --build-arg http_proxy=$(DOCKER_HTTP_PROXY)
endif
ifneq ($(strip $(DOCKER_HTTPS_PROXY)),)
PROXY_BUILD_ARGS += --build-arg https_proxy=$(DOCKER_HTTPS_PROXY)
endif
ifneq ($(strip $(DOCKER_NO_PROXY)),)
PROXY_BUILD_ARGS += --build-arg no_proxy=$(DOCKER_NO_PROXY)
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
