require "sitegen"

import to_lua from require "moonscript.base"

html = require "sitegen.html"
tools = require "sitegen.tools"

PygmentsPlugin = require "sitegen.plugins.pygments"
IndexerPlugin = require "sitegen.plugins.indexer"

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

site = sitegen.create_site =>
  @title = "MoonScript"
  @moon_version = require"moonscript.version".version

  add "moonscript/docs/reference.md"
  add "moonscript/docs/standard_lib.md"
  add "moonscript/docs/command_line.md"
  add "moonscript/docs/api.md"

  add "compiler/index.html", template: false

  deploy_to "leaf@leafo.net", "www/moonscript.org"

  scssphp = tools.system_command "pscss < %s > %s", "css"
  coffeescript = tools.system_command "coffee -c -s < %s > %s", "js"

  build scssphp, "reference.scss"
  build scssphp, "index.scss"
  build scssphp, "compiler/style.scss"

  build coffeescript, "highlight.coffee"
  build coffeescript, "client.coffee"
  build coffeescript, "compiler/client.coffee"

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
            class: "moon-code"
            id: "moon-" .. tostring i
            raw highlight "moon", code_text
          }
        }

        if nil and page.source\match "^index"
          div {
            __breakclose: true
            class: "code_container"
            code {
              class: "lua_code"
              id: "lua-" .. tostring i
              raw highlight "lua", lua_text
            }
            div {
              class: "rainbow_btn_wrap"
              a {
                href: "#"
                class: "see_lua rainbow_btn"
                code_id: tostring i
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

site\write!
