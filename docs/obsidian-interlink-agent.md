# obsidian-interlink-agent

`obsidian-interlink-agent` runs one recurring maintenance pass over an Obsidian
vault. It sends a prompt to a configured one-off agent command and asks it to add
Obsidian wikilinks between Markdown notes.

`setup-obsidian-interlink-cron` installs the cron entry for that runner.

## Configuration

These are command/path settings, not secrets:

```sh
export AGENTIC_RUNTIME=codex
export AGENTIC_ONE_OFF_CMD='codex exec'
export OBSIDIAN_VAULT_DIR="$HOME/Documents/Obsidian"
```

`AGENTIC_RUNTIME` is checked with `command -v` so setup and cron runs can skip
cleanly when the agent is not installed. `AGENTIC_ONE_OFF_CMD` is run from the
vault directory and receives the prompt on stdin.

`AGENTIC_ONE_OFF_CMD` intentionally has no repo default. Configure it only after
confirming the command can run non-interactively from cron.

## Install

```sh
make install-obsidian-interlink
```

or:

```sh
tools/install --user --only obsidian-interlink-agent --only setup-obsidian-interlink-cron
```

## Schedule

Preview the cron setup:

```sh
setup-obsidian-interlink-cron --dry-run
```

Install the default schedule:

```sh
setup-obsidian-interlink-cron
```

From this repo, the Make target installs the two user-level helper commands and
prompts for missing setup values:

```sh
make setup-obsidian-interlink-cron
```

Blank prompt answers skip that setup section without creating a broken cron
entry.

The default schedule is:

```cron
17 */6 * * *
```

Override it:

```sh
setup-obsidian-interlink-cron --schedule '12 9 * * *'
```

Remove the managed cron entry:

```sh
setup-obsidian-interlink-cron --remove
```

The setup command writes a small env file at
`~/.config/home-repo/agentic.env` so cron does not need to source `.zshrc`.

## Safety

- Setup exits successfully without modifying cron when the runner, agent
  runtime, vault, or `crontab` command is missing.
- The runner exits successfully when the vault is missing, empty, or another run
  is already active.
- The prompt tells the agent that it is recurring and should make idempotent
  Markdown-only edits.
