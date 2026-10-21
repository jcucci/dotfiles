alias g='git'
alias gch='git checkout'
alias gst='git status'
alias gpl='git pull'
alias gf='git fetch'
alias gma='git merge --abort'
alias gmerged='git branch --merged'
alias gcm='git commit -m'
alias gca='git commit -a -m'

gps() {
    git push 2>/dev/null || git push -u origin HEAD
}

gcp() {
    git checkout $1
    git pull
}

# Merge <source> (default: current branch) into <target>, push, and return.
# If <target> is checked out in another worktree, merge there instead of trying
# to check it out here (git refuses), so this works from any worktree.
# Stops at the first failure rather than carrying on against the wrong branch.
_git_merge_into() {
    local target=$1 source=${2:-$(git branch --show-current)} msg=$3
    local dir
    dir=$(git worktree list --porcelain | awk -v ref="refs/heads/$target" \
        '/^worktree /{p=substr($0,10)} $0=="branch " ref{print p; exit}')

    if [[ -n "$dir" && "$dir" != "$(git rev-parse --show-toplevel)" ]]; then
        git -C "$dir" pull && git -C "$dir" merge "$source" -m "$msg" && git -C "$dir" push
    else
        git checkout "$target" && git pull && git merge "$source" -m "$msg" && git push && git checkout "$source"
    fi
}

gmn() {
    _git_merge_into ninja "$1" "Merge for ninja"
}

gmt() {
    _git_merge_into gateway "$1" "Merge for gateway"
}

gm() {
    git merge $1 -m $2
}

gbdel() {
    git branch -d $1
    git push origin --delete $1
}

gcd() {
  commit=$(git log --pretty="%H %s" --graph | fzf | awk '{print $2}')
  if [ -n "$commit" ]; then
    git show --pretty="" --color=always $commit | delta
  fi
}

