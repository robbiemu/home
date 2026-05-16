# --- API Key Management ---
# Secrets are loaded on demand from macOS Keychain; do not commit secret values.
# Linux equivalent: use Secret Service/secret-tool for desktops, or pass for
# headless systems.
typeset -A api_keys
api_keys=(
  "GEMINI_API_KEY" "Google Gemini API key"
  "GOOGLE_SEARCH_API_KEY" "Google Search api key"
  "CSE_ID" "Google Search - selfenrichment - CSE ID"
  "LANGSMITH_API_KEY" "Langsmith api key"
  "CEREBRAS_API_KEY" "Cerebras api key"
  "OPENAI_API_KEY" "OpenAI api key"
  "HF_TOKEN" "HuggingFace api token"
  "GH_PUBLIC_REPOS" "GitHub public repos token"
  "BRAVE_SEARCH_API_KEY" "Brave Search api key"
  "CRATES_IO_TOKEN" "crates.io publishing token"
)

function setvar() {
  if ! command -v security >/dev/null 2>&1; then
    echo "Error: macOS security command is not available."
    return 1
  fi

  local key_name
  for key_name in "$@"; do
    if [[ "$key_name" == "GOOGLE_SEARCH_API_KEY" ]]; then
      export "$key_name"="$(security find-generic-password -l "${api_keys[$key_name]}" -w)"
      echo "Set $key_name"
      export "CSE_ID"="$(security find-generic-password -l "${api_keys[CSE_ID]}" -w)"
      echo "Set CSE_ID"
    elif [[ "$key_name" == "BRAVE_SEARCH_API_KEY" ]]; then
      export BRAVE_SEARCH_API_KEY="$(security find-generic-password -l 'Brave Search Inference api key' -w)"
      echo "Set BRAVE_SEARCH_API_KEY to INFERENCE key."
    elif [[ -n "${api_keys[$key_name]}" ]]; then
      export "$key_name"="$(security find-generic-password -l "${api_keys[$key_name]}" -w)"
      echo "Set $key_name"
    else
      echo "Unknown key: $key_name"
    fi
  done
}

function listvar() {
  local key
  echo "Available API keys:"
  for key in "${(@k)api_keys}"; do
    if [[ "$key" == "CSE_ID" ]]; then
      continue
    elif [[ "$key" == "GOOGLE_SEARCH_API_KEY" ]]; then
      echo "  - $key (includes CSE_ID)"
    elif [[ "$key" == "BRAVE_SEARCH_API_KEY" ]]; then
      echo "  - $key (setvar sets to inference, use brave-switch to toggle)"
    else
      echo "  - $key"
    fi
  done
}
