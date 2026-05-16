# zip_project

`zip_project` creates a zip archive from files known to Git:

- tracked files
- untracked files that are not ignored by `.gitignore`

It must be run inside a Git repository.

## Usage

```sh
zip_project
zip_project --output project.zip
zip_project --filter
zip_project --filter '\.(py|md)$'
zip_project --exclude '^tests/'
zip_project --force
```

By default, the command refuses to overwrite an existing output file. Pass
`--force` to replace it.

`--filter` without a regex uses a default source/documentation extension set.

The command stages files in a temporary directory, zips that staging directory,
and removes the temporary directory on exit.
