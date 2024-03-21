#!/usr/bin/env bash

export FZF_DEFAULT_OPTS="\
--border \
--pointer='» ' \
--marker='◈ ' \
--layout=reverse \
--bind 'ctrl-space:toggle-preview' \
--bind 'ctrl-s:toggle-sort' \
--bind 'ctrl-e:preview-down' \
--bind 'ctrl-y:preview-up' \
--no-height"

RED="${RED:-$(tput setaf 1)}"
GREEN="${GREEN:-$(tput setaf 2)}"
YELLOW="${YELLOW:-$(tput setaf 3)}"
BOLD="${BOLD:-$(tput bold)}"
NORMAL="${NORMAL:-$(tput sgr0)}"

export RED
export GREEN
export YELLOW
export BOLD
export NORMAL

__command_exists() {
  [ -n "$1" ] && type "$1" >/dev/null 2>&1
}

# logging
__log_error() {
  echo "[${RED}${BOLD}ERROR${NORMAL}] $*"
}

__log_warning() {
  echo "[${YELLOW}${BOLD}WARNING${NORMAL}] $*"
}

__log_info() {
  echo "[${GREEN}${BOLD}INFO${NORMAL}] $*"
}

if [ -z "$KUBECTL_YAML_VIEWER" ]; then
  KUBECTL_YAML_VIEWER="less"
  if __command_exists bat; then
    KUBECTL_YAML_VIEWER="bat --color=always --language=yaml --style=plain"
  fi
fi

__kubectl_select_one() {
  SUBJECT=pods
  if [ "$#" -gt 0 ]; then
    SUBJECT="$1"
    shift
  fi

  ARGS="$([ $# -eq 0 ] && printf '' || printf '%q ' "$@")"

  kubectl get "$SUBJECT" "$@" | \
    fzf \
      --no-multi \
      --ansi \
      --header-lines=1 \
      --preview "kubectl get $SUBJECT $ARGS {1} -o yaml | $KUBECTL_YAML_VIEWER" | \
    awk '{ print $1 }'
}

__kubectl_select_resource_type() {
  ARGS="$([ $# -eq 0 ] && printf '' || printf '%q ' "$@")"

  kubectl api-resources "$@" | \
    fzf \
      --no-multi \
      --ansi \
      --header-lines=1 \
      --preview "kubectl get {1} $ARGS | $KUBECTL_YAML_VIEWER" | \
    awk '{ print $1 }'
}

__kubectl_select_context() {
  CURRENT_CONTEXT_INFO='
  Current Context: '"$RED$BOLD$(kubectl config current-context)$NORMAL"'
  '

  kubectl config get-contexts -o name | \
      fzf +m \
        --header "$CURRENT_CONTEXT_INFO" \
        --no-preview
}

