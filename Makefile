.PHONY: verify install install-user install-local install-all install-dotfiles install-zsh-section list-zsh-sections install-obsidian-interlink setup-obsidian-interlink-cron install-brew-admin install-git-safestart install-git-co install-git-bump install-zip-project install-git-purge-old-branches configure-git-safestart

verify:
	tools/verify

install: install-user

install-user:
	tools/install --user

install-local:
	tools/install --local

install-all:
	tools/install --all

install-dotfiles:
	tools/install --dotfiles --prompt

ZSH_SECTION ?=

install-zsh-section:
	@test -n "$(ZSH_SECTION)" || { echo "Set ZSH_SECTION=<name>."; exit 1; }
	tools/install --dotfiles --prompt --zsh-section "$(ZSH_SECTION)"

list-zsh-sections:
	@find dotfiles/zshrc.d -type f -name '*.zsh' -exec basename {} .zsh \; | sort

install-obsidian-interlink:
	tools/install --user --only obsidian-interlink-agent --only setup-obsidian-interlink-cron

AGENTIC_RUNTIME ?=
AGENTIC_ONE_OFF_CMD ?=
OBSIDIAN_VAULT_DIR ?=

setup-obsidian-interlink-cron: install-obsidian-interlink
	AGENTIC_RUNTIME="$(AGENTIC_RUNTIME)" AGENTIC_ONE_OFF_CMD="$(AGENTIC_ONE_OFF_CMD)" OBSIDIAN_VAULT_DIR="$(OBSIDIAN_VAULT_DIR)" "$(HOME)/.local/bin/setup-obsidian-interlink-cron" --prompt

install-brew-admin:
	tools/install --local --only brew-admin

install-git-safestart:
	tools/install --local --only git-safestart

install-git-co:
	tools/install --local --only git-co

install-git-bump:
	tools/install --local --only git-bump

install-zip-project:
	tools/install --local --only zip_project

install-git-purge-old-branches:
	tools/install --local --only git-purge-old-branches

REPO ?= .
DEFAULT_COMMAND ?=
SAFE_BRANCH ?=
SAFE_BRANCH_PATTERN ?=
SUBMODULES ?=

configure-git-safestart:
	REPO="$(REPO)" DEFAULT_COMMAND="$(DEFAULT_COMMAND)" SAFE_BRANCH="$(SAFE_BRANCH)" SAFE_BRANCH_PATTERN="$(SAFE_BRANCH_PATTERN)" SUBMODULES="$(SUBMODULES)" tools/configure-git-safestart --prompt
