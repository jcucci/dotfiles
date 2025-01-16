ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

zinit ice depth=1
zinit light zsh-users/zsh-syntax-highlighting
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
export NUGET_CREDENTIALPROVIDER_SESSIONTOKENCACHE_ENABLED="true"
export VISUAL="nvim"
export EDITOR="nvim"
export MOZ_ENABLE_WAYLAND=1

if [ -f ~/.config/zsh/dev.env ]; then
    source ~/.config/zsh/dev.env
fi

# general
alias ls='eza --color'
alias la='eza -la --color'
alias cls='clear'
alias zsource='source ~/.config/zsh/.zshrc'
alias ninjasource='source ~/.config/zsh/ninja.env'
alias wineclip='wl-paste -t text -w xclip -selection clipboard'
alias cat='bat'

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

function klogs {
    local namespace=`kubectl get ns | sed 1d | awk '{print $1}' | fzf`
    local pod=`kubectl get pods -n $namespace | sed 1d | awk '{print $1}' | fzf`
    echo "Showing logs for $pod"

    kubectl -n $namespace logs -f $pod
}

function kshell {
    local namespace=`kubectl get ns | sed 1d | awk '{print $1}' | fzf`
    local container=`kubectl get container | set 1d | awk '{print $1}' | fzf`
    local pod=`kubectl get pods -n $namespace | sed 1d | awk '{print $1}' | fzf`
    echo "Connecting to $pod"

    if [ -z $1 ]
    then
        kubectl -n $namespace exec -ti $pod -- bash
    else
        kubectl -n $namespace exec -ti $pod -- $1
    fi
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

dnversions() {
    if [ -z "$1" ] && [ -z "$2" ]; then
        echo "Usage: dnversions <package_name> [sharpfm] or dnversions [sharpfm] <package_name>"
        return 1
    fi
    
    local package_name
    local is_sharpfm=false
    
    if [ "$1" = "sharpfm" ]; then
        is_sharpfm=true
        package_name="$2"
    elif [ "$2" = "sharpfm" ]; then
        is_sharpfm=true
        package_name="$1"
    else
        package_name="$1"
    fi
    
    if [ -z "$package_name" ]; then
        echo "Error: Package name is required"
        return 1
    fi
    
    if [ "$is_sharpfm" = true ]; then
        if [ -z "$AZURE_DEVOPS_PAT" ]; then
            echo "Error: AZURE_DEVOPS_PAT environment variable not set"
            return 1
        fi
        
        curl -s \
        --header "Accept: application/json" \
        --header "Authorization: Basic $(echo -n ":$AZURE_DEVOPS_PAT" | base64 -w 0)" \
        "https://sharpfm.pkgs.visualstudio.com/_packaging/64eacba0-4a33-4524-a207-22b9304801fa/nuget/v3/query2/?q=$package_name&prerelease=false" | \
        jq --arg pkg "$package_name" '.data[] | select(.id | ascii_downcase == ($pkg | ascii_downcase)) | {name: .id, versions: (.versions | sort_by(.) | reverse | .[0:5])}'
    else
        curl -s "https://api-v2v3search-0.nuget.org/query?q=$package_name&prerelease=false" | \
        jq --arg pkg "$package_name" '.data[] | select(.id | ascii_downcase == ($pkg | ascii_downcase)) | {name: .id, versions: (.versions | sort_by(.) | reverse | .[0:5])}'
    fi
}

dnsearch() {
    if [ -z "$1" ]; then
        echo "Usage: nuget_search <package_name> [sharpfm]"
        return 1
    fi
    
    if [ "$2" = "sharpfm" ]; then
        curl -s \
        --header "Accept: application/json" \
        --header "Authorization: Basic $(echo -n ":$AZURE_DEVOPS_PAT" | base64 -w 0)" \
        "https://sharpfm.pkgs.visualstudio.com/_packaging/64eacba0-4a33-4524-a207-22b9304801fa/nuget/v3/query2/?q=$1&prerelease=false" | \
        jq '[.data[] | {name: .id, version: .version}]'
    else
        curl -s "https://api-v2v3search-0.nuget.org/query?q=$1&prerelease=false" | \
        jq '[.data[] | {name: .id, version: .version}]'
    fi
}

dnsearch() {
    if [ -z "$1" ] && [ -z "$2" ]; then
        echo "Usage: nuget_search <package_name> [sharpfm] or nuget_search [sharpfm] <package_name>"
        return 1
    fi
    
    local package_name
    local is_sharpfm=false
    
    if [ "$1" = "sharpfm" ]; then
        is_sharpfm=true
        package_name="$2"
    elif [ "$2" = "sharpfm" ]; then
        is_sharpfm=true
        package_name="$1"
    else
        package_name="$1"
    fi
    
    if [ -z "$package_name" ]; then
        echo "Error: Package name is required"
        return 1
    fi
    
    if [ "$is_sharpfm" = true ]; then
        if [ -z "$AZURE_DEVOPS_PAT" ]; then
            echo "Error: AZURE_DEVOPS_PAT environment variable not set"
            return 1
        fi
        
        curl -s \
        --header "Accept: application/json" \
        --header "Authorization: Basic $(echo -n ":$AZURE_DEVOPS_PAT" | base64 -w 0)" \
        "https://sharpfm.pkgs.visualstudio.com/_packaging/64eacba0-4a33-4524-a207-22b9304801fa/nuget/v3/query2/?q=$package_name&prerelease=true" | \
        jq '[.data[] | {name: .id, version: .version}]'
    else
        # Public NuGet search
        curl -s "https://api-v2v3search-0.nuget.org/query?q=$package_name&prerelease=false" | \
        jq '[.data[] | {name: .id, version: .version}]'
    fi
}

# azure
kvshow() {
    az keyvault secret show --vault-name king-ninja-sharp-kv -n $1
}

kvset() {
    az keyvault secret set --vault-name king-ninja-sharp-kv -n $1 --value $2
}

# system
untar() {
    tar -xvzf $1
}

eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
