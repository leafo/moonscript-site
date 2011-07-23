require "lfs"
require "yaml"
require "date"
require "cosmo"
discount = require "discount"

import insert, concat, sort from table
export write_post, write_index

_term = not package.loaded.build

config =
  build_dir: "www/"
  template_dir: "template/"

format_date = (d) ->
	day = tonumber d:fmt "%d"
	t = { "st", "nd", "rd" }
	day = tostring(day)..(t[day] or "th")
	d:fmt("%B "..day..", %Y")

read_all = (fname) ->
  f = io.open fname
  error "failed to open file: "..fname if not f
  out = f:read"*a"
  f:close!
  out

file_put = (fname, str) ->
  with io.open fname, "w"
    :write str
    :close!

build_index = (posts) ->
  by_date = {}
  by_name = {}

  index = (post) ->
    insert by_date, post
    by_name[post.base_name] = post

  sort by_date, (a, b) -> a.post_date > b.post_date

  posts.by_date = by_date
  posts.by_name = by_name

  posts

build_post = (text, base_name) ->
  s, e = text:find "%%", nil, true
  error "Failed to find meta-delimiter on post: "..base_name if not e

  meta = yaml.load text:sub 1, s - 1
  text = text:sub e + 1

  error "Post date required in "..base_name if not meta.post_date

  meta.post_date = date meta.post_date
  meta.format_date = format_date meta.post_date

  meta.raw_date = (meta.post_date - date.epoch()):spanseconds()

  meta.body = discount text
  meta.url = base_name .. ".html"
  meta.out_name = config.build_dir .. meta.url
  meta.base_name = base_name
  meta

load_templates = (tpl) ->
  tpl[k] = cosmo.f read_all config.template_dir..v for k,v in pairs tpl
  tpl

tpl = load_templates {
  wrapper: "index.html"
  post: "post.html"
  post_list: "post_list.html"
}

-- wrap in template
-- body set to nil because it's not needed
write_post = (post) ->
  file_put post.out_name, tpl.wrapper body: tpl.post post
  post.body = nil


write_index = (index) ->
  file_put config.build_dir .. "index.html", tpl.wrapper {
    body: tpl.post_list index
  }

-- now do the actual writing
posts = {}
check_file = (fname) ->
  base_name = fname:match "^(.*)%.md$"
  if base_name
    id, _name = base_name:match "^(..)-(.*)$"
    if id then base_name = _name

    f = io.open fname
    post = build_post f:read"*a", base_name
    f:close!

    write_post post
    insert posts, post

if _term
  check_file fname for fname in lfs.dir"."
  write_index build_index posts

