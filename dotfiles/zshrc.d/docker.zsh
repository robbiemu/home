# --- Docker ---
home_repo_export_dir DOCKER_COMPLETIONS_DIR "$HOME/.docker/completions"
if [[ -n "${DOCKER_COMPLETIONS_DIR:-}" && -d "$DOCKER_COMPLETIONS_DIR" ]]; then
  fpath=("$DOCKER_COMPLETIONS_DIR" $fpath)
  autoload -Uz compinit
  compinit -u
fi
