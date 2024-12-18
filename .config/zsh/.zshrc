# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

zinit ice depth=1; zinit light romkatv/powerlevel10k
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab

autoload -U compinit && compinit

zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh

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

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -la --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -la --color $realpath'

export ASPNETCORE_ENVIRONMENT=Development
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools
export PATH=$PATH:$DOTNET_ROOT/azure-functions-cli
export PATH=$PATH:$HOME/apps/hawk-4.1.0
export NUGET_CREDENTIALPROVIDER_SESSIONTOKENCACHE_ENABLED="true"
export VISUAL=code
export EDITOR="$VISUAL"
export MOZ_ENABLE_WAYLAND=1

source "/home/jcucci/.config/zsh/dev.env"

# general
alias ls='eza --color'
alias la='eza -la --color'
alias cls='clear'
alias zsource='source ~/.config/zsh/.zshrc'
alias ninjasource='source ~/.config/zsh/ninja.env'
alias wineclip='wl-paste -t text -w xclip -selection clipboard'

# git
alias g='git'
alias gch='git checkout'
alias gst='git status'
alias gpl='git pull'
alias gps='git push'
alias gf='git fetch'
alias gma='git merge --abort'
alias gmerged='git branch --merged'
alias gcm='git commit -m'
alias gca='git commit -a -m'

gcp() {
    git checkout $1
    git pull
}

gmn() {
    git checkout ninja
    git pull
    git merge $1 -m "Merge for ninja"
    git push
    git checkout $1
}

gmt() {
    git checkout gateway
    git pull
    git merge $1 -m "Merge for gateway"
    git push
    git checkout $1
}

gm() {
    git merge $1 -m $2
}

gbdel() {
    git branch -d $1
    git push origin --delete $1
}

# k8s
alias k='kubectl'

kpods() {
    kubectl get pods -n $1
}

kenv() {
    kubectl exec -n $1 -it $2 -- env
}


# dotnet
alias dnpack='dotnet pack -c RELEASE'

dntest() {
    dotnet test $1 -v q --nologo --filter=Category!=Integration
}

dnbuild() {
    dotnet build $1 -v q --nologo
}

dnpush() {
    dotnet nuget push $1 -s "sharpfm" -k az
}

# azure
kvshow() {
    az keyvault secret show --vault-name king-ninja-sharp-kv -n $1
}

kvset() {
    az keyvault secret set --vault-name king-ninja-sharp-kv -n $1 --value $2
}

eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
# eval "$(starship init zsh)"
