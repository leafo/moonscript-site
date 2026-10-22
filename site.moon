require "sitegen"
lfs = require "lfs"

import to_lua from require "moonscript.base"

html = require "sitegen.html"

SyntaxhighlightPlugin = require "sitegen.plugins.syntaxhighlight"

highlight = SyntaxhighlightPlugin\highlight

try_compile = (text, options=implicitly_return_root: false) ->
  to_lua text, options

split_highlight = (code_text, options) ->
  lua_text, err = try_compile code_text, options

  unless lua_text
    error "Failed to compile moon (#{err}):\n\n#{code_text}"

  html.build ->
    tag.table {
      __breakclose: true
      width: "100%"
      cellspacing: "0"
      cellpadding: "0"
      class: "code-split"

      tr {
        td {
          class: "code-split-left"
          div {
            class: "code-header"
            "MoonScript"
          }
          pre code {
            class: "moon-code"
            raw highlight "moon", code_text
          }
        }

        td {
          class: "code-split-right"
          div {
            class: "code-header code-header-right"
            "Lua"
          }
          pre code {
            class: "lua-code"
            raw highlight "lua", lua_text
          }
        }
      }
    }

single_highlight = (code_text) ->
  html.build ->
    -- this is stupid because markdown parser sucks
    tag.table {
      __breakclose: true
      width: "100%"
      cellspacing: "0"
      cellpadding: "0"
      class: "code-split"

      tr td {
        div {
          class: "code-header"
          "MoonScript"
        }
        pre code {
          class: "moon-code"
          raw highlight "moon", code_text
        }
      }
    }

-- the markdown renderer has no table support, convert pipe tables to html
convert_tables = (text) ->
  escape = (str) -> (str\gsub("&", "&amp;")\gsub("<", "&lt;")\gsub(">", "&gt;"))

  format_cell = (cell) ->
    cell = cell\match "^%s*(.-)%s*$"
    (escape(cell)\gsub "`([^`]+)`", "<code>%1</code>")

  split_row = (line) ->
    line = line\match("^%s*|(.*)|%s*$") or line
    [format_cell c for c in (line .. "|")\gmatch "([^|]*)|"]

  out = {}
  lines = [l for l in (text .. "\n")\gmatch "([^\n]*)\n"]
  i = 1
  while i <= #lines
    line = lines[i]
    sep = lines[i + 1]
    if line\match("^%s*|") and sep and sep\match("^%s*|[%s:|-]+|%s*$")
      header = split_row line
      aligns = for a in *split_row sep
        a\match(":$") and ' style="text-align: right"' or ""

      parts = {'<table class="quick_ref">', "<thead><tr>"}
      for idx, cell in ipairs header
        table.insert parts, "<th#{aligns[idx] or ""}>#{cell}</th>"
      table.insert parts, "</tr></thead><tbody>"

      i += 2
      while lines[i] and lines[i]\match "^%s*|"
        table.insert parts, "<tr>"
        for idx, cell in ipairs split_row lines[i]
          table.insert parts, "<td#{aligns[idx] or ""}>#{cell}</td>"
        table.insert parts, "</tr>"
        i += 1

      table.insert parts, "</tbody></table>"
      table.insert out, table.concat parts
    else
      table.insert out, line
      i += 1

  table.concat out, "\n"

