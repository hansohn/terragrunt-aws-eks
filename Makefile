SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := dev
.DELETE_ON_ERROR:
.SUFFIXES:

# include makefiles
export SELF ?= $(MAKE)
PROJECT_PATH ?= $(shell 'pwd')
include $(PROJECT_PATH)/Makefile.*

# main
export UNAME_S ?= $(shell uname -s)

# Skip the AWS_PROFILE default when aws-vault has provided credential env vars.
ifndef AWS_ACCESS_KEY_ID
export AWS_PROFILE ?= unknown
endif
export AWS_DEFAULT_REGION ?= us-west-2
export REPO_NAME := $(shell basename ${PWD})

DOCKER_IMAGE ?= hansohn/terraform-aws
DOCKER_TAG   ?= latest
DOCKER_PULL  ?= always

DOCKER_ARGS ?=
DOCKER_ARGS += --interactive
DOCKER_ARGS += --tty
DOCKER_ARGS += --rm
DOCKER_ARGS += --env AWS_PROFILE --env AWS_DEFAULT_REGION
DOCKER_ARGS += --env REPO_NAME
# Credential env vars (set by aws-vault). Forwarded only when present; when they
# are absent the container falls back to AWS_PROFILE + the mounted ~/.aws, so
# `make dev` works with or without aws-vault.
DOCKER_ARGS += --env AWS_ACCESS_KEY_ID --env AWS_SECRET_ACCESS_KEY
DOCKER_ARGS += --env AWS_SESSION_TOKEN --env AWS_REGION
DOCKER_ARGS += --workdir /app
DOCKER_ARGS += --volume ${PWD}:/app
DOCKER_ARGS += --volume ${HOME}/.aws:/root/.aws
# Persist the provider cache (image's .terraformrc plugin_cache_dir) across runs.
DOCKER_ARGS += --volume ${HOME}/.terraform.d/plugin-cache:/opt/terraform/plugin-cache
DOCKER_ARGS += --volume ${HOME}/.ssh/known_hosts:/root/.ssh/known_hosts
DOCKER_ARGS += --volume ${HOME}/.gitconfig:/root/.gitconfig:ro
DOCKER_ARGS += --pull $(DOCKER_PULL)

SSH_AUTH_SOCK_MAGIC_PATH := /run/host-services/ssh-auth.sock
ifeq ($(UNAME_S),Darwin)
DOCKER_ARGS += --env SSH_AUTH_SOCK=$(SSH_AUTH_SOCK_MAGIC_PATH)
DOCKER_ARGS += --volume $(SSH_AUTH_SOCK_MAGIC_PATH):$(SSH_AUTH_SOCK_MAGIC_PATH)
endif


## Run local dev env
dev: ENTRYPOINT ?= bash

dev:
	docker run \
		$(DOCKER_ARGS) \
		$(DOCKER_IMAGE):$(DOCKER_TAG) \
		$(ENTRYPOINT)

.PHONY: dev

CLEAN_DIRS  += .terraform .terragrunt-cache
CLEAN_FILES += 'auto-*.tf' terraform.plan .terraform.lock.hcl
$(CLEAN_DIRS):
	find . -type d -name $@ -prune -exec rm -rf {} \;
$(CLEAN_FILES):
	find . -type f -name $@ -exec rm -f {} \;

## Clean everything
clean: $(CLEAN_DIRS) $(CLEAN_FILES)
.PHONY: clean $(CLEAN_DIRS) $(CLEAN_FILES)
