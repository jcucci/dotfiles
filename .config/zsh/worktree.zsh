# Parallel-agent worktree helpers (built on worktrunk; layout in ~/.config/worktrunk/config.toml)

# New worktree + tmux window (Claude on top, shell below). Outside tmux, just creates and cds.
#   wtn <branch> [base-branch]
wtn() {
    local branch=${1:?Usage: wtn <branch> [base-branch]}
    if [[ -n "$TMUX" ]]; then
        ~/.config/tmux/scripts/tmux-worktree-new "$branch" "$PWD" "$2"
    elif git show-ref --verify --quiet "refs/heads/$branch"; then
        wt switch "$branch"
    else
        wt switch --create "$branch" ${2:+--base "$2"}
    fi
}

alias wl='wt list'
alias ws='wt switch'
