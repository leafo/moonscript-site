
require "lfs"
require "cosmo"
require "yaml"
discount = require "discount"

util = require "moonscript.util"

module "sitegen", package.seeall

import insert, concat, sort from table
export create_site, html_encode, html_decode, slugify
export index_headers

punct = "[%^$()%.%[%]*+%-?]"
escape_patt = (str) ->
  (str\gsub punct, (p) -> "%"..p)

html_encode_entities = {
  ['&']: '&amp;'
  ['<']: '&lt;'
  ['>']: '&gt;'
  ['"']: '&quot;'
  ["'"]: '&q#039;'
}

html_decode_entities = {}
for key,value in pairs html_encode_entities
  html_decode_entities[value] = key

html_encode_string = "[" .. concat([escape_patt char for char in pairs html_encode_entities]) .. "]"
html_encode = (text) ->
  (text\gsub html_encode_string, html_encode_entities)

html_decode = (text) ->
  (text\gsub "(&[^&]-;)", (enc) ->
    decoded = html_decode_entities[enc]
    decoded if decoded else enc)

strip_tags = (html) ->
  html\gsub "<[^>]+>", ""

-- filter to build index for headers
index_headers = (body, meta) ->
  headers = {}

  current = headers
  fn = (body, i) ->
    i = tonumber i
    if not current.depth
      current.depth = i
    else
      if i > current.depth
        current = parent: current, depth: i
      else
        while i < current.depth and current.parent
          insert current.parent, current
          current = current.parent

        current.depth = i if i < current.depth

    slug = slugify html_decode body
    insert current, {body, slug}
    concat {
      '<h', i, '><a name="',slug,'"></a>', body, '</h', i, '>'
    }

  require "lpeg"
  import P, R, Cmt, Cs, Cg, Cb, C from lpeg

  nums = R("19")
  open = P"<h" * Cg(nums, "num") * ">"

  close = P"</h" * C(nums) * ">"
  close_pair = Cmt close * Cb("num"), (s, i, a, b) -> a == b
  tag = open * C((1 - close_pair)^0) * close

  patt = Cs((tag / fn + 1)^0)
  out = patt\match(body)

  while current.parent
    insert current.parent, current
    current = current.parent

  out, headers


slugify = (text) ->
  text = strip_tags text
  text = text\gsub "[&+]", " and "
  (text\lower!\gsub("%s+", "_")\gsub("[^%w_]", ""))

sys =
  mkdir: (path) ->
    os.execute ("mkdir -p %s")\format path
  copy: (src, dest) ->
    os.execute ("cp %s %s")\format src, dest

-- don't forget trailing /
config =
  template_dir: "template/"
  out_dir: "www/"
  page_pattern: "^(.*)%.md$"
  write_gitignore: true

default_meta =
  template: "index"

extend = (table, index) ->
  -- setmetatable table, __index: index
  for k,v in pairs index
    if table[k] == nil
      table[k] = v
  table


create_site = (init) ->
  site = extend {
    copy_files: {}
    additional_files: {}
    filters: {}
    written_files: {}
    generate_date: os.date!
  }, config

  template_cache = {}
  fill_template = (context, name) ->
    if not template_cache[name]
      file = io.open concat { site.template_dir, name, ".html"}
      template_cache[name] = cosmo.f file\read "*a"

    template_cache[name] context

  render_page = (meta, text) ->
    text = discount text
    for filter in *site.filters
      patt, action = unpack filter
      if meta.target\match patt
        text = action text, meta
        break

    meta = extend { main: text }, meta
    fill_template meta, meta.template

  write_page = (meta, text) ->
    -- pull the path
    dir, target = meta.target\match"^(.*)/([^/]*)$"
    if dir
      sys.mkdir site.out_dir .. dir

    fname = concat { site.out_dir, meta.target, ".html" }
    with io.open fname, "w"
      print "writing", fname
      insert site.written_files, fname
      \write render_page meta, text
      \close!

  get_pages = ->
    set = {}
    files = [file for file in *site.additional_files]
    set[file] = true for file in *files

    for path in lfs.dir"."
      if path\match(site.page_pattern) and not set[path]
        table.insert(files, path)

    files

  parse_file = (fname) ->
    text = io.open(fname)\read "*a"
    meta = extend {
      target: fname\match site.page_pattern
      current_page: fname
    }, extend default_meta, site

    s, e = text\find "%-%-\n"
    if s
      header = yaml.load text\sub 1, s - 1
      meta = extend header, meta if header
      text = text\sub e

    write_page meta, text

  copy_files = (files) ->
    for file in *files
      target = site.out_dir .. file
      print "copied", target
      insert site.written_files, target
      sys.copy file, target

  site_scope =
    copy_files: (files) ->
      for file in *files
        insert site.copy_files, file
    filter: (name, fn) ->
      insert site.filters, {name, fn}
    add_file: (file) ->
      table.insert(site.additional_files, file)

  if init
    setfenv init, setmetatable site_scope, __index: getfenv init
    init site


  {
    write: =>
      parse_file fname for fname in *get_pages!
      copy_files site.copy_files

      if site.write_gitignore
        with io.open site.out_dir .. ".gitignore", "w"
          patt = "^" .. escape_patt(site.out_dir) .. "(.+)$"
          relative = [fname\match patt for fname in *site.written_files]
          \write concat relative, "\n"
          \close!
  }

