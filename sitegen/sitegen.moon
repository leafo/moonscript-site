module "sitegen", package.seeall

require "lfs"
require "yaml"
require "date"
require "cosmo"
discount = require "discount"

from table import concat, insert

import insert, concat, sort from table
export write_post, write_index

read_all = (fname) ->
  f = io.open fname
  error "failed to open file: "..fname if not f
  out = f\read"*a"
  f\close!
  out

file_put = (fname, str) ->
  with io.open fname, "w"
    \write str
    \close!

mkdir = (path) ->
  "hello world"

