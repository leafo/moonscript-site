
require "sitegen"
util = require "moonscript.util"

require "moonscript.parse"
require "moonscript.compile"

import parse, compile from moonscript
import html_decode, html_encode from sitegen

is_moonscript = (text) ->
  not text\match "~>"

compile_pre_tags = (body, action) ->
  body\gsub "(<pre><code>(.-)</code></pre>)", (block, code) ->
    moon_code = html_decode code
    if is_moonscript moon_code
      tree, te = parse.string moon_code
      lua_code, ce = compile.tree tree

      if not tree or not lua_code
        print "++ Failed to compile chunk"
        print moon_code
        print!
        block
      else
        action html_encode(moon_code), html_encode(lua_code)
    else
      block

site = sitegen.create_site =>
  @root = "/moon/www"
  copy_files {"highlight.js", "client.js"}

  filter "^reference", (body, meta) ->
    body, index = sitegen.index_headers body, meta

    yield_index = (index) ->
      for item in *index
        if item.depth
          cosmo.yield _template: 2
          yield_index item
          cosmo.yield _template: 3
        else
            cosmo.yield name: item[1], target: item[2]

    meta.index = ->
      yield_index index

    compile_pre_tags body, (moon, lua) ->
      table.concat {
        '<table style="width: 100%;" cellspacing="0" cellpadding="1">'
        '<tr class="code-header"><td>moonscript</td><td>lua</td></tr>'
        '<tr><td style="width: 50%" class="code-border"><pre><code class="moon-code">'
          moon,'</code></pre></td>'
        '<td><pre><code class="lua-code">',lua,'</code></pre></td>'
        '</tr></table>'
      }

  filter "^index", (body, meta) ->
    body = body\gsub "<h2>.-</h2>", (header) ->
        '</div><div class="box">'..header

    i = 0
    compile_pre_tags body, (moon, lua) ->
      i += 1
      table.concat {
        '<div class="code-container">'
        '<code class="lua-code" id="lua-',i,'">',lua,'</code>'
        '<button class="see-lua" code_id="',i,'">See Lua</button>'
        '<pre><code class="moon-code" id="moon-',i,'">', moon, "</code></pre>"
        '</div>'
      }

site\write!
