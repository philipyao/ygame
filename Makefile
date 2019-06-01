GO           ?= go
FIRST_GOPATH := $(firstword $(subst :, ,$(shell $(GO) env GOPATH)))
$(info GOPATH:  $(FIRST_GOPATH))
GO_VERSION   ?= $(shell $(GO) version)

PROJ_NAME=$(shell basename "$(PWD)")
PROJ_PATH=$(shell pwd)
PROJ_BIN_PATH=$(PROJ_PATH)/../../bin

export PATH := $(PROJ_PATH)/scripts:$(PATH)

VERSION=1.0.0
#BUILD=$(shell git rev-parse HEAD)
# Use linker flags to provide version/build settings to the target
LDFLAGS=-ldflags "-X=main.Version=$(VERSION) -X=main.Build=$(BUILD)"

.PHONY: all
.DEFAULT: help

.PHONY: help
## help: print this help message
help: Makefile
	@echo
	@echo " Choose a command run in "$(PROJ_TNAME)":"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo

.PHONY: vendor
## vendor: sync build dependencies to the `vendor` directory
vendor:
	@echo "[$(PROJ_NAME)] start to sync vendor"
	@scripts/govendor sync
	@echo "[$(PROJ_NAME)] sync vendor done"

.PHONY: check
check:
	@for d in $$(go list ./... | grep -v /vendor/); do echo $${d}; done

.PHONY: proto
proto:
	@echo "[$(PROJ_NAME)] start generating code from proto file"
#@./scripts/genproto.sh

# List of binary cmds to build
CMDS := \
	monitorserver \
	loginserver

.PHONY: prebuild
prebuild:
	@echo "prebuild"
	@$(MAKE) vendor
	@mkdir -p $(PROJ_BIN_PATH)

.PHONY: postbuild
postbuild:
	@echo "\033[32;1mpostbuild \033[0m"

.PHONY: build
## build: build all server binaries in the `cmd` directory
build: prebuild $(CMDS) postbuild

.PHONY: build-windows
build-windows:
	@echo "build windows"
	@GOARCH=amd64 GOOS=windows go build ${LDFLAGS} -o $(PROJ_BIN_PATH)/minclient.exe ./cmd/minclient

#
# Define targets for commands
#
$(CMDS):
	@echo "building $@"
	@go build ${LDFLAGS} -o $(PROJ_BIN_PATH)/$@ ./cmd/$@

.PHONY: test
## test: launch tests
test: 
	@for d in $$(go list ./... | grep -v /vendor/); do go test -v $${d}; done

.PHONY: clean
## clean: clean build files
clean:
	@go clean
	@rm $(PROJ_BIN_PATH)/* -rf

#todo
#fmt
#vet

