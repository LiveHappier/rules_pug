"Tests for pug bzl definitions"

load("@bazel_tools//tools/build_rules:test_rules.bzl", "file_test", "rule_test")

def _pug_binary_test(package):
    rule_test(
        name = "hello_world_rule_test",
        generates = ["main.html"],
        rule = package + "/hello_world:hello_world"
    )

    file_test(
        name = "hello_world_file_test",
        file = package + "/hello_world:main.html",
        content = "<div>Hello World !</div>"
    )

    rule_test(
        name = "mixin_rule_test",
        generates = ["main.html"],
        rule = package + "/mixin:mixin"
    )

    file_test(
        name = "mixin_file_test",
        file = package + "/mixin:main.html",
        content = "<div>Hello World !</div><div>Mixin file</div><div>Mixin resource</div>"
    )

def pug_rule_test(package):
    """Issue simple tests on pug rules."""
    _pug_binary_test(package)
