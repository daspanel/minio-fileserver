#
#   Copyright 2015  Xebia Nederland B.V.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

######################################################################
# Constants
######################################################################

# Customize your project settings in this file.  
include conf/make-project-settings.mk

#RELEASE_SUPPORT := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))/scripts/make-release-support.sh
RELEASE_SUPPORT := scripts/make-release-support.sh
VERSION=$(shell . $(RELEASE_SUPPORT) ; getVersion)
TAG=$(shell . $(RELEASE_SUPPORT); getTag)

.PHONY: pre-build docker-build post-build build release patch-release minor-release major-release tag check-status check-release showver \
	push do-push post-push

# The default target -- what happens if you just type 'make'
all: help

help:
	@echo "make build                 builds a new version of your Docker image and tags it."
	@echo "make patch-release         increments the patch release level, build and push to registry."
	@echo "make minor-release         increments the minor release level, build and push to registry."
	@echo "make major-release         increments the major release level, build and push to registry."
	@echo "make release               build the current release and push the image to the registry."
	@echo "make check-status          will check whether there are outstanding changes."
	@echo "make check-release         will check whether the current directory matches the tagged release in git."
	@echo "make showver               will show the current release tag based on the directory content."
	@echo "make lint                  check Dockerfile using https://github.com/lukasmartinelli/hadolint."
	@echo "make clean                 remove all temporary, build, test, coverage and Python artifacts."
	@echo "make rootfs-fixperms       remove write premission from group and others inside roots."
	@echo "make clean-image           remove project image from local Docker - https://linuxconfig.org/remove-all-containners-based-on-docker-image-name"
	@echo "make clean-image-dangling  remove Docker dangling images (and exited containers)."
	@echo "make clean-build           remove build artifacts."
	@echo "make clean-pyc             remove Python file artifacts."
	@echo "make clean-test            remove test and coverage artifacts."
	@echo "make run-sh                run current image version with interactive shell (/bin/sh)."
	@echo "make gen-changelog         auto generate CHANGELOG.md file."
	@echo "make mkdocs-gen            generate mkdocs html documentation"
	@echo "make mkdocs-serve          run local mkdocs server to test html documentation"
	@echo "make mkdocs-deploy-gh      deploy html documentation in GitHub gh-pages branch of this project"

mkdocs-gen:
	rm -Rf site_mkdocs
	mkdocs build --clean

mkdocs-serve: mkdocs-gen
	mkdocs serve

mkdocs-deploy-gh: mkdocs-gen
	mkdocs gh-deploy --clean

gen-changelog:
	rm -f change.log
	bin/changelog init
	bin/changelog prepare
	bin/changelog test
	bin/changelog finalize --version=$(shell . $(RELEASE_SUPPORT); getVersion)
	bin/changelog export --template=templates/changelog.tmpl --vars='{"github_user":"$(GITHUB_USER)", "github_project":"$(GITHUB_PROJECT)"}' > CHANGELOG.md
	bin/changelog export --template=templates/changelog.tmpl --vars='{"github_user":"$(GITHUB_USER)", "github_project":"$(GITHUB_PROJECT)"}' > docs/changelog.md

run-sh: 
	docker run -it $(IMAGE):$(VERSION) /bin/sh

lint:
	docker run --rm -i lukasmartinelli/hadolint < Dockerfile

clean: clean-build clean-pyc clean-test
	find . -name '*~' -exec rm -f {} +

rootfs-fixperms:
	chmod -R go-w rootfs

clean-image:
	#docker ps -a | awk '{ print $$1,$$2 }' | grep "$(IMAGE):$(VERSION)" | awk '{print $$1 }' | xargs -I {} docker rm {}
	#docker ps -a | awk '{ print $$1,$$2 }' | grep "$(IMAGE_LOCAL):$(VERSION)" | awk '{print $$1 }' | xargs -I {} docker rm {}
	docker ps -a | awk '{ print $$1,$$2 }' | grep "$(IMAGE)" | awk '{print $$1 }' | xargs -I {} docker rm {}
	docker ps -a | awk '{ print $$1,$$2 }' | grep "$(IMAGE_LOCAL)" | awk '{print $$1 }' | xargs -I {} docker rm {}
	docker rmi $(IMAGE) 2>/dev/null; true
	docker rmi $(IMAGE):$(VERSION) 2>/dev/null; true
	docker rmi $(IMAGE_LOCAL) 2>/dev/null; true
	docker rmi $(IMAGE_LOCAL):$(VERSION) 2>/dev/null; true
	# TODO: remove tagged images left behind

