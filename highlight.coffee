
Set = (items) ->
  out = {}
  out[item] = true for item in items
  out

class Lexer
  attr_name: "style"
  constructor: ->
    @match_name_table = []
    
    matches = []
    for name, pattern of @matches
      pattern = if pattern instanceof Array
        count = pattern.length
        @match_name_table.push name for k in [1..count]
        ("(" + @escape(key) + ")" for key in pattern).join "|"
      else
        @match_name_table.push name
        "(" + pattern.source + ")"

      matches.push pattern

    patt = matches.join "|"
    @r = new RegExp patt, "g"
    @replace_all()

  replace_all: ->
    cls_name = "." + @name + "-code"
    nodes = document.querySelectorAll cls_name
    for node in nodes
      node.innerHTML = @format_text node.innerHTML

  format_text: (text) ->
    text.replace @r, (match, params...) =>
      i = 0
      while not params[i] and i < params.length
        i++

      name = @match_name_table[i]
      @style match, @get_style name, match

  get_style: (name, value) ->
    fn = @theme[name]
    throw Error "unknown highlight type: " + name if not fn

    if typeof fn == "function"
      fn value
    else
      fn

  style: (text, style) ->
    "<span #{@attr_name}=\"#{style}\">#{text}</span>"

  escape: (text) ->
    text.replace /[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"

class Lua extends Lexer
  name: "lua"
  matches:
    keyword: ["for", "function", "end", "local"]
    number: /\d+/
    string: /"[^"]*"/

  theme:
    string: "color: orange"
    number: "color: purple"
    keyword: "color: red; font-weight: bold"

class Moon extends Lexer
  name: "moon"
  matches:
    keyword: [
      "class", "extends", "if", "then"
      "do", "with", "import", "export", "while"
      "elseif"
    ]
    self: ["self"]
    symbol: ['!', '\\', '=']
    fn_symbol: ['->', '=>']
    assign: /[a-zA-Z_][a-zA-Z_0-9]*:/
    self_var: /@[a-zA-Z_][a-zA-Z_0-9]*/
    number: /\d+/
    string: /"[^"]*"/

  theme:
    keyword: "color: green"
    symbol: "color: red; font-weight: bold"
    assign: "color: orange"
    self: "color: blue"
    self_var: "color: blue"
    string: "color: brown"

window.Lexer = Lexer
window.Lua = Lua
window.Moon = Moon
