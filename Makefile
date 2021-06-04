config ?= debug

PACKAGE := protobuf
PROTOC_PLUGIN := protoc-gen-pony
GET_DEPENDENCIES_WITH := corral fetch
CLEAN_DEPENDENCIES_WITH := corral clean
COMPILE_WITH := corral run -- ponyc

BUILD_DIR ?= build/$(config)
SRC_DIR ?= $(PACKAGE)
PROTOC_PLUGIN_SRC ?= $(SRC_DIR)/_plugin
EXAMPLES_DIR := examples
tests_binary := $(BUILD_DIR)/$(PACKAGE)
docs_dir := build/$(PACKAGE)-docs
plugin_binary := build/$(config)/$(PROTOC_PLUGIN)

ifdef config
	ifeq (,$(filter $(config),debug release))
		$(error Unknown configuration "$(config)")
	endif
endif

ifeq ($(config),release)
	PONYC = $(COMPILE_WITH)
else
	PONYC = $(COMPILE_WITH) --debug
endif

# Default to version from `VERSION` file but allowing overridding on the
# make command line like:
# make version="nightly-19710702"
# overridden version *should not* contain spaces or characters that aren't
# legal in filesystem path names
ifndef version
	ifneq ($(wildcard .git),)
		tag := $(shell git rev-parse --short HEAD)
	else
		$(error No possible version selected)
	endif
else
	tag := $(version)
endif

SOURCE_FILES := $(shell find $(SRC_DIR) -name *.pony)
VERSION := "$(tag) [$(config)]"
EXAMPLES := $(notdir $(shell find $(EXAMPLES_DIR)/* -type d))
EXAMPLES_SOURCE_FILES := $(shell find $(EXAMPLES_DIR) -name *.pony)
EXAMPLES_BINARIES := $(addprefix $(BUILD_DIR)/,$(EXAMPLES))

test: unit-tests build-examples

unit-tests: $(tests_binary)
	$^ --exclude=integration --sequential

$(tests_binary): $(SOURCE_FILES) | $(BUILD_DIR)
	$(GET_DEPENDENCIES_WITH)
	$(PONYC) -o $(BUILD_DIR) $(SRC_DIR)

plugin-test: $(plugin_binary)
# 	protoc --pony_out=$(BUILD_DIR) --plugin=$(plugin_binary) $(EXAMPLES_DIR)/addressbook/addressbook.proto
	protoc --pony_out=$(BUILD_DIR) --plugin=$(plugin_binary) proto2/google/protobuf/compiler/plugin.proto

plugin: $(GEN_FILES) $(SOURCE_FILES) | $(BUILD_DIR)
	@sed s/%%VERSION%%/$(VERSION)/ $(PROTOC_PLUGIN_SRC)/version.pony.in > $(PROTOC_PLUGIN_SRC)/version.pony
	$(GET_DEPENDENCIES_WITH)
	$(PONYC) -o $(BUILD_DIR) -b $(PROTOC_PLUGIN) $(PROTOC_PLUGIN_SRC)

build-examples: $(EXAMPLES_BINARIES)

$(EXAMPLES_BINARIES): $(BUILD_DIR)/%: $(SOURCE_FILES) $(EXAMPLES_SOURCE_FILES) | $(BUILD_DIR)
	$(GET_DEPENDENCIES_WITH)
	$(PONYC) -o $(BUILD_DIR) $(EXAMPLES_DIR)/$*

clean:
	$(CLEAN_DEPENDENCIES_WITH)
	rm -rf $(BUILD_DIR)
	rm -rf $(plugin_dir)

$(docs_dir): $(GEN_FILES) $(SOURCE_FILES)
	rm -rf $(docs_dir)
	$(GET_DEPENDENCIES_WITH)
	$(PONYC) --docs-public --pass=docs --output build $(SRC_DIR)

docs: $(docs_dir)

TAGS:
	ctags --recurse=yes $(SRC_DIR)

all: test

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

.PHONY: all build-examples clean test plugin plugin-test