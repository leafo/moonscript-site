require "sitegen"
require "moonscript"
require "moon"

indexer = require"sitegen.indexer"
extra = require"sitegen.extra"
html = require "sitegen.html"

extra.AnalyticsPlugin.__base.analytics = -> ""

site = sitegen.create_site =>
  @title = "MoonScript"
  @moon_version = require"moonscript.version".version
  copy "highlight.js", "client.js"

  i = 0
  with extra.PygmentsPlugin.custom_highlighters
    .bash = (code_text) =>
      html.build -> pre { code_text }

    .moon = (code_text) =>
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


site\write!
