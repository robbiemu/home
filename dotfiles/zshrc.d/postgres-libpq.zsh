# --- Postgres ---
home_repo_export_dir LIBPQ_PREFIX "/opt/homebrew/opt/libpq"
if [[ -n "${LIBPQ_PREFIX:-}" ]]; then
  home_repo_prepend_path_if_dir "$LIBPQ_PREFIX/bin"
  export LDFLAGS="${LDFLAGS:+$LDFLAGS }-L$LIBPQ_PREFIX/lib"
  export CPPFLAGS="${CPPFLAGS:+$CPPFLAGS }-I$LIBPQ_PREFIX/include"
fi
