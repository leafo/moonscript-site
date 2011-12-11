require "sitegen"
require "moonscript"
require "moon"

indexer = require"sitegen.indexer"
extra = require"sitegen.extra"
html = require "sitegen.html"

extra.AnalyticsPlugin.__base.analytics = -> ""

reference_highlight = (code_text) ->
  lua_text = nil
  x = coroutine.create ->
    lua_text = moonscript.to_lua code_text

  pass, err = coroutine.resume x
  if not pass
    print err
    print!
    print code_text
    print!
    return err

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

  i = 0
  with extra.PygmentsPlugin.custom_highlighters
    .bash = (code_text) =>
      html.build -> pre { code_text }

    .moon = (code_text, page) =>
      if page.source\match "reference"
        return reference_highlight code_text

      lua_text = moonscript.to_lua code_text

      html.build ->
        i += 1
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
          pre {
            code {
              class: "moon-code"
              id: "moon-" .. tostring i
              code_text
            }
          }
        }

  -- split the headers
  filter "^index", (body) =>
    body = body\gsub "<h2>.-</h2>", (header) ->
        '</div><div class="box">'..header
    body = indexer.build_from_html body
    body

  filter "reference%.md$", (body) =>
    body = body\gsub "<h1>.-</h1>", (header) ->
      table.concat { '</div>', header, '<div class="main">' }

    body

site\write!
