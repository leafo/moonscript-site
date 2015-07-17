<div id="intro"></div>
**MoonScript** is a dynamic scripting language that compiles into
[Lua](http://www.lua.org/). It gives you the power of one of the fastest
scripting languages combined with a rich set of features.

```moon
class Thing
  name: "unknown"

class Person extends Thing
  say_name: => print "Hello, I am #{@name}!"

with Person!
  .name = "MoonScript"
  \say_name!
```

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

<div id="overview"></div>
## Overview

MoonScript provides a clean syntax using significant whitespace that avoids all
the keyword noise typically seen in a Lua script. Below is a sample of some
constructs found in the language.

```moon
export my_func
x = 2323

collection =
  height: 32434
  hats: {"tophat", "bball", "bowler"}

my_func = (a) -> x + a

print my_func 100
```

It also adds [table comprehensions](reference/#table_comprehensions), [implicit return](reference/#function_literals) on functions, [classes](reference/#object_oriented_programming),
[inheritance](reference/#inheritance), scope management statements [import](reference/#import_statement) & [export](reference/#export_statement), and a convenient
object creation statement called [with](reference/#with_assignment).

```moon
import concat, insert from table

double_args = (...) ->
  [x * 2 for x in *{...}]

tuples = [{k, v} for k,v in ipairs my_table]
```

It can be loaded directly from a Lua script [without an intermediate
compile step](reference/api.html#autocompiling_with_the_moonscript_module). It even knows how to [tell you
where errors occurred](reference/command_line.html#error_rewriting) in the original file when
they happen.

<div id="installation"></div>
## Installation

<div id="installing_with_luarocks"></div>
### Installing with LuaRocks

If you're on Windows, then install the [Windows binaries](#windows_binaries),
otherwise the easiest way to install is to use LuaRocks.

LuaRocks can be obtained [here](http://www.luarocks.org/) or from your package
manager.

After it is installed, run the following in a terminal:

```bash
$ luarocks install moonscript
```

This will provide the `moon` and `moonc` executables along with the
`moonscript` and `moon` Lua module.


<div id="windows_binaries"></div>
### Windows Binaries

Precompiled Windows binaries are available to avoid the trouble of compiling:  
<http://moonscript.org/bin/moonscript-0.3.0.zip>

Extract the contents into your `PATH`.

<div id="optional"></div>
### Optional

If you're on Linux and use *watch* mode (which compiles `.moon` files to `.lua`
files as they are changed) you can install
[linotify](https://github.com/hoelzro/linotify) to use inotify instead of
polling.

<div id="source"></div>
## Source

The source code to the project lives on GitHub:  
<https://github.com/leafo/moonscript>

Issues with the tool can be reported on the issue tracker:  
<https://github.com/leafo/moonscript/issues>

The latest development version can be installed with the dev rockspec:

```bash
$ luarocks install \
    http://moonscript.org/rocks/moonscript-dev-1.rockspec
```

### Dependencies

In addition to [Lua 5.1 or 5.2](http://lua.org), the following Lua modules are
required to run the compiler and associated tools:

 * [LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html)
 * [LuaFileSystem](http://keplerproject.github.com/luafilesystem/)
 * [alt-getopt](http://luaforge.net/projects/alt-getopt/)
 * and [optionally](#optional) on Linux [linotify](https://github.com/hoelzro/linotify)

All of the required ones can be retrieved automatically using the
[LuaRocks](#installing_with_luarocks) installation.

<div id="learning"></div>
## Learning

 * [Official reference manual](reference/)
 * [Installation tutorial](http://leafo.net/posts/getting_started_with_moonscript.html)
 * [MoonScript examples](https://github.com/leafo/moonscript/wiki/Moonscript-Examples)

<div id="extras"></div>
## Extras & Addons

### Editor Support

Vim syntax and indent:  
<https://github.com/leafo/moonscript-vim>

Textmate (and Sublime Text) syntax and indent:  
<https://github.com/leafo/moonscript-tmbundle>

SciTE (with scintillua) syntax:  
<https://github.com/leafo/moonscript/tree/master/extra/scintillua>

Preconfigured and packaged version of SciTE for Windows with MoonScript
support:  
<http://moonscript.org/scite/>

MoonScript module for the Textadept editor, written in MoonScript
<https://github.com/rgieseke/ta-moonscript>

### Tools

Online Compiler:  
<http://moonscript.org/compiler/>

## Overview of Differences & Highlights

A more detailed overview of the syntax can be found in the
[reference manual](reference/).

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

<div id="about"></div>
## About

The syntax of MoonScript has been heavily inspired by the syntax of
[CoffeeScript](http://jashkenas.github.io/coffee-script/). MoonScript is
CoffeeScript for Lua.

MoonScript would not have been possible without the excellent tool
[LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/) for parsing.

<a name="change_log"></a>
## Changelog

 * [0.3.0](https://github.com/leafo/moonscript/blob/master/CHANGELOG.md#moonscript-v030-2015-2-28)-- February 28 2015
 * [0.2.6](https://github.com/leafo/moonscript/blob/master/CHANGELOG.md#moonscript-v026-2014-6-18)-- June 19 2014
 * [0.2.5](https://github.com/leafo/moonscript/blob/master/CHANGELOG.md#moonscript-v025-2014-3-5)-- March 5 2014
 * [0.2.4](http://leafo.net/posts/moonscript_v024.html)-- July 2 2013
 * 0.2.3-2 -- Jan 29 2013, Fixed bug with moonloader not loading anything
 * [0.2.3](http://leafo.net/posts/moonscript_v023.html) -- Jan 24 2013
 * [0.2.2](http://leafo.net/posts/moonscript_v022.html) -- Nov 04 2012
 * [0.2.0](http://leafo.net/posts/moonscript_v020.html) -- Dec 11 2011