clean-image-dangling:
	docker ps -a -f status=exited -q  | xargs -r docker rm -v
	docker images --no-trunc -q -f dangling=true | xargs -r docker rmi

clean-build:
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

clean-pyc:
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test:
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/

build: rootfs-fixperms pre-build docker-build post-build

pre-build:


post-build:


post-push:


docker-build: .release
	docker build -t $(IMAGE):$(VERSION) .
	@DOCKER_MAJOR=$(shell docker -v | sed -e 's/.*version //' -e 's/,.*//' | cut -d\. -f1) ; \
	DOCKER_MINOR=$(shell docker -v | sed -e 's/.*version //' -e 's/,.*//' | cut -d\. -f2) ; \
	if [ $$DOCKER_MAJOR -eq 1 ] && [ $$DOCKER_MINOR -lt 10 ] ; then \
		echo docker tag -f $(IMAGE):$(VERSION) $(IMAGE):latest ;\
		docker tag -f $(IMAGE):$(VERSION) $(IMAGE):latest ;\
	else \
		echo docker tag $(IMAGE):$(VERSION) $(IMAGE):latest ;\
		docker tag $(IMAGE):$(VERSION) $(IMAGE):latest ; \
	fi

.release:
	@echo "release=0.0.0" > .release
	@echo "tag=$(NAME)-0.0.0" >> .release
	@echo INFO: .release created
	@cat .release


release: check-status check-release build push


push: do-push post-push 

do-push: 
ifeq ($(AUTOBUILD),n)
	@echo "Login in $(REGISTRY_HOST) with user $(USERNAME)"
	docker login --username=$(USERNAME)
	docker push $(IMAGE):$(VERSION)
	docker push $(IMAGE):latest
else
	@echo "Project using docker hub autobuild. None to be done."
endif

snapshot: build push

showver: .release
	@. $(RELEASE_SUPPORT); getVersion

tag-patch-release: VERSION := $(shell . $(RELEASE_SUPPORT); nextPatchLevel)
tag-patch-release: .release tag 

tag-minor-release: VERSION := $(shell . $(RELEASE_SUPPORT); nextMinorLevel)
tag-minor-release: .release tag 

tag-major-release: VERSION := $(shell . $(RELEASE_SUPPORT); nextMajorLevel)
tag-major-release: .release tag 

patch-release: tag-patch-release release
	@echo $(VERSION)

minor-release: tag-minor-release release
	@echo $(VERSION)

major-release: tag-major-release release
	@echo $(VERSION)


tag: TAG=$(shell . $(RELEASE_SUPPORT); getTag $(VERSION))
tag: check-status
	@. $(RELEASE_SUPPORT) ; ! tagExists $(TAG) || (echo "ERROR: tag $(TAG) for version $(VERSION) already tagged in git" >&2 && exit 1) ;
	@. $(RELEASE_SUPPORT) ; setRelease $(VERSION)
	git add .release
	git commit -m "bumped to version $(VERSION)" ;
	rm -f change.log
	bin/changelog init
	bin/changelog prepare
	bin/changelog test
	bin/changelog finalize --version=$(VERSION)
	bin/changelog export --template=templates/changelog.tmpl --vars='{"github_user":"$(GITHUB_USER)", "github_project":"$(GITHUB_PROJECT)"}' > CHANGELOG.md
	bin/changelog export --template=templates/changelog.tmpl --vars='{"github_user":"$(GITHUB_USER)", "github_project":"$(GITHUB_PROJECT)"}' > docs/changelog.md
	git add CHANGELOG.md docs/changelog.md
	git commit -m "See changes in CHANGELOG.md"
	git push
	git tag $(TAG) ;
	@[ -n "$(shell git remote -v)" ] && git push --tags

check-status:
	@. $(RELEASE_SUPPORT) ; ! hasChanges || (echo "ERROR: there are still outstanding changes" >&2 && exit 1) ;

check-release: .release
	@. $(RELEASE_SUPPORT) ; tagExists $(TAG) || (echo "ERROR: version not yet tagged in git. make [minor,major,patch]-release." >&2 && exit 1) ;
	@. $(RELEASE_SUPPORT) ; ! differsFromRelease $(TAG) || (echo "ERROR: current directory differs from tagged $(TAG). make [minor,major,patch]-release." ; exit 1)
