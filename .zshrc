# Base zshrc. Optional machine-specific sections are injected by tools/install
# from dotfiles/zshrc.d when they are configured.
typeset -U path PATH

home_repo_zsh_config="${HOME_REPO_ZSH_CONFIG:-$HOME/.config/home-repo/paths.zsh}"
[[ -r "$home_repo_zsh_config" ]] && source "$home_repo_zsh_config"

function home_repo_prepend_path_if_dir() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  case ":$PATH:" in
    *:"$dir":*) ;;
    *) path=("$dir" $path) ;;
  esac
}

function home_repo_export_dir() {
  local name="$1"
  local fallback="${2:-}"
  local current="${(P)name:-}"

  if [[ -n "$current" ]]; then
    export "$name=$current"
  elif [[ -n "$fallback" && -d "$fallback" ]]; then
    export "$name=$fallback"
  fi
}

home_repo_prepend_path_if_dir "$HOME/.local/bin"

alias cd..="cd .."

if [[ "$OSTYPE" == darwin* ]]; then
  alias ls="ls -G -h"
  alias lsf="ls -G -sh"
  alias lsr="ls -G -ltrh"
  alias lsrf="ls -G -ltrh"
else
  alias ls="ls --color=auto -h"
  alias lsf="ls --color=auto -sh"
  alias lsr="ls --color=auto -ltrh"
  alias lsrf="ls --color=auto -ltrh"
fi

function lsd() {
  local target
  local -a dirs ls_args targets

  if [[ "$OSTYPE" == darwin* ]]; then
    ls_args=(-G -d)
  else
    ls_args=(--color=auto -d)
  fi

  targets=("$@")
  (( ${#targets} )) || targets=(.)

  for target in "${targets[@]}"; do
    dirs=("$target"/*(/DN))
    (( ${#dirs} )) && command ls "${ls_args[@]}" "${dirs[@]}"
  done
}

function calc() {
    local verbose=false
    local expr=""

    # Check for --verbose flag
    for arg in "$@"; do
        if [[ "$arg" == "--verbose" ]]; then
            verbose=true
        else
            expr+="$arg "
        fi
    done

    # Replace multiple symbols with standard ones
    expr=$(echo "$expr" | sed 's/[x×⋅]/*/g; s/[÷]/\//g; s/[＋]/+/g; s/[−]/-/g')

    # Display debug info if --verbose is enabled
    if $verbose; then
        echo "Debug: Expression to be passed to bc -> '$expr'"
    fi

    # Evaluate the expression
    echo "$expr" | bc
}

setopt extendedglob globstarshort
function concat_md() {
    local output="combined.md"
    : > "$output"  # truncate output file

    for file in "$@"; do
        for resolved in ${(f)"$(echo $file)"}; do
            [[ -f $resolved ]] || continue
            echo -e "# -- ## $resolved ##\n" >> "$output"
            cat "$resolved" >> "$output"
            echo -e "\n" >> "$output"
        done
    done
    echo "Output written to $output"
}

alias mkdir='mkdir -p -v'

HISTSIZE=10000
SAVEHIST=10000
