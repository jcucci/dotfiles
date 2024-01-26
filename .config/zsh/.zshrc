# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/.zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# The following lines were added by compinstall

zstyle ':completion:*' completer _complete _ignored
zstyle :compinstall filename '/home/jcucci/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=9000
SAVEHIST=9000
bindkey -v
# End of lines configured by zsh-newuser-install
source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.config/.zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh

source ~/.config/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

source ~/.config/zsh/fzf-tab/fzf-tab.plugin.zsh

# Aliases
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias z='zoxide'
alias la='exa -la'
alias ls='exa'
alias md='mkdir'
alias cp="cp -i"
alias mv='mv -i'
alias rm='rm -i'
alias df='df -h'     # human-readable sizes  
alias free='free -m' # show sizes in MB
alias cdconf='cd ~/.config'
alias cdnvim='cd ~/.config/nvim'
alias cdca='cd ~/projects/sharp/snowdrop-charge-assemblies-be/'
