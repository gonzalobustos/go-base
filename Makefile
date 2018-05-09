.PHONY: all build clean image prepare push shell test version

BIN := gobase

PKG := github.com/gonzalobustos/go-base

REGISTRY ?= gonzalobustos

ARCH := amd64

# VERSION := $(shell git describe --tags --always --dirty)
VERSION := 0.0.1

SRC_DIRS := cmd pkg

BUILD_IMAGE ?= golang:1.9-alpine

IMAGE := $(REGISTRY)/$(BIN)

all: build

build: prepare
	@echo "Compiling /bin/$(ARCH)/$(BIN)"
	@docker run                                                             \
			-ti                                                                 \
			--rm                                                                \
			-u $$(id -u):$$(id -g)                                              \
			-v $$(pwd)/.go:/go                                                  \
			-v $$(pwd):/go/src/$(PKG)                                           \
			-v $$(pwd)/bin/$(ARCH):/go/bin                                      \
			-v $$(pwd)/bin/$(ARCH):/go/bin/$$(go env GOOS)_$(ARCH)              \
			-v $$(pwd)/.go/std/$(ARCH):/usr/local/go/pkg/linux_$(ARCH)_static   \
			-w /go/src/$(PKG)                                                   \
			$(BUILD_IMAGE)                                                      \
			/bin/sh -c "ARCH=$(ARCH) VERSION=$(VERSION) PKG=$(PKG) ./scripts/build.sh"

clean:
	@echo "Doing clean-up"
	rm -rf .go bin

image: build
	@echo "Building $(IMAGE):$(VERSION)"
	@docker build \
      -t $(IMAGE):$(VERSION)                                              \
      -t $(IMAGE):latest                                                  \
      --build-arg arch=$(ARCH)                                            \
      --build-arg bin=$(BIN)                                              \
      .

prepare:
	@mkdir -p bin/$(ARCH)
	@mkdir -p .go/src/$(PKG) .go/pkg .go/bin .go/std/$(ARCH)

push:
	@echo "Pushing $(IMAGE):$(VERSION)"
ifeq ($(findstring gcr.io,$(REGISTRY)),gcr.io)
	@gcloud docker -- push $(IMAGE):$(VERSION)
else
	@docker push $(IMAGE):$(VERSION)
endif

shell: prepare
	@echo "Launching a shell"
	@docker run                                                             \
			-ti                                                                 \
			--rm                                                                \
			-u $$(id -u):$$(id -g)                                              \
			-v $$(pwd)/.go:/go                                                  \
			-v $$(pwd):/go/src/$(PKG)                                           \
			-v $$(pwd)/bin/$(ARCH):/go/bin                                      \
			-v $$(pwd)/bin/$(ARCH):/go/bin/$$(go env GOOS)_$(ARCH)              \
			-v $$(pwd)/.go/std/$(ARCH):/usr/local/go/pkg/linux_$(ARCH)_static   \
			-w /go/src/$(PKG)                                                   \
			$(BUILD_IMAGE)                                                      \
			/bin/sh

test: prepare
	@echo "Testing packages"
	@docker run                                                             \
			-ti                                                                 \
			--rm                                                                \
			-u $$(id -u):$$(id -g)                                              \
			-v $$(pwd)/.go:/go                                                  \
			-v $$(pwd):/go/src/$(PKG)                                           \
			-v $$(pwd)/bin/$(ARCH):/go/bin                                      \
			-v $$(pwd)/bin/$(ARCH):/go/bin/$$(go env GOOS)_$(ARCH)              \
			-v $$(pwd)/.go/std/$(ARCH):/usr/local/go/pkg/linux_$(ARCH)_static   \
			-w /go/src/$(PKG)                                                   \
			$(BUILD_IMAGE)                                                      \
			/bin/sh -c "./scripts/test.sh $(SRC_DIRS)"

version:
	@echo $(VERSION)
