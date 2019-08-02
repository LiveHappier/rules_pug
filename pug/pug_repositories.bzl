# Copyright 2019 LiveHappier. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"Install Pug toolchain dependencies"

load("@build_bazel_rules_nodejs//:defs.bzl", "yarn_install", "check_rules_nodejs_version")

def pug_repositories():
    """Set up environment for Pug compiler.
    """

    # 0.31.1: entry_point attribute of rules_nodejs is now a label
    # 0.32.0: @npm//node_modules/foobar:foobar.js labels changed to @npm//:node_modules/foobar/foobar.js with fix for bazelbuild/rules_nodejs#802.
    check_rules_nodejs_version("0.32.0")

    yarn_install(
        name = "build_bazel_rules_pug_deps",
        package_json = "@rules_pug//:pug/package.json",
        yarn_lock = "@rules_pug//:pug/yarn.lock",
        # Do not symlink node_modules as when used in downstream repos we should not create
        # node_modules folders in the @rules_pug external repository. This is
        # not supported by managed_directories.
        symlink_node_modules = False,
    )
