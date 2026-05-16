# --- Brave ---
# Switch the active Brave Search API key loaded from macOS Keychain.
function brave-switch() {
  if ! command -v security >/dev/null 2>&1; then
    echo "Error: macOS security command is not available."
    return 1
  fi

  local search_key_label='Brave Search api key'
  local inference_key_label='Brave Search Inference api key'
  local search_key_value
  local inference_key_value

  search_key_value="$(security find-generic-password -l "$search_key_label" -w 2>/dev/null)"
  inference_key_value="$(security find-generic-password -l "$inference_key_label" -w 2>/dev/null)"

  if [[ -z "$search_key_value" || -z "$inference_key_value" ]]; then
    echo "Error: Could not find one or both Brave API keys in the keychain."
    echo "Please ensure entries exist for '$search_key_label' and '$inference_key_label'."
    return 1
  fi

  if [[ "$BRAVE_SEARCH_API_KEY" == "$inference_key_value" ]]; then
    export BRAVE_SEARCH_API_KEY="$search_key_value"
    echo "Switched to Brave standard SEARCH key."
  else
    export BRAVE_SEARCH_API_KEY="$inference_key_value"
    echo "Switched to Brave INFERENCE key."
  fi

  echo "Active Key: ...${BRAVE_SEARCH_API_KEY: -4}"
}
