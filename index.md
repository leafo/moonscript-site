**MoonScript** is a dynamic scripting language that compiles into
[Lua](http://ww.lua.org/). It gives you the power of the fastest scripting
language combined with a rich set of features.

    class Thing
      name: "unknown"
    
    class Person extends Thing
      say_name: => print "Hello, I am", @name
	
	with Person!
	  .name = "Moonscript"
	  \say_name!

MoonScript can either be compiled into Lua and run at a later time, or it can
be dynamically compiled and run using the *moonloader*. It's as simple as
`require "moonscript"` in order to have Lua understand how to load and run any
MoonScript file.

Because it compiles right into Lua code, it is completely compatible with
alternative Lua implementations like [LuaJIT](http://luajit.org), and it is
also compatible with all existing Lua code and libraries.

The command line tools also let you run MoonScript directly from the
command line, like any first-class scripting language.

A comprehensive overview of the language can be found in the [reference
manual](reference/), the rest of this page serves as an overview of the
language.

## Overview

MoonScript provides a clean syntax using significant whitespace that avoids all
the keyword noise typically seen in a Lua script. Below is a sample of some
constructs found in the languge.

	export my_func
	x = 2323

	collection =
	  height: 32434
	  hats: {"tophat", "bball", "bowler"}

	my_func = (a) -> x + a

	print my_func 100

It also adds table comprehensions, implicit return on functions, classes,
inheritance, scope management statements `import` & `export`, and a convenient
object creation statement called `with`.

	import concat, insert from table

    double_args = (...) ->
      [x * 2 for x in *{...}]

    tuples = [{k, v} for k,v in ipairs my_table]

It can be loaded directly from a Lua script without an intermediate compile
step. It even knows how to tell you where errors occurred in the original file
when they happen.

## Installation

### Installing with LuaRocks

The easiest way to install is to use Lua rocks and the provide rockspec.

LuaRocks can be obtained [here](http://www.luarocks.org/) or from your package
manager.

After it is installed, run the following in a terminal:

    ~> wget https://moonscript.org/rocks/moonscript-dev-1.rockspec
    ~> luarocks install moonscript-dev-1.rockspec

This will provide the `moon` and `moonc` tools along with the `moonscript`
Lua module.

### Optional

If you are on Linux and want to run *watch* mode, which compiles `.moon` files to
`.lua` files as they are changed, you can install
[linotify](https://github.com/hoelzro/linotify).


## Source

The sourcecode to the project lives on github:  
<https://github.com/leafo/moonscript>.

Issues with the tool can be reported on the issue tracker:  
<https://github.com/leafo/moonscript/issues>

### Dependencies

In addition to [Lua 5.1](http://lua.org), the following Lua modules are
required to run the compiler and associated tools:

 * [LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html)
 * [LuaFileSystem](http://keplerproject.github.com/luafilesystem/)
 * [alt-getopt](http://luaforge.net/projects/alt-getopt/)
 * and optionally on Linux [linotify](https://github.com/hoelzro/linotify)

All of the required ones can be retrieved automatically using the
[LuaRocks](#installing_with_luarocks) installation.

## Learning

A comprehensive [reference manual](reference/) is available.

## Overview of Differences & Highlights

A more detailed overview of the syntax can be found in the
[documentation](docs/index.md).

 * Whitespace sensitive blocks defined by indenting
 * All variable declarations are local by default
 * `export` keyword to declare global variables, `import` keyword to make local
   copies of values from a table
 * Parentheses are optional for function calls, similar to Ruby
 * Fat arrow, `=>`, can be used to create a function with a self argument
 * `@` can be prefixed in front of a name to refer to that name in `self`
 * `!` operator can be used to call a function with no arguments
 * Implicit return on functions based on the type of last statement
 * `:` is used to separate key and value in table literals instead of `=`
 * Newlines can be used as table literal entry delimiters in addition to `,`
 * \ is used to call a method on an object instead of `:`
 * `+=`, `-=`, `/=`, `*=`, `%=` operators
 * `!=` is an alias for `~=`
 * Table comprehensions, with convenient slicing and iterator syntax
 * Lines can be decorated with for loops and if statements at the end of the line
 * If statements can be used as expressions
 * Class system with inheritance based on metatable's `__index` property
 * Constructor arguments can begin with `@` to cause them to automatically be
   assigned to the object
 * Magic `super` function which maps to super class method of same name in a
   class method
 * `with` statement lets you access anonymous object with short syntax


