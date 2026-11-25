ZDOTDIR="/Users/joe.cucci/.config/zsh"
. "$HOME/.cargo/env"

# SSH commands skip .zprofile, so Homebrew's hc isn't found
if [[ -n "$SSH_CONNECTION" && -d /opt/homebrew/bin && ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
  export PATH="$PATH:/opt/homebrew/bin"
fi
