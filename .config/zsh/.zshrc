ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

zinit ice depth=1
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-history-substring-search  # must load after syntax-highlighting
zinit light hlissner/zsh-autopair

# Oh My Zsh snippets
zinit snippet OMZL::clipboard.zsh
zinit snippet OMZP::colored-man-pages
zinit snippet OMZP::extract             # `extract <archive>` for any archive type
zinit snippet OMZP::copypath            # copy current dir path to clipboard
[[ "$OSTYPE" == linux* ]] && zinit snippet OMZP::archlinux

# Completions for CLIs that generate their own. Cached in $ZDOTDIR/completions;
# delete that directory (or a single _file) to regenerate after an upgrade.
ZSH_COMPLETIONS_DIR="$ZDOTDIR/completions"
mkdir -p "$ZSH_COMPLETIONS_DIR"
_gen_completion() {  # _gen_completion <name> <command...>
  local name=$1; shift
  (( $+commands[$1] )) || return
  [[ -s "$ZSH_COMPLETIONS_DIR/_$name" ]] || "$@" > "$ZSH_COMPLETIONS_DIR/_$name" 2>/dev/null
}
_gen_completion gh       gh completion -s zsh
_gen_completion mise     mise completion zsh
_gen_completion rustup   rustup completions zsh
_gen_completion cargo    rustup completions zsh cargo
_gen_completion docker   docker completion zsh
_gen_completion dotnet   dotnet completions script zsh
_gen_completion herdr    herdr completion zsh
_gen_completion uv       uv generate-shell-completion zsh
_gen_completion kubectl  kubectl completion zsh
unfunction _gen_completion
fpath=("$ZSH_COMPLETIONS_DIR" $fpath)

autoload -U compinit && compinit

zinit cdreplay -q

bindkey -v
export KEYTIMEOUT=1  # snappier Esc into vi normal mode

# History substring search: type a prefix, then Up/Down (or k/j in normal mode)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^p' history-substring-search-up
bindkey '^n' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down
bindkey '^y' autosuggest-accept  # accept the grey suggestion (Right arrow also works)

HISTSIZE=5000
HISTFILE=~/.config/zsh/history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt globdots

if [[ "$ARGV0" == "/opt/cursor-bin/cursor-bin.AppImage" ]]; then
  unset ARGV0
fi

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
zstyle ':completion:*:descriptions' format '[%d]'           # lets fzf-tab group results
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':fzf-tab:*' switch-group '<' '>'                     # cycle groups in fzf-tab
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -la --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -la --color $realpath'

export ASPNETCORE_ENVIRONMENT=Development
# Auto-detect DOTNET_ROOT based on OS
if [ -d "/usr/local/share/dotnet" ]; then
    export DOTNET_ROOT=/usr/local/share/dotnet
elif [ -d "/usr/share/dotnet" ]; then
    export DOTNET_ROOT=/usr/share/dotnet
fi
export PATH=$PATH:$HOME/.dotnet/tools
export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools
export PATH=$PATH:$DOTNET_ROOT/azure-functions-cli
export PATH=$PATH:$HOME/apps/hawk-4.1.0
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/.npm-global/bin
export NUGET_CREDENTIALPROVIDER_SESSIONTOKENCACHE_ENABLED="true"
# Use DOTNET_ROOT to set MSBuildSDKsPath dynamically
command -v dotnet &>/dev/null && export MSBuildSDKsPath=$DOTNET_ROOT/sdk/$(dotnet --version)/Sdks
export VISUAL="nvim"
export EDITOR="nvim"
export XDG_DATA_DIRS="/usr/local/share:/usr/share"
export MOZ_ENABLE_WAYLAND=1
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# general
alias ls='eza --color --oneline'
alias la='eza -la --color --icons'
alias cls='clear'
alias zsource='source ~/.config/zsh/.zshrc'
alias wineclip='wl-paste -t text -w xclip -selection clipboard'
alias cat='bat'
alias ff='fastfetch'
alias oc="opencode"
alias weavr="$HOME/projects/weavr/target/debug/weavr"
alias ns="$HOME/projects/nimbus-station/src/NimbusStation.Cli/bin/Debug/net10.0/ns"

untar() {
    tar -xvzf $1
}

source_env_file() {
  local file="$1"

  if [ -z "$file" ]; then
    echo "Usage: source_file <file>"
    return 1
  fi

  if [ ! -f "$file" ]; then
    echo "Error: File '$file' not found."
    return 1
  fi

  set -a
  source "$file"
  set +a
}

ninjasource() {
    source_env_file "$HOME/.config/zsh/ninja.env"
}

ninjatestsource() {
    source_env_file "$HOME/.config/zsh/ninja-api-tests.env"
}

[ -f ~/.config/zsh/dev.env ] && source_env_file $HOME/.config/zsh/dev.env
[ -f ~/.config/zsh/azure.zsh ] && source ~/.config/zsh/azure.zsh
[ -f ~/.config/zsh/claude.zsh ] && source ~/.config/zsh/claude.zsh
[ -f ~/.config/zsh/dotnet.zsh ] && source ~/.config/zsh/dotnet.zsh
[ -f ~/.config/zsh/docker.zsh ] && source ~/.config/zsh/docker.zsh
[ -f ~/.config/zsh/git.zsh ] && source ~/.config/zsh/git.zsh
[ -f ~/.config/zsh/jj.zsh ] && source ~/.config/zsh/jj.zsh
[ -f ~/.config/zsh/kubernetes.zsh ] && source ~/.config/zsh/kubernetes.zsh
[ -f ~/.config/zsh/worktree.zsh ] && source ~/.config/zsh/worktree.zsh
[ -f ~/.config/zsh/android.zsh ] && source ~/.config/zsh/android.zsh

eval "$(fzf --zsh)"
command -v mise &>/dev/null && eval "$(mise activate zsh)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
# atuin: searchable shell history on Ctrl+R (loaded after fzf so it owns Ctrl+R).
# Up arrow stays with history-substring-search.
if (( $+commands[atuin] )); then
  eval "$(atuin init zsh --disable-up-arrow)"
  bindkey -M vicmd '^R' atuin-search-vicmd  # also in vi normal mode
fi
# direnv: load/unload a project's .envrc on cd
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

