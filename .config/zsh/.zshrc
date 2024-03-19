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

# External initializations
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
