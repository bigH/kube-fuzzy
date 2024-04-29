## Installation

```bash
brew install bat git-delta fzf

git clone https://github.com/bigH/kube-fuzzy.git

# in your shell rc or local shell when trying it
echo "export PATH=\"$(pwd)/kube-fuzzy/bin:\$PATH\"" >> ~/.bashrc

# optional, but useful
echo "source \"$(pwd)/kube-fuzzy/extras.sh" >> ~/.bashrc
echo "source \"$(pwd)/kube-fuzzy/aliases.sh" >> ~/.bashrc
```

## What's Included?

- `kube-fuzzy` - interactive kubectl tool
- `kube-diff` - diff two resources from separate contexts
- `kube-certs` - view secrets as certificates
- `kube-get-all` - get every resource type and then list every resource within
- `kube-set-namespace` - set the current namespace for kubectl
- `kube-set-context` - set the current context for kubectl
- `kube-with-namespace` - for a _single command_, set the namespace/context before running it (only works with `kube-fuzzy` & `kubectl-wrapper`)
- `kube-with-context` - for a _single command_, set the namespace/context before running it (only works with `kube-fuzzy` & `kubectl-wrapper`)

`kubectl-wrapper` is also an included command - meant to be used in place of kubectl whereever possible. It will automatically check and print the context. In `*prod*` contexts, it confirms any execution of `kubectl`. It's also useful to map to this for `kubectl exec` and `kubectl edit` command aliases.

`kubectl-wrapper --no-log-context` will not log context, but still retains the safety against `*prod*` contexts.

## Configuring

```bash
# set default `exec` behavior (an array)
export KUBE_FUZZY_EXEC_DEFAULT=(-it make console)

# set default yaml viewer (used in preview window and when `describe`-ing)
export KUBE_FUZZY_YAML_VIEWER="bat --color=always"

# set diff renderer for `kube-diff`
export KUBE_DIFF_RENDERER="delta --side-by-side"
```

## Useful Aliases

```bash
alias kf=kube-fuzzy

# exec default is `-it bash`, so select a pod and get a shell
alias kx=kube-fuzzy exec

# set namespace / context durably
alias ksn=kube-set-namespace
alias ksc=kube-set-context

# set namespace / context for just this command
alias kwn=kube-with-namespace
alias kwc=kube-with-context

# set namespace & context for just this command
alias kwcn=kube-with-context kube-with-namespace
```

## Usage

```bash
some-command-that-takes-pod $(kube-fuzzy get pods)
# OR with aliases
some-command-that-takes-pod $(kf g pods)

# just shell into pod of choice
kube-fuzzy exec
# OR with aliases
kx

# in a different namespace and context, select pods and echo 
kube-with-context kube-with-namespace \
    kube-fuzzy exec pods bash -c 'echo Hello, $HOSTNAME!'
# OR with aliases
kwcn kf exec pod bash -c 'echo Hello, $HOSTNAME!'
```
