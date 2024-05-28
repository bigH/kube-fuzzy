## Installation

```bash
brew install bat git-delta fzf

git clone https://github.com/bigH/kube-fuzzy.git

# in your shell rc or local shell when trying it
echo "export PATH=\"$(pwd)/kube-fuzzy/bin:\$PATH\"" >> ~/.bashrc

## OPTIONAL

# aliases as commands - better than bash aliases because
# - they propagate to sub-shells, so they work with xargs and pipes
# - they work properly with kube-with-context and kube-with-namespace since those run in sub-shells
echo "export PATH=\"$(pwd)/kube-fuzzy/alias-bin:\$PATH\"" >> ~/.bashrc

# useful functions
echo "source \"$(pwd)/kube-fuzzy/extras.sh\"" >> ~/.bashrc
```

## What's Included?

- `kube-fuzzy` - interactive kubectl tool
- `kube-fuzzy-exec` - uses `kube-fuzzy` to allow exec-ing into pods
- `kube-diff` - diff two resources from separate contexts
- `kube-certs` - view secrets as certificates
- `kube-get-all` - get every resource type and then list every resource within
- `kube-set-namespace` - set the current namespace for kubectl
- `kube-set-context` - set the current context for kubectl
- `kube-with-namespace` - for a _single command_, sets an env var
    - does not work with `kubectl` directly, but works with `kubectl-wrapper`
    - works with `kube-fuzzy`, `kube-fuzzy-exec`, `kube-certs`, `kube-get-all`, but not `kube-diff`
- `kube-with-context` - for a _single command_, sets an env var
    - does not work with `kubectl` directly, but works with `kubectl-wrapper`
    - works with `kube-fuzzy`, `kube-fuzzy-exec`, `kube-certs`, `kube-get-all`, but not `kube-diff`

`kubectl-wrapper` is also an included command - meant to be used in place of `kubectl` whereever possible. It will automatically check and print the context. In `*prod*` contexts, it confirms any execution of possible writes via `kubectl`. It's also useful to map to this for `kubectl exec` and `kubectl edit` command aliases.

- `kubectl-wrapper --no-log-context` will not log context, but still retains the safety against `*prod*` contexts.
- `kubectl-wrapper --no-prompt-for-prod-writes` will not prompt for any non-read commands in prod contexts.
- `kubectl-wrapper --no-log-context --no-prompt-for-prod-writes` is basically the equivalent of `kubectl`, but with context/namespace if set by `kube-with-context` or `kube-with-namespace`.

## Configuring

```bash
# set default yaml viewer (used in preview window and when `describe`-ing)
export KUBE_FUZZY_YAML_VIEWER="bat --color=always"

# set diff renderer for `kube-diff`
export KUBE_DIFF_RENDERER="delta --side-by-side"
```

## Extras

- useful [aliases](./alias-bin)
- useful [extras.sh](./extras.sh)

## Usage

```bash
# use command substitution to select something to operate on:
some-command-that-takes-pods $(kube-fuzzy get pods)

# use pipes - here using aliases too
kf get pod | xargs some-command-that-takes-pods

# select context, namespace, then pods and run a command on each
kube-with-context kube-with-namespace
    kube-fuzzy get pods | xargs -n1 -I{} kubectl-wrapper exec {} -- bash -c "echo Hello, \$HOSTNAME!"
# OR with kube-fuzzy-exec
kube-with-context kube-with-namespace kube-fuzzy-exec bash -c 'echo Hello, $HOSTNAME!'
# OR with aliases
kwcn kx bash -c 'echo Hello, $HOSTNAME!'

# kube-fuzzy-exec can provide prompts for each pod operated on
kube-fuzzy-exec --prompt bash

# use `kubectl-wrapper` to respect `kube-with-context` and `kube-with-namespace`
kwcn kubectl-wrapper edit deployment $(kube-fuzzy get deployment)

# want to pipe with `kube-with-context`?
# use `eval` since environment variables are not passed through pipes
kube-with-context eval '.... | ....'

# `kubectl-wrapper` will print context and prompt to confirm in `*prod*` contexts
# turn off the context logging by using `--no-log-context`
kubectl-wrapper --no-log-context get pods

# diff between two environments (contexts/namespaces)
kube-diff ':' 'foo:bar' describe deployment my-deployment
```

## General Notes

Most (if not all) commands respect the `kube-with-context` and `kube-with-namespace` commands by using `kubectl-wrapper` or `kube-fuzzy`. This is useful for one-off commands that you don't want to change your current context or namespace for. In order for this to work for your own commands, you can use `kubectl-wrapper` in place of `kubectl` and it will respect these functions.

Most commands also use stderr for any helpful output that is not the core output. For example, warnings from `kube-fuzzy get pods` are all sent to stderr, while only pods selected show up in stdout. These commands pipe/redirect really well.
