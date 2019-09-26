# Pug rules for Bazel

## Overview

rules_pug is a simple set of Bazel rules for building Pug files.

## Rules

- pug_binary

## Setup

in `WORKSPACE`:
```
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_pug",
    url = "https://github.com/LiveHappier/rules_pug/archive/v0.2.tar.gz",
    strip_prefix = "rules_pug-0.2",
    sha256 = "878a2ea0129f718900af05e0303c523806a0d0de19969907a51c1a7994fc200e"
)

# Setup the rules_pug toolchain
load("@rules_pug//pug:pug_repositories.bzl", "pug_repositories")
pug_repositories()
```

## Examples

check `examples`

## Doc

todo with skydoc