kf() {
  # shellcheck disable=2016
  HELP_TEXT="
Usage:
  kf  <action> ...

  # interactively selects namespace to apply command to
  kfn <action> ...

  # interactively selects context to apply command to
  kfc <action> ...

Arguments:
  '--' splits the arg list into 3 useful parts
  '---' is equivalent to '-- --'

  kf <command> [type] [...global args] -- [...get args] -- [...action args]
  kf <command> [type] [...global args] --- [...action args]

  # For example, this command
  kf exec --context=foo -n bar --- -it psql

    # Delegates to this one for the list
    kubectl get pod --context=foo -n bar

    # Delegates to this one for the preview
    kubectl describe pod <selection> --context=foo -n bar -it psql

Commands:

  # interactively list and look at the YAML for some resource type (get + describe)
  kf get <type> [...args]

  # interactively select an item of resource type to edit
  kf edit <type> [...args]

  # interactively select a pod to execute a command against (no args == '-it bash')
  kf exec [...args]

Gotchas:

 - '--all-namespaces' will not work properly because forwarding namespace
   to later commands will not work - for that use 'kfn'
"

  if [ "$#" -eq 0 ]; then
    __log_error "${BOLD}action${NORMAL} (exec, describe, etc.) is ${BOLD}required${NORMAL}"
    echo "$HELP_TEXT"
    return 1
  else
    # get action
    ACTION="$1"
    shift

    # split the arg list
    ARG_TYPE='0'

    ACTION_ARGS=()
    GET_ARGS=()

    if [ -n "$KUBECTL_FORCE_NAMESPACE" ]; then
      ACTION_ARGS+=(--namespace "$KUBECTL_FORCE_NAMESPACE")
      GET_ARGS+=(--namespace "$KUBECTL_FORCE_NAMESPACE")
    fi

    if [ -n "$KUBECTL_FORCE_CONTEXT" ]; then
      ACTION_ARGS+=(--context "$KUBECTL_FORCE_CONTEXT")
      GET_ARGS+=(--context "$KUBECTL_FORCE_CONTEXT")
    fi

    # some actions take a type
    case "$ACTION" in
      'get' | 'g' | 'describe' | 'd' | 'edit' | 'e')
        if [ "$#" -eq 0 ]; then
          __log_warning "${BOLD}type${NORMAL} (pod, deploy, ing, svc, etc.) not provided; prompting..."
          TYPE="$(__kubectl_select_resource_type "${GET_ARGS[@]}")"
          if [ -z "$TYPE" ]; then
            __log_error "${BOLD}type${NORMAL} (pod, deploy, ing, svc, etc.) not selected or provided"
            return 1
          fi
        else
          TYPE="$1"
          shift
        fi
        ;;
      'exec' | 'x')
        TYPE="pod"
        ;;
    esac

    for arg in "$@"; do
      if [ "$arg" = '--' ]; then
        ((ARG_TYPE+=1))
      elif [ "$arg" = '---' ]; then
        ((ARG_TYPE+=2))
      else
        if [ "$ARG_TYPE" -eq 0 ]; then
          ACTION_ARGS+=("$arg")
          GET_ARGS+=("$arg")
        elif [ "$ARG_TYPE" -eq 1 ]; then
          GET_ARGS+=("$arg")
        else
          ACTION_ARGS+=("$arg")
        fi
      fi
    done

    # get user's selected object
    SELECTION="$(__kubectl_select_one "$TYPE" "${GET_ARGS[@]}")"

    if [ -n "$SELECTION" ]; then
      case "$ACTION" in
        get | g)
          kubectl get -o yaml "$TYPE" "$SELECTION" "${ACTION_ARGS[@]}" | eval "$KUBECTL_YAML_VIEWER" ;;
        describe | d)
          kubectl describe "$TYPE" "$SELECTION" "${ACTION_ARGS[@]}" | eval "$KUBECTL_YAML_VIEWER" ;;
        edit | e)
          kubectl edit "$TYPE" "$SELECTION" "${ACTION_ARGS[@]}" ;;
        exec | x)
          if [ "${#ACTION_ARGS[@]}" -eq 0 ]; then
            kubectl exec "$SELECTION" -it bash
          else
            kubectl exec "$SELECTION" "${ACTION_ARGS[@]}"
          fi
          ;;
        esac
    else
      __log_warning "no $TYPE selected"
    fi
  fi
}

kfn() {
  KUBECTL_FORCE_NAMESPACE="$(__kubectl_select_one namespace)"
  if [ -n "$KUBECTL_FORCE_NAMESPACE" ]; then
    kf "$@"
  else
    __log_warning "no namespace selected"
  fi
  unset KUBECTL_FORCE_NAMESPACE
}

kfc() {
  KUBECTL_FORCE_CONTEXT="$(__kubectl_select_context)"
  if [ -n "$KUBECTL_FORCE_CONTEXT" ]; then
    kf "$@"
  else
    __log_warning "no context selected"
  fi
  unset KUBECTL_FORCE_CONTEXT
}

ksc() {
  KUBECTL_SELECTED_CONTEXT="$(__kubectl_select_context)"
  if [ -n "$KUBECTL_SELECTED_CONTEXT" ]; then
    kubectl config use-context "$KUBECTL_SELECTED_CONTEXT"
  else
    __log_warning "no context selected"
  fi
}

ksn() {
  CURRENT_CONTEXT="$(kubectl config current-context)"
  KUBECTL_SELECTED_NAMESPACE="$(__kubectl_select_one namespace)"
  if [ -n "$KUBECTL_SELECTED_NAMESPACE" ]; then
    kubectl config set-context "$CURRENT_CONTEXT" --namespace "$KUBECTL_SELECTED_NAMESPACE"
  else
    __log_warning "no namespace selected"
  fi
}

