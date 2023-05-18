SHELL := /bin/bash

BINARY_DIR ?= /usr/local/bin

.PHONY: tools
tools:
	$(MAKE) packer
	$(MAKE) vault

.PHONY: packer
packer: URL := https://releases.hashicorp.com/packer/1.8.7/packer_1.8.7_linux_amd64.zip
packer: FILENAME := packer
packer: download_unzip

.PHONY: vault
vault: URL := https://releases.hashicorp.com/vault/1.13.2/vault_1.13.2_linux_amd64.zip
vault: FILENAME := vault
vault: download_unzip

.PHONY: download_unzip
download_unzip: TEMP_FILE ?= $(lastword $(subst /, ,$(URL)))
download_unzip: OUTPUT_FILE = $(PWD)/$(TEMP_FILE)
download_unzip: EXTRACT_FILE = $(BINARY_DIR)/$(FILENAME)
download_unzip:
	[[ -e "$(EXTRACT_FILE)" ]] || \
		(([[ -e "$(OUTPUT_FILE)" ]] || curl -L $(URL) -o $(OUTPUT_FILE)) && \
		sudo unzip $(OUTPUT_FILE) -d $(BINARY_DIR) && \
		rm $(OUTPUT_FILE))
