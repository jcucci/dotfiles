alias kubectl='kubecolor'
alias k='kubectl'

kpods() {
    local namespace=`kubectl get ns | sed 1d | awk '{print $1}' | fzf`
    kubectl get pods -n $namespace "$@"
}

kpodsw() {
    local namespace=`kubectl get ns | sed 1d | awk '{print $1}' | fzf`
    kubectl get pods -n $namespace --watch "$@"
}

kenv() {
    local namespace=`kubectl get ns | sed 1d | awk '{print $1}' | fzf`
    local pod=`kubectl get pods -n $namespace | sed 1d | awk '{print $1}' | fzf`
    kubectl exec -n $namespace -it $pod -- env
}

function klogs {
    local namespace=`kubectl get ns | sed 1d | awk '{print $1}' | fzf`
    local pod=`kubectl get pods -n $namespace | sed 1d | awk '{print $1}' | fzf`

    kubectl -n $namespace logs $pod "$@"
}

function kshell {
    local namespace=`kubectl get ns | sed 1d | awk '{print $1}' | fzf`
    local container=`kubectl get container | set 1d | awk '{print $1}' | fzf`
    local pod=`kubectl get pods -n $namespace | sed 1d | awk '{print $1}' | fzf`

    if [ -z $1 ]
    then
        kubectl -n $namespace exec -ti $pod -- bash
    else
        kubectl -n $namespace exec -ti $pod -- $1
    fi
}

