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

gcd() {
  commit=$(git log --pretty="%H %s" --graph | fzf | awk '{print $2}')
  if [ -n "$commit" ]; then
    git show --pretty="" --color=always $commit | delta
  fi
}

