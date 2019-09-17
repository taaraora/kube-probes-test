SHELL := /bin/sh

MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
CURRENT_DIR := $(patsubst %/,%,$(dir $(MAKEFILE_PATH)))

DOCKER_IMAGE_NAME := $(if ${TRAVIS_REPO_SLUG},${TRAVIS_REPO_SLUG},taaraora/kube-probes-test)
DOCKER_IMAGE_TAG := $(if ${DOCKER_IMAGE_TAG},${DOCKER_IMAGE_TAG},$(shell git describe --tags --always | tr -d v || echo 'latest'))
GO111MODULE=on

GO_FILES := $(shell find . -type f -name '*.go' -not -path "./vendor/*")

define LINT
	@echo "Running code linters..."
	golangci-lint run
endef

define GOIMPORTS
	goimports -v -w -local github.com/taaraora/kube-probes-test -l $(GO_FILES)
endef

define TOOLS
		if [ ! -x "`which golangci-lint 2>/dev/null`" ]; \
        then \
        	echo "golangci-lint linter not found."; \
        	echo "Installing linter... into ${GOPATH}/bin"; \
        	curl -sfL https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | sh -s -- -b ${GOPATH}/bin  v1.18.0 ; \
        fi
endef

.PHONY: default
default: lint

.PHONY: lint
lint: tools
	@$(call LINT)

.PHONY: test
test:
	go test -mod=vendor -count=1 -race ./...

.PHONY: tools
tools:
	@$(call TOOLS)

.PHONY: goimports
goimports:
	@$(call GOIMPORTS)

.PHONY: push
push:
	docker push $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)

.PHONY: build-image
build-image: build
	docker build -t $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) -f ./Dockerfile .
	docker tag $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) $(DOCKER_IMAGE_NAME):latest
