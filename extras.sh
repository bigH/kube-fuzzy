#!/usr/bin/env bash

# Usage:
#   __build_watchable_command "<function name>" \
#     "<command producing data>" \
#     "<filter>
#
# Here's a simple example:
#   __build_watchable_command 'kube-pod-count-by-image-source' \
#     'kubectl get pods -o jsonpath=\"{range .items[*]}{.spec.containers[0].image}{"\n"}{end}\"' \
#     'cut -d/ -f1 | sort | uniq -c'
#
# This will create two functions:
#   - kube-pod-count-by-image-source
#   - watch-kube-pod-count-by-image-source
#
# NB: !! MAKE SURE TO USE PROPER ESCAPING !!
__build_watchable_command() {
  local function_name="$1"
  local command_prefix="$2"
  local filter="$3"

  local command_string="$command_prefix \$([ \$# -eq 0 ] && printf '' || printf '%q' \"\$@\") | $filter"

  eval "$function_name() { eval \"$command_string\" }"
  eval "watch-$function_name() { watch \"$command_string\" }"
}

# build a table showing all images used in pods and their count
__build_watchable_command 'kube-pod-count-by-image' \
  'kubectl get pods -o jsonpath=\"{range .items[*]}{.spec.containers[0].image}#{.metadata.labels.app}#{.status.phase}#{.status.reason}{\\\"\n\\\"}{end}\"' \
  'sort | uniq -c | column -t -s \"#\"'

# build a table for all pods with corresponding node and pod ips
__build_watchable_command 'kube-node-layout' \
  'kubectl get pods -o jsonpath=\"{range .items[?(@.status.phase==\\\"Running\\\")]}{.spec.nodeName}#{.status.hostIP}#{.metadata.name}#{.status.podIP}{\\\"\n\\\"}{end}\"' \
  'column -t -s \"#\" | sort'

# get rid of command-builder to keep the environment clean
unset __build_watchable_command
