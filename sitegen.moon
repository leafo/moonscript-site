
require "lfs"
require "cosmo"
require "yaml"
discount = require "discount"

util = require "moonscript.util"

module "sitegen", package.seeall

import insert, concat, sort from table
export create_site

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

punct = "[%^$()%.%[%]*+-?]"
escape_patt = (str) ->
  (str\gsub punct, (p) -> "%"..p)

create_site = (init) ->
  site = extend {
    copy_files: {}
    filters: {}
    written_files: {}
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
    fname = concat { site.out_dir, meta.target, ".html" }
    with io.open fname, "w"
      print "writing", fname
      insert site.written_files, fname
      \write render_page meta, text
      \close!

  get_pages = ->
    return for path in lfs.dir"."
      path if path\match site.page_pattern

  parse_file = (fname) ->
    text = io.open(fname)\read "*a"
    meta = extend {
      target: fname\match site.page_pattern
    }, default_meta

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
      os.execute ("cp %s %s")\format file, target

  site_scope =
    copy_files: (files) ->
      for file in *files
        insert site.copy_files, file
    filter: (name, fn) ->
      insert site.filters, {name, fn}

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

