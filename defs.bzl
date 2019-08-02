# Copyright LiveHappier. All rights reserved.

# This file is part of rules_go_simple. Use of this source code is governed by
# the 3-clause BSD license that can be found in the LICENSE.txt file.

# deps.bzl contains public definitions needed in WORKSPACE and macros called
# from WORKSPACE. It is kept separate from def.bzl so that definitions loaded
# from def.bzl may use dependencies declared here.



""" Public API is re-exported here."""

load("//pug:pug_repositories.bzl", _pug_repositories = "pug_repositories")
load(
  "//pug:pug.bzl",
  _PugInfo = "PugInfo",
  _pug_binary = "pug_binary",
  _pug_library = "pug_library",
)

pug_repositories = _pug_repositories

pug_library = _pug_library
pug_binary = _pug_binary

# Expose the PugInfo provider so that people can make their own custom rules
# that expose pug library outputs.
PugInfo = _PugInfo
