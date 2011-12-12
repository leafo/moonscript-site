require "sitegen"
require "moonscript"
require "moon"

indexer = require"sitegen.indexer"
extra = require"sitegen.extra"
html = require "sitegen.html"

-- extra.AnalyticsPlugin.__base.analytics = -> ""

try_compile = (text) ->
  out = nil
  c = coroutine.create ->
    out = moonscript.to_lua text

  pass, err = coroutine.resume c

  if pass
    out
  else
    print err
    print!
    print text
    print!
    nil, err


reference_highlight = (code_text) ->
  lua_text, err = try_compile code_text
  return err if not lua_text

  html.build ->
    tag.table {
      __breakclose: true
      width: "100%"
      cellspacing: "0"
      cellpadding: "1"

      tr {
        class: "code-header"
        td "moonscript"
        td "lua"
      }

      tr {
        td {
          width: "50%"
          class: "code-border"
          pre code {
            class: "moon-code"
            code_text
          }
        }

        td pre code {
          class: "lua-code"
          lua_text
        }

      }

    }

site = sitegen.create_site =>
  @title = "MoonScript"
  @moon_version = require"moonscript.version".version
  copy "highlight.js", "client.js"
  add "moonscript/docs/reference.md"
  add "moonscript/docs/standard_lib.md"

  deploy_to "leaf@leafo.net", "www/moonscript.org"

  i = 0
  with extra.PygmentsPlugin.custom_highlighters
    .moon = (code_text, page) =>
      if page.source\match "reference"
        return reference_highlight code_text

      lua_text, err = try_compile code_text
      return err if not lua_text

      html.build ->
        i += 1

        moon_pre = pre {
          __breakclose: true
          code {
            class: "moon-code"
            id: "moon-" .. tostring i
            code_text
          }
        }

        if page.source\match "^index"
          div {
            __breakclose: true
            class: "code-container"
            code {
              class: "lua-code"
              id: "lua-" .. tostring i
              lua_text
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
