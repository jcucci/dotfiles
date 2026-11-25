ZDOTDIR="$HOME/.config/zsh"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -d "$HOME/.cargo/bin" ] && case ":$PATH:" in *":$HOME/.cargo/bin:"*) ;; *) PATH="$HOME/.cargo/bin:$PATH" ;; esac
[ -d "$HOME/go/bin" ] && case ":$PATH:" in *":$HOME/go/bin:"*) ;; *) PATH="$PATH:$HOME/go/bin" ;; esac

# Omarchy: OMARCHY_PATH plus mise shims/wrappers and ~/.local/bin on PATH
[ -r /usr/share/omarchy/default/bash/env-bootstrap ] && . /usr/share/omarchy/default/bash/env-bootstrap

# SSH commands skip .zprofile, so Homebrew's hc isn't found
if [[ -n "$SSH_CONNECTION" && -d /opt/homebrew/bin && ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
  export PATH="$PATH:/opt/homebrew/bin"
fi
