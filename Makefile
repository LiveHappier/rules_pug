SHELL := $(shell which bash)

.PHONY: examples

BAZEL_OPTS = -s --verbose_failures

examples: hello-world mixin

hello-world:
	bazel build $(BAZEL_OPTS) //examples/hello_world
mixin:
	bazel build $(BAZEL_OPTS) //examples/mixin

test:
	bazel test --cache_test_results=false //pug/test:*
