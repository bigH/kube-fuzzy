alias kf=kube-fuzzy

# exec on pods
alias kx="kube-fuzzy get pod | xargs -n 1 -I '{}' kubectl exec '{}' --"

# exec on pods with confirmation on each command being run
alias kx="kube-fuzzy get pod | xargs -p -n 1 -I '{}' kubectl exec '{}' --"

# set namespace / context durably
alias ksn=kube-set-namespace
alias ksc=kube-set-context

# set namespace / context for just this command
alias kwn=kube-with-namespace
alias kwc=kube-with-context

# set namespace & context for just this command
alias kwcn=kube-with-context kube-with-namespace
