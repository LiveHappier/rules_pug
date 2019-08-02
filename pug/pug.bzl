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
        "transitive_sources": "Pug sources for this target and its dependencies",
    },
)

def _collect_transitive_sources(srcs, deps):
    "Pug compilation requires all transitive .pug source files"
    return depset(
        srcs,
        transitive = [dep[PugInfo].transitive_sources for dep in deps],
        # Provide .pug sources from dependencies first
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
    transitive_sources = _collect_transitive_sources(
        ctx.files.srcs,
        ctx.attr.deps,
    )
    return [
        PugInfo(transitive_sources = transitive_sources),
        DefaultInfo(
            files = transitive_sources,
            runfiles = ctx.runfiles(transitive_files = transitive_sources),
        ),
    ]

def _run_pug(ctx, input, html_output):
    """run_pug performs an action to compile a single Pug file into HTML."""

    # The Pug CLI expects inputs like
    # pug <flags> <input_filename> <output_filename>
    args = ctx.actions.args()

    # Flags (see https://github.com/sass/dart-sass/blob/master/lib/src/executable/options.dart)
    # args.add_joined(["--style", ctx.attr.output_style], join_with = "=")

    # Sources for compilation may exist in the source tree, in bazel-bin, or bazel-genfiles.
    #for prefix in [".", ctx.var["BINDIR"], ctx.var["GENDIR"]]:
    #    args.add("--basedir=%s/" % prefix)
    #    for include_path in ctx.attr.include_paths:
    #        args.add("--basedir=%s/%s" % (prefix, include_path))

    # Last arguments are input and output paths
    # Note that the sourcemap is implicitly written to a path the same as the
    # html with the added .map extension.
    args.add_all([input.path, html_output.path])

    ctx.actions.run(
        mnemonic = "PugCompiler",
        executable = ctx.executable.compiler,
        inputs = _collect_transitive_sources([input], ctx.attr.deps),
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
    doc = "Pug_library targets to include in the compilation",
    providers = [PugInfo],
    allow_files = False,
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

def _multi_pug_binary_impl(ctx):
  """multi_pug_binary accepts a list of sources and compile all in one pass.
  Args:
    ctx: The Bazel build context
  Returns:
    The multi_pug_binary rule.
  """

  inputs = ctx.files.srcs
  outputs = []
  # Every non-partial Pug file will produce one HTML output file and,
  # optionally, one sourcemap file.
  for f in inputs:
    # Pug partial files (prefixed with an underscore) do not produce any
    # outputs.
    if f.basename.startswith("_"):
      continue
    name = _strip_extension(f.basename)
    outputs.append(ctx.actions.declare_file(
      name + ".html",
      sibling = f,
    ))

  # Use the package directory as the compilation root given to the Pug compiler
  root_dir = ctx.label.package

  # Declare arguments passed through to the Sass compiler.
  # Start with flags and then expected program arguments.
  args = ctx.actions.args()
  #args.add("--style", ctx.attr.output_style)
  args.add("--basedir", root_dir)

  args.add(root_dir + ":" + ctx.bin_dir.path + '/' + root_dir)

  if inputs:
    ctx.actions.run(
        inputs = inputs,
        outputs = outputs,
        executable = ctx.executable.compiler,
        arguments = [args],
        mnemonic = "PugCompiler",
        progress_message = "Compiling Pug",
    )

  return [DefaultInfo(files = depset(outputs))]

multi_pug_binary = rule(
  implementation = _multi_pug_binary_impl,
  attrs = {
    "srcs": attr.label_list(
      doc = "A list of pug files and associated assets to compile",
      allow_files = _ALLOWED_SRC_FILE_EXTENSIONS,
      allow_empty = True,
      mandatory = True,
    ),

    "compiler": attr.label(
      doc = _COMPILER_ATTR_DOC,
      default = Label("//pug"),
      executable = True,
      cfg = "host",
    ),
  }
)
