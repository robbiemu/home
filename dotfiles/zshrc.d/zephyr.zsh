# --- Zephyr SDK ---
home_repo_export_dir ZEPHYR_SDK_INSTALL_DIR "$HOME/.local/zephyr-sdk-0.16.8"
home_repo_export_dir ZEPHYR_BASE "$HOME/zmk-work/app/zephyr"
if [[ -n "${ZEPHYR_SDK_INSTALL_DIR:-}" || -n "${ZEPHYR_BASE:-}" || -n "${ZEPHYR_TOOLCHAIN_VARIANT:-}" ]]; then
  export ZEPHYR_TOOLCHAIN_VARIANT="${ZEPHYR_TOOLCHAIN_VARIANT:-zephyr}"
fi
