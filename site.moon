require "sitegen"

moonscript = require "moonscript"
indexer = require"sitegen.indexer"
extra = require"sitegen.extra"
html = require "sitegen.html"
tools = require"sitegen.tools"

highlight = extra.PygmentsPlugin\highlight


try_compile = (text, options=implicitly_return_root: false) ->
  out = nil
  c = coroutine.create ->
    out = moonscript.to_lua text, options

  pass, err = coroutine.resume c

  if pass
    out
  else
    print err
    print!
    print text
    print!
    nil, err


split_highlight = (code_text, options) ->
  lua_text, err = try_compile code_text, options
  return err if not lua_text

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
  add "compiler/index.html", template: false

  deploy_to "leaf@leafo.net", "www/moonscript.org"

  scssphp = tools.system_command "pscss < %s > %s", "css"
  coffeescript = tools.system_command "coffee -c -s < %s > %s", "js"

  build scssphp, "ref.scss"
  build scssphp, "style.scss"
  build scssphp, "compiler/style.scss"

  build coffeescript, "highlight.coffee"
  build coffeescript, "client.coffee"
  build coffeescript, "compiler/client.coffee"

  i = 0
  with extra.PygmentsPlugin.custom_highlighters
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

        if page.source\match "^index"
          div {
            __breakclose: true
            class: "code-container"
            code {
              class: "lua-code"
              id: "lua-" .. tostring i
              raw highlight "lua", lua_text
            }
            button {
              class: "see-lua"
              code_id: tostring i
              "See Lua"
            }
            moon_pre
          }
        else
          moon_pre

    .moonret = (code_text, page) =>
      split_highlight code_text, {}

    .moononly = (code_text, page) =>
      single_highlight code_text

  -- split the headers
  filter "^index", (body) =>
    body = body\gsub "<h2>.-</h2>", (header) ->
        '</div><div class="box">'..header
    body = indexer.build_from_html body
    body

  filter "docs", (body) =>
    body\gsub "<h1>.-</h1>", (header) ->
      table.concat { '</div>', header, '<div class="main">' }

site\write!
