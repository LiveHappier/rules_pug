# Pug rules for Bazel

## Overview

rules_pug is a simple set of Bazel rules for building Pug files.

## Rules

- pug_binary

## Setup

in `WORKSPACE`:
```
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "rules_pug",
    commit = "f70594cb852a402266ebc4fd0881e773fbab63cc",
    remote = "https://github.com/LiveHappier/rules_pug.git",
    shallow_since = "1569509903 +0200"
)

# Setup the rules_pug toolchain
load("@rules_pug//pug:pug_repositories.bzl", "pug_repositories")
pug_repositories()
```

## Examples

check `examples`

## Doc

todo with skydoc