export KDIFF_RENDERER="command cat -"
export KDIFF_PAGER="less"

if __command_exists delta; then
  KDIFF_PAGER="delta"
fi

# Usage: kdiff [context-a] [context-b] <kubectl command>
#
# Examples:
#   $ kdiff qa-1 qa-2 describe deployment xyz
kdiff() {
  LEFT="$1"
  RIGHT="$2"

  shift
  shift

  if [ -t 1 ] && [ -n "$KDIFF_PAGER" ]; then
    diff -u <(eval "kubectl \"--context=$LEFT\" $(printf ' %q' "$@") | $KDIFF_RENDERER") \
            <(eval "kubectl \"--context=$RIGHT\" $(printf ' %q' "$@") | $KDIFF_RENDERER") \
            | eval "$KDIFF_PAGER"
  else
    diff -u <(eval "kubectl \"--context=$LEFT\" $(printf ' %q' "$@") | $KDIFF_RENDERER") \
            <(eval "kubectl \"--context=$RIGHT\" $(printf ' %q' "$@") | $KDIFF_RENDERER")
  fi
}

# start a shell on a pod (treats args as command)
kfx() {
  if [ "$#" -eq 0 ]; then
    kf exec --- -it bash
  else
    kf exec --- -it "$@"
  fi
}

# really get _all_ the things (highlighting regexes provided as arguments)
kgetall() {
  QUERY="($([ $# -eq 0 ] && printf '' || printf '%s|' "$@")\$)"
  for i in $(kubectl api-resources --verbs=list -o name | sort | uniq); do
    echo
    echo "\$ kubectl get --all-namespaces --ignore-not-found ${i}"
    if [ -n "$QUERY" ]; then
      kubectl get --all-namespaces --ignore-not-found "${i}" | grep --color=always -E "$QUERY"
    else
      kubectl get --all-namespaces --ignore-not-found "${i}"
    fi
  done
}

# examine secrets as though they are certificates
kcert() {
  ARGS="$([ $# -eq 0 ] && printf '' || printf '%q ' "$@")"
  kubectl get secret "$@" | \
    fzf \
      --no-multi \
      --ansi \
      --header-lines=1 \
      --preview "echo {1} ; kubectl get secret {1} $ARGS -o jsonpath='{.data.tls\\.crt}' | xargs echo | base64 -D | openssl x509 -text -noout" | \
    awk '{ print $1 }'
}

# all kube events sorted by time (passes args to kubectl)
kube-events-sorted() {
  kubectl get event --all-namespaces --sort-by=".metadata.creationTimestamp" "$@"
}

# NB: make sure to escape double-quotes (!!!!!!!!!!!!!)
build_watchable_command() {
  local function_name="$1"
  local command_prefix="$2"
  local filter="$3"

  local command_string="$command_prefix \$([ \$# -eq 0 ] && printf '' || printf '%q' \"\$@\") | $filter"

  eval "$function_name() { eval \"$command_string\" }"
  eval "watch-$function_name() { watch \"$command_string\" }"
}

# build a table for all pods with status
KUBE_POD_COUNT_BY_IMAGE_COMMAND='kubectl get pods -o jsonpath=\"{range .items[*]}{.spec.containers[0].image}#{.metadata.labels.app}#{.status.phase}#{.status.reason}#{.status.message}{\\\"\n\\\"}{end}\"'
build_watchable_command 'kube-pod-count-by-image' "$KUBE_POD_COUNT_BY_IMAGE_COMMAND" 'sort | uniq -c | column -t -s \"#\"'

# build a table for all pods with status
KUBE_NODE_LAYOUT_COMMAND='kubectl get pods -o jsonpath=\"{range .items[?(@.status.phase==\\\"Running\\\")]}{.spec.nodeName}#{.status.hostIP}#{.metadata.name}#{.status.podIP}{\\\"\n\\\"}{end}\"'
build_watchable_command 'kube-node-layout' "$KUBE_NODE_LAYOUT_COMMAND" 'column -t -s \"#\" | sort'
