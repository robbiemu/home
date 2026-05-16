# TODO

## Privileged Local Follow-Up

These are local machine administration tasks that need `sudo` or the Homebrew
owner/admin account. They are intentionally not automated by the repo verifier.

- Restore intended ownership for installed `/usr/local/lib` helper scripts if
  they should remain owned by a dedicated Homebrew owner account:

  ```sh
  sudo chown <brew-admin-user>:staff \
    /usr/local/lib/brew-admin.sh \
    /usr/local/lib/git-safestart.sh \
    /usr/local/lib/git-co.sh \
    /usr/local/lib/git-bump.sh \
    /usr/local/lib/zip_project.sh \
    /usr/local/lib/git-purge-old-branches.sh
  ```

- Refresh the root-owned command symlinks after any install target changes:

  ```sh
  sudo ln -sf /usr/local/lib/brew-admin.sh /usr/local/bin/brew-admin
  sudo ln -sf /usr/local/lib/git-safestart.sh /usr/local/bin/git-safestart
  sudo ln -sf /usr/local/lib/git-co.sh /usr/local/bin/git-co
  sudo ln -sf /usr/local/lib/git-bump.sh /usr/local/bin/git-bump
  sudo ln -sf /usr/local/lib/zip_project.sh /usr/local/bin/zip_project
  sudo ln -sf /usr/local/lib/git-purge-old-branches.sh /usr/local/bin/git-purge-old-branches
  sudo ln -sf /usr/local/lib/git-purge-old-branches.sh /usr/local/bin/git-pob
  ```

- Retire the obsolete one-time `git-clean-repo` helper:

  ```sh
  sudo rm -f /usr/local/bin/git-clean-repo /usr/local/lib/git-clean-repo.sh
  ```

- Retire the old Homebrew wrapper name after `brew-admin` is installed:

  ```sh
  sudo rm -f /usr/local/bin/brew-macadmin /usr/local/lib/brew-macadmin.sh
  ```

- Decide whether `/usr/local/lib` helper ownership should standardize on
  a dedicated admin account, `root:wheel`, or the installing user. The repo
  currently documents the commands, but the local machine policy should be
  explicit.

- After privileged cleanup, run:

  ```sh
  tools/verify
  zip_project --help
  git safestart -h
  git co -h
  git pob -h
  ```
