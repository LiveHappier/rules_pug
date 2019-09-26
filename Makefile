SHELL := $(shell which bash)

.PHONY: test

test:
	bazel test --cache_test_results=false //pug/test:*
