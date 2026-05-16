# --- nvm ---
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
nvm_homebrew_prefix="${NVM_HOMEBREW_PREFIX:-/opt/homebrew/opt/nvm}"
[[ -s "$nvm_homebrew_prefix/nvm.sh" ]] && . "$nvm_homebrew_prefix/nvm.sh"
[[ -s "$nvm_homebrew_prefix/etc/bash_completion.d/nvm" ]] && . "$nvm_homebrew_prefix/etc/bash_completion.d/nvm"
unset nvm_homebrew_prefix
