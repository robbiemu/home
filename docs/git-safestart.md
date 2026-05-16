# git-safestart

`git-safestart` generalizes the old project-specific `git-safestart.sh`
workflow. It prepares a repository and its submodules before running the repo's
main command.

The default behavior is pointer-safe:

```sh
git pull --ff-only
git submodule sync --recursive
git submodule update --init --recursive
```

That makes submodules match the commits recorded by the superproject. If a repo
needs selected submodules on a "safe" branch before running, configure those
paths explicitly with a fixed branch or branch naming pattern.

## Install

```sh
make install-git-safestart
```

This installs:

```text
/usr/local/lib/git-safestart.sh
/usr/local/bin/git-safestart -> /usr/local/lib/git-safestart.sh
```

Git will then expose it as:

```sh
git safestart
```

Install the no-run checkout companion:

```sh
make install-git-co
```

Git will then expose it as:

```sh
git co
```

## Configure A Local Repo

Use the Makefile from this repo to write local Git config into another repo:

```sh
make configure-git-safestart \
  REPO=/path/to/project \
  DEFAULT_COMMAND='npm run dev' \
  SAFE_BRANCH=safestart \
  SUBMODULES='qwireclear-fe-common qwireclear-fe-styleguide'
```

For a branch naming convention instead of one fixed branch:

```sh
make configure-git-safestart \
  REPO=/path/to/project \
  DEFAULT_COMMAND='make serve' \
  SAFE_BRANCH_PATTERN='safe/{branch}' \
  SUBMODULES='common styleguide'
```

If `DEFAULT_COMMAND` is not provided and the target repo does not already have
`safestart.command`, the Make target prompts for it. Submit a blank answer to
skip configuring that repo for now.

Supported placeholders:

- `{branch}`: main repo branch being started.
- `{path}`: configured submodule path.
- `{name}`: basename of the submodule path.

The config is written to the target repo's `.git/config`, not to global Git
config and not to committed files:

```ini
[safestart]
	command = npm run dev
	safeBranch = safestart
	submodule = qwireclear-fe-common
	submodule = qwireclear-fe-styleguide
```

## Usage

Use the current branch:

```sh
git safestart
```

Checkout and pull a specific branch first:

```sh
git safestart --branch feature/foo
```

Override the configured safe branch:

```sh
git safestart --branch feature/foo --safe-branch safestart
```

Override the configured run command:

```sh
git safestart --branch feature/foo -- npm run test
```

Checkout a branch and configured submodules without running the repo command:

```sh
git co feature/foo
```

`git co` is equivalent to:

```sh
git safestart --branch feature/foo --safe-branch-pattern '{branch}' --no-run
```

Preview commands without changing anything:

```sh
git safestart --branch feature/foo --dry-run
git co feature/foo --dry-run
```

## Safety Rules

- Uses `git pull --ff-only`.
- Uses `git submodule update --init --recursive` before any branch override.
- Refuses dirty main repos and dirty configured submodules unless
  `--allow-dirty` is provided.
- Does not run `git reset --hard`, `git clean`, or forced checkout.
- Does not commit local config; each repo opts in independently.
