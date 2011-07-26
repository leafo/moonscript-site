
require "sitegen"
util = require "moonscript.util"

require "moonscript.parse"
require "moonscript.compile"

is_moonscript = (text) ->
  return not text\match "~>"

reconvert_html = (text) ->
  text\gsub "&gt;", ">"

site = sitegen.create_site =>
  copy_files {"highlight.js"}
  filter "index", (body, meta) ->
    body = body\gsub "<h2>.-</h2>", (header) ->
        '</div><div class="box">'..header

    i = 0
    body\gsub "(<pre><code>(.-)</code></pre>)", (block, code) ->
      _code = code
      code = reconvert_html code
      if is_moonscript code
        tree, e = moonscript.parse.string code
        lua = moonscript.compile.tree tree
        i += 1
        table.concat {
          '<div class="code-container">'
          '<code class="lua-code" id="lua-',i,'">',lua,'</code>'
          '<button class="see-lua" code_id="',i,'">See Lua</button>'
          '<pre><code class="moon-code" id="moon-',i,'">', _code, "</code></pre>"
          '</div>'
        }
      else
        block

site\write!
