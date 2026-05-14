VERSION ?= 8.4
IMAGE ?= utopia-base-test:$(VERSION)
ENV_FILE := versions/$(VERSION).env

VERSIONS := $(patsubst versions/%.env,%,$(wildcard versions/*.env))

BUILD_ARGS = $(shell awk -F= '!/^\#/ && NF { printf "--build-arg %s ", $$1 }' $(ENV_FILE))

.PHONY: build test all clean

build:
	set -a && . ./$(ENV_FILE) && set +a && \
	docker build $(BUILD_ARGS) --tag $(IMAGE) .

test: build
	container-structure-test test --image $(IMAGE) --config tests.yaml

all:
	@for v in $(VERSIONS); do $(MAKE) build VERSION=$$v || exit $$?; done

clean:
	@for v in $(VERSIONS); do docker rmi utopia-base-test:$$v 2>/dev/null || true; done
