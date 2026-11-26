# Route Claude Code to the right config dir.
#   Linux                     -> ~/.claude (single account)
#   macOS ~/projects/sharp/*  -> enterprise account (~/.claude, the default)
#   macOS everything else     -> personal account   (~/.claude-personal)
_claude_config_dir() {
    if [[ "$OSTYPE" != darwin* ]]; then
        print -r -- "$HOME/.claude"
        return
    fi
    case "$PWD/" in
        "$HOME/projects/sharp/"*) print -r -- "$HOME/.claude" ;;
        *)                        print -r -- "$HOME/.claude-personal" ;;
    esac
}

# Routing is inlined (not delegated to _claude_config_dir) so the function still
# works when copied alone, e.g. into Claude Code's shell snapshot; an empty
# CLAUDE_CONFIG_DIR makes the CLI write its config into the current directory.
claude() {
    local config_dir="$HOME/.claude"
    [[ "$OSTYPE" == darwin* && "$PWD/" != "$HOME/projects/sharp/"* ]] && config_dir="$HOME/.claude-personal"
    CLAUDE_CONFIG_DIR="$config_dir" command claude "$@"
}

alias cld='claude'
alias cldc='claude --continue'
alias cldr='claude --resume'
alias cldu='claude update'
alias cldd='claude doctor'
alias cldmcp='claude mcp'
alias cldusage='npx ccusage@latest'
alias cldtrace='npx @mariozechner/claude-trace'

# One-shot print-mode query, routed through the account wrapper
ccp() {
    claude -p "$*"
}