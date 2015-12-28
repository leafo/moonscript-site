require "sitegen"

import to_lua from require "moonscript.base"

html = require "sitegen.html"
tools = require "sitegen.tools"

PygmentsPlugin = require "sitegen.plugins.pygments"

highlight = PygmentsPlugin\highlight

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

sitegen.create =>
  @title = "MoonScript"
  @moon_version = require"moonscript.version".version

  add "index.md", index: true

  add "moonscript/docs/reference.md", index: true
  add "moonscript/docs/standard_lib.md", index: true
  add "moonscript/docs/command_line.md", index: true
  add "moonscript/docs/api.md", index: true

  deploy_to "leaf@leafo.net", "www/moonscript.org"

  scssphp = tools.system_command "sassc < %s > %s", "css"
  coffeescript = tools.system_command "coffee -c -s < %s > %s", "js"

  build scssphp, "reference.scss"
  build scssphp, "index.scss"

  build coffeescript, "index.coffee"

  i = 0
  with PygmentsPlugin.custom_highlighters
    .moon = (code_text, page, options) =>
      if page.source\match "reference"
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
      single_highlight code_text

  filter "docs", (body) =>
    body\gsub "<h1>.-</h1>", (header) ->
      table.concat { '</div>', header, '<div class="main">' }

