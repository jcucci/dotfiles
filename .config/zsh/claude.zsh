alias cld='claude'
alias cldc='claude --continue'
alias cldr='claude --resume'
alias cldu='claude update'
alias cldd='claude doctor'
alias cldmcp='claude mcp'
alias cldusage='npx ccusage@latest'
alias cldtrace='npx @mariozechner/claude-trace'

# Quick commit with Claude Code
cccommit() {
    claude --prompt "Review these changes and create a commit" --no-interactive
}

# Ask Claude to fix errors in current directory
ccfix() {
    local pattern=${1:-"error\|Error\|ERROR"}
    claude --prompt "Fix any $pattern issues in the current directory"
}

# Ask Claude to explain code
ccexplain() {
    if [ "$1" ]; then
        claude --prompt "Explain this code: $1"
    else
        claude --prompt "Explain the code in the current file"
    fi
}

# Ask Claude to add tests
cctest() {
    local file=${1:-"."}
    claude --prompt "Add comprehensive tests for $file"
}

# Ask Claude to refactor code
ccrefactor() {
    local target=${1:-"current file"}
    claude --prompt "Refactor and improve the $target following best practices"
}

# Ask Claude to review code
ccreview() {
    local target=${1:-"current changes"}
    claude --prompt "Review the $target and suggest improvements"
}

# Ask Claude to add documentation
ccdocs() {
    local target=${1:-"current file"}
    claude --prompt "Add comprehensive documentation to the $target"
}

# Quick bug fix with context
ccbug() {
    if [ "$1" ]; then
        claude --prompt "Help me debug this issue: $1"
    else
        claude --prompt "Help me debug the current issue"
    fi
}