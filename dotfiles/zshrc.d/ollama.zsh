# --- Ollama ---
function ollama_pull_hf() {
  if [[ "$#" -eq 2 ]]; then
    local full="$1"
    local short="$2"
  elif [[ "$#" -eq 3 && "$2" == "as" ]]; then
    local full="$1"
    local short="$3"
  else
    echo "Usage: ollama_pull_hf <full_model_name> [as] <short_name>"
    return 1
  fi

  if ! command -v ollama >/dev/null 2>&1; then
    echo "Error: ollama command is not available."
    return 1
  fi

  ollama pull "$full" && ollama cp "$full" "$short" && ollama rm "$full"
}

export OLLAMA_API_BASE="${OLLAMA_API_BASE:-http://127.0.0.1:11434}"
export OLLAMA_FLASH_ATTENTION="${OLLAMA_FLASH_ATTENTION:-1}"
export OLLAMA_KV_CACHE_TYPE="${OLLAMA_KV_CACHE_TYPE:-q8_0}"
export OLLAMA_CONTEXT_LENGTH="${OLLAMA_CONTEXT_LENGTH:-131072}"
export OLLAMA_DEFAULT_MODEL="${OLLAMA_DEFAULT_MODEL:-qwen3:8b-q4_K_M}"
export OLLAMA_DEFAULT_CODE_MODEL="${OLLAMA_DEFAULT_CODE_MODEL:-qwen3:30b-a3b-q4_K_M}"
export OLLAMA_DEFAULT_REASONING_MODEL="${OLLAMA_DEFAULT_REASONING_MODEL:-qwen3:30b-a3b-q4_K_M}"
