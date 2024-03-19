zstyle ':completion:*' completer _complete _ignored
zstyle :compinstall filename '/home/jcucci/.zshrc'

autoload -Uz compinit
compinit

HISTFILE=~/.histfile
HISTSIZE=9000
SAVEHIST=9000
bindkey -v
zstyle ':completion:*' menu select
zstyle ':completion::complete:*' gain-privileges 1

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Aliases
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias la='exa -la'
alias ls='exa'
alias ga='git add *'
alias gst='git status'
alias gpl='git pull'
alias gps='git push'
alias gco='git commit'
alias gch='git checkout'
alias gsh='git stash'

# Environment variables
export VSS_NUGET_EXTERNAL_FEED_ENDPOINTS='{"endpointCredentials": [{"endpoint":"https://sharpfm.pkgs.visualstudio.com/_packaging/sharpfm/nuget/v3/index.json", "username":"jcucci@unlimitedsystems.com", "password":"bfmatgajuvf56ywlogut3ccf3ka7rqrjpnqvsdewdhkq2rigyrdq"}]'

# External initializations
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
