################################################################################
# DEFINES
.DEFAULT_GOAL:=help
SHELL:=/bin/bash

PROJECT_NAME:=presenting.nvim
COMMIT:=$(shell git rev-parse --short HEAD)

################################################################################
##@ Maintenance
.PHONY: all
all: update-readmes fmt lint docs pre-commit ## Runs all the targets

.PHONY: docs
docs: deps ## generates the docs.
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua require('mini.doc').generate()" -c "qa!"

.PHONY: lint
lint:  deps ## run the linter.
	luacheck lua/

.PHONY: fmt
fmt:  deps ## run the formatter.
	stylua .

.PHONY: update-readmes
update-readmes: README.org README.adoc ## Update READMEs from README.md

.PHONY: pre-commit
pre-commit:  ## Run pre-commit on all
	pre-commit run --all

.PHONY: test
test: deps  ## Runs all tests
	echo "TODO: implement tests"
	# nvim --version | head -n 1 && echo ''
	# nvim --headless --noplugin -u ./scripts/minimal_init.lua \
	# 	-c "lua require('mini.test').setup()" \
	# 	-c "lua MiniTest.run({ execute = { reporter = MiniTest.gen_reporter.stdout({ group_depth = 1 }) } })"

.PHONY: examples
examples: ## Generate animated examples
	vhs presentation.tape

################################################################################
deps:  ## installs `mini.nvim`, used for both the tests and documentation.
	@mkdir -p deps
	git clone --depth 1 https://github.com/echasnovski/mini.nvim deps/mini.nvim

README.org: README.md
	pandoc -f markdown -t org -o $@ $^

README.adoc: README.md
	pandoc -f markdown -t asciidoc -o $@ $^

################################################################################
##@ Helpers
.PHONY: clean
clean: ## Cleanup the project folders
	rm -rf deps
	rm -rf docs

.PHONY: help
help:  ## Display this help
	@echo "Welcome to $$(tput bold)${PROJECT_NAME}$$(tput sgr0) 🥳📈🎉"
	@echo ""
	@echo "To get started:"
	@echo "  >>> $$(tput bold)make all$$(tput sgr0)"
	@awk 'BEGIN {FS = ":.*##"; printf "\033[36m\033[0m"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
