
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

    body\gsub "(<pre><code>(.-)</code></pre>)", (block, code) ->
      _code = code
      code = reconvert_html code
      if is_moonscript code
        tree, e = moonscript.parse.string code
        lua = moonscript.compile.tree tree

        table.concat {
          '<div class="code-container">'
          '<pre class="popup"><code class="lua-code">', lua , '</code></pre>'
          '<button class="see-lua">See Lua</button>'
          '<pre><code class="moon-code">', _code, "</code></pre>"
          '</div>'
        }
      else
        block

site\write!
