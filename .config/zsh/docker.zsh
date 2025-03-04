alias d='docker'
alias di='docker images'
alias dc='docker container'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dpull='docker pull'
alias drmi='docker rmi'
alias drim='docker image prune -a -f'
alias dvol='docker volume'
alias dvolrm='docker volume rm'
alias dvolprune='docker volume prune -f'
alias dnet='docker network'
alias dnetrm='docker network rm'
alias dnetprune='docker network prune -f'

alias dcup='docker-compose up'
alias dcdown='docker-compose down'
alias dclogs='docker-compose logs -f'
alias dcb='docker-compose build'
alias dcexec='docker-compose exec'

function select_container() {
  if [[ -n "$1" ]]; then  # Check if an argument was passed
    echo "$1"  # Use the argument as the container name
  elif command -v fzf >/dev/null 2>&1; then
    docker ps --format '{{.Names}}' | fzf
  else
    echo "No container specified and fzf not available."
    return 1
  fi
}

function dclean() {
  docker stop $(docker ps -aq)
  docker rm $(docker ps -aq)
  docker image prune -a -f
  docker volume prune -f
  docker network prune -f
  echo "All containers stopped and removed, unused images/volumes/networks pruned."
}

function dstop() {
  container=$(select_container "$1")
  docker stop "$container"
}

function dstart() {
  container=$(select_container "$1")
  docker start "$container"
}

function drestart() {
  container=$(select_container "$1")
  docker restart "$container"
}

function dkill() {
  container=$(select_container "$1")
  docker kill "$container"
}

function drm() {
  container=$(select_container "$1")
  docker rm "$container"
}

function drmf() {
  container=$(select_container "$1")
  docker rm -f "$container"
}

function denter() {
  container=$(select_container "$1")
  docker exec -it "$container" bash
}

function dip() {
  container=$(select_container "$1")
  docker inspect "$container" | jq -r '.[0].NetworkSettings.IPAddress'
}

function dlogs() {
    container=$(select_container "$1")
    docker logs --timestamps --follow --tail 100 "$container" 2>&1 | \
    while IFS= read -r line; do
        if [[ "$line" == *'ERROR'* || "$line" == *'error'* ]]; then
            echo -e "\e[1;31m$line\e[0m" # Bold Red for errors
        elif [[ "$line" == *'WARN'* || "$line" == *'warn'* || "$line" == *'WARNING'* || "$line" == *'warning'* ]]; then
            echo -e "\e[1;33m$line\e[0m" # Bold Yellow for warnings
        else
            echo "$line"
        fi
    done
}

function dbuild() {
  image_name=$1
  tag=$2
  docker build -t "$image_name:$tag" .
}

function dlogs() {
    container_name="$1"
    docker logs --timestamps --follow --tail 100 "$container_name" 2>&1 | \
    while IFS= read -r line; do
        if [[ "$line" == *'ERROR'* || "$line" == *'error'* ]]; then
            echo -e "\e[1;31m$line\e[0m" # Bold Red for errors
        elif [[ "$line" == *'WARN'* || "$line" == *'warn'* || "$line" == *'WARNING'* || "$line" == *'warning'* ]]; then
            echo -e "\e[1;33m$line\e[0m" # Bold Yellow for warnings
        else
            echo "$line"
        fi
    done
}

function drun() {
  image=$1
  shift  # Remove the image name from the arguments
  command="$*" # Capture all remaining arguments as the command

  docker run --rm "$image" "$command"
}

function cid() {
  container_name=$1
  docker ps -q -f name="$container_name"
}
