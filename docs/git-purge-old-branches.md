# git-purge-old-branches

`git-purge-old-branches` lists or deletes branches whose last commit is older
than a configured age. Git exposes it as:

```sh
git purge-old-branches
git pob
```

The command is dry-run by default.

Use `-h` for help through Git, as `git pob --help` asks Git to open a manpage.

## Examples

List stale local branches:

```sh
git purge-old-branches
```

List branches older than two months:

```sh
git purge-old-branches --older-than 2.months.ago
```

Delete stale local branches using safe Git deletion:

```sh
git purge-old-branches --delete
```

`--delete` uses `git branch -d`, so unmerged branches are not removed.

Restrict deletion to branches already merged into `main`:

```sh
git purge-old-branches --merged-base main --delete
```

List stale remote branches:

```sh
git purge-old-branches --remote origin
```

Remote mode runs `git fetch --prune REMOTE` before listing candidates so stale
remote-tracking refs do not linger locally.

Delete stale remote branches:

```sh
git purge-old-branches --remote origin --delete
```

## Safety

- Dry-run by default.
- Protected branches are skipped.
- Current local branch is skipped.
- Local deletion uses `git branch -d`, not `-D`.
- Remote deletion requires both `--remote` and `--delete`.

Default protected branch list:

```text
main,master,dev,test,stage,staging
```
