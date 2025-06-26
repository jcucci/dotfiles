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

autoload -U compinit && compinit

zinit cdreplay -q

bindkey -v

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
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -la --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -la --color $realpath'

export ASPNETCORE_ENVIRONMENT=Development
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$PATH:/home/jcucci/.dotnet/tools
export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools
export PATH=$PATH:$DOTNET_ROOT/azure-functions-cli
export PATH=$PATH:$HOME/apps/hawk-4.1.0
export PATH=$PATH:/home/jcucci/.local/share/JetBrains/Toolbox/apps/rider/bin/
export PATH=$PATH:/home/jcucci/.npm-global/bin
export NUGET_CREDENTIALPROVIDER_SESSIONTOKENCACHE_ENABLED="true"
export VISUAL="nvim"
export EDITOR="nvim"
export XDG_DATA_DIRS="/usr/local/share:/usr/share"
export MOZ_ENABLE_WAYLAND=1
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# general
alias claude="/home/jcucci/.claude/local/claude"
alias ls='eza --color --oneline'
alias la='eza -la --color --icons'
alias cls='clear'
alias zsource='source ~/.config/zsh/.zshrc'
alias wineclip='wl-paste -t text -w xclip -selection clipboard'
alias cat='bat'
alias ff='fastfetch'

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
    source_env_file '/home/jcucci/.config/zsh/ninja.env'
}

source_env_file '/home/jcucci/.config/zsh/dev.env'
[ -f ~/.config/zsh/azure.zsh ] && source ~/.config/zsh/azure.zsh
[ -f ~/.config/zsh/claude.zsh ] && source ~/.config/zsh/claude.zsh
[ -f ~/.config/zsh/dotnet.zsh ] && source ~/.config/zsh/dotnet.zsh
[ -f ~/.config/zsh/docker.zsh ] && source ~/.config/zsh/docker.zsh
[ -f ~/.config/zsh/git.zsh ] && source ~/.config/zsh/git.zsh
[ -f ~/.config/zsh/kubernetes.zsh ] && source ~/.config/zsh/kubernetes.zsh

eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
