# Makefile

VERSION ?= $(shell git describe --exact-match 2> /dev/null || \
                 git describe --match=$(git rev-parse --short=8 HEAD) --always --dirty --abbrev=8)
REGISTRY ?=luoh/cluster-api-provider-vsphere-travis-ci

all: build

PWD := $(shell pwd)

build: 
	docker build . --tag $(REGISTRY):$(VERSION)
	docker tag $(REGISTRY):$(VERSION) $(REGISTRY):latest
        
upload:
	docker login -u="$(DOCKER_USERNAME)" -p="$(DOCKER_PASSWORD)";
	docker push $(REGISTRY):$(VERSION)
	docker push $(REGISTRY):latest

clean:
	docker image rm -f $(REGISTRY):$(VERSION)
	docker image rm -f $(REGISTRY):latest
