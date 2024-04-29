## Installation

```
brew install bat git-delta fzf

git clone https://github.com/bigH/kube-fuzzy.git

# in your shell rc or local shell when trying it
PATH="$(pwd)/kube-fuzzy/bin:$PATH"

# your choice
source kube-fuzzy/extras.sh
```

## Usage

```
# kf is the main command in this package. it's not amazing, but works _fine_
$ kf get
$ kf get pods
$ kf exec --- -it bash

# diff some output from 2 different contexts
# .. useful for comparing `describe` yaml
$ kdiff [context 1] [context 2] [kube command]              

# force namespace for just this command, rather than changing config
$ kfn get pods

# same as above but for setting context
$ kfc get pods

# set context in config
$ ksc

# set namespace in config
$ ksn
```
