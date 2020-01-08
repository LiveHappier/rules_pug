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
    url = "https://github.com/LiveHappier/rules_pug/archive/v0.3.tar.gz",
    strip_prefix = "rules_pug-0.3",
    sha256 = "35221e0704d32ce27abdf0a747bfb1d23ef6693c73f6db5a58c353d999138dbc"
)

# Setup the rules_pug toolchain
load("@rules_pug//pug:pug_repositories.bzl", "pug_repositories")
pug_repositories()
```

## Examples

check `examples`

## Doc

todo with skydoc
