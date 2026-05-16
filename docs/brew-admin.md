# brew-admin

`brew-admin` is an optional macOS role-account wrapper for machines where the
daily account is intentionally unprivileged and Homebrew is owned by a separate
admin or maintenance account.

The wrapper runs:

```sh
sudo -u "$BREW_ADMIN_USER" HOME="$BREW_ADMIN_HOME" "$HOMEBREW_PREFIX/bin/brew" "$@"
```

Configuration:

```sh
export BREW_ADMIN_USER=homebrew-admin
export BREW_ADMIN_HOME=/Users/$BREW_ADMIN_USER
export HOMEBREW_PREFIX=/opt/homebrew
```

`BREW_ADMIN_USER` has no built-in account-name default. The older `BREW_ADMIN`
environment variable is still accepted for compatibility.

The local pattern on a machine like this can be configured as:

- daily account: the unprivileged interactive account
- Homebrew owner/admin account: set `BREW_ADMIN_USER` to the local account name
- Homebrew prefix: `/opt/homebrew`
- command exposed on `PATH`: `/usr/local/bin/brew-admin`

## Install

```sh
make install-brew-admin
```

This installs:

```text
/usr/local/lib/brew-admin.sh
/usr/local/bin/brew-admin -> /usr/local/lib/brew-admin.sh
```

## Usage

```sh
brew-admin --prefix
brew-admin update
brew-admin upgrade
brew-admin install jq
```

The active `.zshrc` aliases `brew` to `brew-admin`, so interactive `brew`
commands use the role account.

## Caveat

Homebrew itself is primarily designed for single-user installs, and upstream
documents shared multi-user Homebrew installations as unsupported. This wrapper
keeps Homebrew operations under the Homebrew-owning account instead of running
`sudo brew` as root, but it is still a local machine policy rather than an
upstream-supported Homebrew configuration.

Do not automate broad sudoers rules from this repo. If passwordless operation is
desired, review and install the narrowest possible sudoers rule manually for the
specific wrapper and account on the specific host.
