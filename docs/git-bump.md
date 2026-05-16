# git-bump

`git-bump` triggers a GitHub Actions `workflow_dispatch` run without touching
the working tree. It replaces the old pattern of creating a no-op README commit
just to make Actions run.

Git exposes it as:

```sh
git bump
```

## Defaults

- Workflow: `bump.yml`
- Ref: current Git branch
- Label input name: `label`

These can be configured per repository:

```sh
git config --local bump.workflow release.yml
git config --local bump.ref main
git config --local bump.labelInput version
```

## Examples

Trigger `bump.yml` on the current branch:

```sh
git bump
```

Trigger the default workflow on `main` with a label input:

```sh
git bump main release-2026-05-15
```

Trigger a specific workflow:

```sh
git bump --workflow release.yml --ref main
```

Pass workflow inputs:

```sh
git bump --workflow release.yml --ref main -f version=1.2.3 -f channel=stable
```

Use JSON inputs:

```sh
git bump --workflow release.yml --ref main --json inputs.json
```

Preview the `gh` command:

```sh
git bump main release-2026-05-15 --dry-run
```

## Requirements

- GitHub CLI (`gh`)
- A workflow with `on.workflow_dispatch`
- GitHub auth with permission to trigger Actions
