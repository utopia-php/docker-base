VERSION ?= 8.4
IMAGE ?= utopia-base-test
ENV_FILE := versions/$(VERSION).env

BUILD_ARGS := $(shell awk -F= '!/^\#/ && NF { printf "--build-arg %s ", $$1 }' $(ENV_FILE))

.PHONY: build test all clean

build:
	set -a && . ./$(ENV_FILE) && set +a && \
	docker build $(BUILD_ARGS) --tag $(IMAGE) .

test: build
	container-structure-test test --image $(IMAGE) --config tests.yaml

all:
	$(MAKE) build VERSION=8.3
	$(MAKE) build VERSION=8.4
	$(MAKE) build VERSION=8.5

clean:
	docker rmi $(IMAGE) 2>/dev/null || true
