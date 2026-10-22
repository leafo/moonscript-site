{
  title: "How to Call Methods"
  description: "How to call methods in MoonScript with the backslash operator, why Lua's colon syntax doesn't work, the difference between \\ and ., and how @ refers to self inside a method."
}

In MoonScript you call a method with a backslash: `obj\method args` compiles
to `obj:method(args)` in Lua. The dot, `obj.method args`, looks up a field
and calls it *without* passing the object as `self`. Inside a method, `@`
refers to `self`, so `@method args` calls another method on the same object.

## Quick reference

<table class="quick_ref">
  <thead><tr><th>MoonScript</th><th>Lua</th><th>Meaning</th></tr></thead>
  <tbody>
    <tr><td><code>obj&#92;method a, b</code></td><td><code>obj:method(a, b)</code></td><td>Call a method, passing <code>obj</code> as <code>self</code></td></tr>
    <tr><td><code>obj&#92;method!</code></td><td><code>obj:method()</code></td><td>Call a method with no arguments</td></tr>
    <tr><td><code>obj.func a</code></td><td><code>obj.func(a)</code></td><td>Call a function stored in a field, no <code>self</code></td></tr>
    <tr><td><code>@name</code></td><td><code>self.name</code></td><td>Read a field on <code>self</code></td></tr>
    <tr><td><code>@method a</code></td><td><code>self:method(a)</code></td><td>Call a method on <code>self</code></td></tr>
    <tr><td><code>f = obj&#92;method</code></td><td><em>(a closure)</em></td><td>Create a function bound to <code>obj</code></td></tr>
  </tbody>
</table>

## Calling a method with <code>&#92;</code>

Lua uses `:` to call a method. MoonScript uses <code>&#92;</code> instead.
Arguments can be written without parentheses, and `!` calls a method with no
arguments:

```moon
file = io.open "notes.txt"
contents = file\read "*a"
file\close!
```

Chained calls work as you would expect, as do calls on the result of an
index or on a literal:

```moon
name = user.profile\display_name!
upper = "hello world"\upper!
result = builder\select("id")\where(active: true)\limit 10
```

All of Lua's string methods work this way, since strings use the `string`
table as their metatable:

```moon
str = "MoonScript"
print str\sub 1, 4
print str\lower!, str\len!
```

## Why Lua's `:` doesn't work

The colon is already used in MoonScript to write key and value pairs in
tables. Writing a Lua-style method call **does not cause a compile error**. It
creates a table instead:

```moon
contents = file:read "*a"
```

The code compiles, and fails when it runs. The compiled Lua calls a global
function named `read`, which doesn't exist:

    lua5.4: notes.lua:1: attempt to call a nil value (global 'read')

On Lua 5.1 and LuaJIT the same error is worded differently:

    luajit: notes.lua:1: attempt to call global 'read' (a nil value)

If you see `attempt to call a nil value (global '...')` for something that
looks like a method name, look for a `:` that should be a <code>&#92;</code>.

## The difference between <code>&#92;</code> and `.`

The dot accesses a field and calls whatever is there as an ordinary function.
No `self` is passed. This is correct for module functions and for functions
stored in a table:

```moon
json = require "cjson"
encoded = json.encode { 1, 2, 3 }
```

Using a dot to call a method is a mistake. The method receives no `self`, and
fails as soon as it reads a field:

```moon
class Person
  new: (@name) =>
  greet: => print "Hello, I am #{@name}"

person = Person "Ada"
person.greet!
```

Running this gives:

    lua5.4: person.lua:6: attempt to index a nil value (local 'self')

On Lua 5.1 and LuaJIT:

    luajit: person.lua:6: attempt to index local 'self' (a nil value)

The fix is `person\greet!`.

## Using `@` inside methods

A method is a function defined with the fat arrow, `=>`. The fat arrow adds a
`self` argument, and inside the method `@` is shorthand for `self`:

```moononly
class Counter
  new: =>
    @count = 0

  increment: (amount=1) =>
    @count += amount
    @report!

  report: =>
    print "count is #{@count}"
```

`@count` reads a field, and `@report!` calls a method, compiling to
`self:report()`. When `@` is followed by a name and then arguments, it is a
method call:

```moononly
class Greeter
  greet: (name) => print "Hello, #{name}"
  greet_all: (names) =>
    for name in *names
      @greet name
```

To call a function stored on `self` *without* passing `self`, index it with a
dot: `@.callback value` compiles to `self.callback(value)`.

### `=>` vs `->`

A function defined with the thin arrow, `->`, gets no `self` argument. Using
`->` for a method, and then calling it with <code>&#92;</code>, shifts every
argument by one position, because the object fills the first parameter:

```moon
class Tag
  set_name: (name) -> @name = name
```

Here `@name` refers to a `self` that the function never defines. Use `=>` for
anything that will be called as a method, including `new`.

## Getting a method as a function

Sometimes you need to pass a method somewhere that expects a plain function,
such as a callback. Writing `obj\method` without calling it creates a new
function with `obj` bound as `self`:

```moon
on_click = button\handle_click
register "click", on_click
```

The same works with `import`. Prefixing a name with <code>&#92;</code> imports
it as a function bound to the object:

```moon
import \open, \close from session
open!
```

## Calling MoonScript methods from Lua

MoonScript classes compile to ordinary Lua tables and metatables, so Lua code
calls their methods with the normal `:` syntax:

```lua
local Person = require("person")
local p = Person("Ada")
p:greet()
```

## See also

* [Function literals and fat arrows](../reference/#the-language/function-literals/fat-arrows)
* [Classes and object oriented programming](../reference/#the-language/object-oriented-programming)
* [`@` and `@@` values](../reference/#the-language/object-oriented-programming/-and-values)
* [Function stubs](../reference/#the-language/function-stubs)
* [Import statement](../reference/#the-language/import-statement)
