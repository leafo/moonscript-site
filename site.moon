
require "sitegen"
util = require "moonscript.util"

site = sitegen.create_site =>
  copy_files {"highlight.js"}
  filter "index", (content, meta) ->
    first = true
    content\gsub "<h2>.-</h2>" (header) ->
      if first
        first = false
        header
      else
        '</div><div class="box">'..header

site\write!
