# Copyright 2018 The Bazel Authors. All rights reserved.
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
"Compile Pug files to HTML"

_ALLOWED_SRC_FILE_EXTENSIONS = [".pug", ".jade"]

# Documentation for switching which compiler is used
_COMPILER_ATTR_DOC = """Choose which Pug compiler binary to use.
By default, we use the JavaScript-transpiled version of the
pug library.
"""

PugInfo = provider(
    doc = "Collects files from pug_library for use in downstream pug_binary",
    fields = {
        "sources": "Pug sources for this target and its dependencies",
    },
)

def _collect_deps(srcs, deps):
    """Obtain the source file for a target and its dependencies
    note: Dependencies are not compiled with pug, so we use the DefaultInfo provider

    Args:
      srcs: a list of source files
      deps: a list of targets that are direct dependencies

    Returns:
      a collection of all the needed sources
    """
    return depset(
        srcs,
        transitive = [dep[DefaultInfo].files for dep in deps],
        order = "postorder",
    )

def _pug_library_impl(ctx):
    """pug_library collects all transitive sources for given srcs and deps.

    It doesn't execute any actions.

    Args:
      ctx: The Bazel build context

    Returns:
      The pug_library rule.
    """
    source_files = _collect_deps(
        ctx.files.srcs,
        ctx.attr.deps,
    )
    return [
        PugInfo(sources = source_files),
        DefaultInfo(
            files = source_files,
            runfiles = ctx.runfiles(sources = source_files),
        ),
    ]

def _run_pug(ctx, input, html_output):
    """run_pug performs an action to compile a single Pug file into HTML."""

    # The Pug CLI expects inputs like
    # pug <input_filename> <output_filename>
    args = ctx.actions.args()

    # Last arguments are input and output paths
    args.add_all([input.path, html_output.path])

    ctx.actions.run(
        mnemonic = "PugCompiler",
        executable = ctx.executable.compiler,
        inputs = _collect_deps([input], ctx.attr.deps),
        tools = [ctx.executable.compiler],
        arguments = [args],
        outputs = [html_output],
        use_default_shell_env = True,
    )

def _pug_binary_impl(ctx):
    # Make sure the output HTML is available in runfiles if used as a data dep.
    outputs = [ctx.outputs.html_file]
    _run_pug(ctx, ctx.file.src, ctx.outputs.html_file)
    return DefaultInfo(runfiles = ctx.runfiles(files = outputs))

def _pug_binary_outputs(src, output_name, output_dir):
    """Get map of pug_binary outputs, including generated html.
    Note that the arguments to this function are named after attributes on the rule.

    Args:
      src: The rule's `src` attribute
      output_name: The rule's `output_name` attribute
      output_dir: The rule's `output_dir` attribute

    Returns:
      Outputs for the pug_binary
    """

    output_name = output_name or _strip_extension(src.name) + ".html"
    html_file = "/".join([p for p in [output_dir, output_name] if p])

    outputs = {
        "html_file": html_file,
    }

    return outputs

def _strip_extension(path):
    """Removes the final extension from a path."""
    components = path.split(".")
    components.pop()
    return ".".join(components)

pug_deps_attr = attr.label_list(
    providers = [DefaultInfo],
    doc = "pug_library targets to include in the compilation",
    allow_files = True,
)

pug_library = rule(
    implementation = _pug_library_impl,
    attrs = {
        "srcs": attr.label_list(
            doc = "Pug source files",
            allow_files = _ALLOWED_SRC_FILE_EXTENSIONS,
            allow_empty = False,
            mandatory = True,
        ),
        "deps": pug_deps_attr,
    },
)
"""Defines a group of Pug include files.
"""

_pug_binary_attrs = {
    "src": attr.label(
        doc = "Pug entrypoint file",
        mandatory = True,
        allow_single_file = _ALLOWED_SRC_FILE_EXTENSIONS,
    ),
    "include_paths": attr.string_list(
        doc = "Additional directories to search when resolving imports",
    ),
    "output_dir": attr.string(
        doc = "Output directory, relative to this package.",
        default = "",
    ),
    "output_name": attr.string(
        doc = """Name of the output file, including the .html extension.
By default, this is based on the `src` attribute: if `index.pug` is
the `src` then the output file is `index.html.`.
You can override this to be any other name.
Note that some tooling may assume that the output name is derived from
the input name, so use this attribute with caution.""",
        default = "",
    ),
    "deps": pug_deps_attr,
    "compiler": attr.label(
        doc = _COMPILER_ATTR_DOC,
        default = Label("//pug"),
        executable = True,
        cfg = "host",
    ),
}

pug_binary = rule(
    implementation = _pug_binary_impl,
    attrs = _pug_binary_attrs,
    outputs = _pug_binary_outputs,
)
