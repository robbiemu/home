# ---- zsh-tips-agent ----
TIPS_AGENT_DIR="${ZSH_TIPS_AGENT_DIR:-$HOME/.local/lib/zsh-tips-agent}"
if [[ -d "$TIPS_AGENT_DIR" ]]; then
  DATA_DIR="$HOME/.local/share/zsh-tips-agent/data"
  TIP_CACHE_FILE="$DATA_DIR/current_tip.txt"
  UPDATE_SCRIPT="$TIPS_AGENT_DIR/bin/update_tip_cache.sh"
  ZSH_TIPS_AGENT_LOG="$HOME/.local/share/zsh-tips-agent/last-run.log"
  TIP_AGE_HOURS=2

  tip_is_fresh() {
    [[ ! -f "$TIP_CACHE_FILE" ]] && return 1
    now=$(date +%s)
    filetime=$(stat -f %m "$TIP_CACHE_FILE" 2>/dev/null || stat -c %Y "$TIP_CACHE_FILE" 2>/dev/null)
    (( ((now - filetime)/3600) < TIP_AGE_HOURS ))
  }

  [[ -f "$TIP_CACHE_FILE" ]] && cat "$TIP_CACHE_FILE"

  if ! tip_is_fresh; then
    if [[ -x "$UPDATE_SCRIPT" ]]; then
      echo "--- Running update_tip_cache.sh at $(date) ---" >> "$ZSH_TIPS_AGENT_LOG"
      { PROJECT_DIR="$TIPS_AGENT_DIR" "$UPDATE_SCRIPT" --verbose >> "$ZSH_TIPS_AGENT_LOG" 2>&1 & } 2>/dev/null
      echo "--- Finished update_tip_cache.sh ---" >> "$ZSH_TIPS_AGENT_LOG"
    fi
  fi
fi
# ---- /zsh-tips-agent ----
