#!/usr/bin/env bash

__command_exists() {
  [ -n "$1" ] && type "$1" >/dev/null 2>&1
}

__log_error() {
  echo "[${RED}${BOLD}ERROR${NORMAL}] $*"
}

__log_warning() {
  echo "[${YELLOW}${BOLD}WARNING${NORMAL}] $*"
}

__log_info() {
  echo "[${GREEN}${BOLD}INFO${NORMAL}] $*"
}

if [ -z "$FZF_DEFAULT_OPTS" ]; then
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
fi

if [ -z "$KUBECTL_YAML_VIEWER" ]; then
  if __command_exists bat; then
    KUBECTL_YAML_VIEWER="bat --color=always --language=yaml --style=plain"
  else
    KUBECTL_YAML_VIEWER="less"
  fi
fi

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