sitegen.create =>
  @title = "MoonScript"
  @moon_version = require"moonscript.version".version

  @site_url = "https://moonscript.org"
  @build_date = os.date "!%Y-%m-%dT%H:%M:%SZ"

  -- page field encoded for use inside a JSON-LD string
  @json_field = (args) =>
    value = tostring @tpl_scope[args[1]] or ""
    (value\gsub('[\\"]', "\\%0")\gsub "\n", " ")

  add "index.md", {
    index: true
    canonical_path: "/"
    description: "MoonScript is a dynamic scripting language that compiles to Lua. It adds classes, comprehensions, whitespace-significant syntax, and implicit returns while running anywhere Lua does."
  }

  add "moonscript/docs/reference.md", {
    index: true
    section_title: "Reference"
    section_path: "/reference/"
    canonical_path: "/reference/"
    description: "The MoonScript language guide: syntax, functions, tables, classes, comprehensions, destructuring, and more, with every example shown alongside its compiled Lua."
  }

  add "moonscript/docs/standard_lib.md", {
    index: true
    section_title: "Reference"
    section_path: "/reference/"
    canonical_path: "/reference/standard_lib.html"
    description: "Reference for the moon standard library module bundled with MoonScript: debugging, class helpers, function and table utilities."
  }

  add "moonscript/docs/command_line.md", {
    index: true
    section_title: "Reference"
    section_path: "/reference/"
    canonical_path: "/reference/command_line.html"
    description: "How to use the moon and moonc command line tools to run MoonScript, compile it to Lua, watch directories, and lint code."
  }

  add "moonscript/docs/api.md", {
    index: true
    section_title: "Reference"
    section_path: "/reference/"
    canonical_path: "/reference/api.html"
    description: "Using MoonScript from Lua: the moonscript module, autocompiling require, and the compiler API for converting MoonScript to Lua at runtime."
  }

  add "guides/index.html", {
    index: false
    template: "reference"
    short_name: "guides"
    section_title: "Guides"
    section_path: "/guides/"
    canonical_path: "/guides/"
  }

  guide_files = [f for f in lfs.dir "guides" when f\match("%.md$") and f != "index.md"]
  table.sort guide_files

  for fname in *guide_files
    slug = fname\gsub "%.md$", ""
    add "guides/#{fname}", {
      is_a: "guide"
      index: true
      template: "reference"
      section_title: "Guides"
      section_path: "/guides/"
      canonical_path: "/guides/#{slug}.html"
    }

  add "moonscript/CHANGELOG.md", {
    target: "changelog"
    template: "reference"
    title: "Changelog"
    short_name: "changelog"
    index: { max_depth: 1 }
    no_compile: true
    section_title: "Changelog"
    section_path: "/changelog.html"
    canonical_path: "/changelog.html"
    description: "Release notes for every version of MoonScript, the language that compiles to Lua, with the date of each release and examples of new syntax."
  }

  deploy_to "leaf@leafo.net", "www/moonscript.org"

  copy "index.css", "reference.css", "index.js"

  i = 0
  with SyntaxhighlightPlugin.custom_highlighters
    .moon = (code_text, page, options) =>
      if page.meta.no_compile
        return html.build ->
          pre {
            __breakclose: true
            code {
              class: "moon_code"
              raw highlight "moon", code_text
            }
          }

      if page.source\match("reference") or page.meta.is_a == "guide"
        return split_highlight code_text, options

      lua_text, err = try_compile code_text, options
      return err if not lua_text

      html.build ->
        i += 1

        moon_pre = pre {
          __breakclose: true
          code {
            class: "moon_code"
            raw highlight "moon", code_text
          }
        }

        if page.source\match "^index"
          div {
            __breakclose: true
            class: "code_container"
            "data-compiled_lua": highlight "lua", lua_text

            div {
              class: "see_lua_btn rainbow_btn_wrap"
              a {
                href: "#"
                class: "rainbow_btn"
                "See Lua"
              }
            }
            moon_pre
          }
        else
          moon_pre

    .moonret = (code_text, page) =>
      split_highlight code_text, {}

    .moononly = (code_text, page) =>
      unless page.meta.no_compile
        lua_text, err = try_compile code_text
        unless lua_text
          error "Failed to compile moon (#{err}):\n\n#{code_text}"

      single_highlight code_text

  filter "CHANGELOG", (body) =>
    body = body\gsub "^# MoonScript dev\n", "# Unreleased (in development)\n"
    -- link issue numbers, also stops a wrapped "#123" from parsing as a header
    body = body\gsub "#(%d+)", "[#%1](https://github.com/leafo/moonscript/issues/%1)"
    convert_tables body

  filter "^guides/", (body) =>
    convert_tables body

  filter "docs", (body) =>
    body\gsub "<h1>.-</h1>", (header) ->
      table.concat { '</div>', header, '<div class="main">' }

