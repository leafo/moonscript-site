{
  title: "How Variable Scope Works"
  description: "How variables are scoped in MoonScript: assignment creates locals, assigning to an outer name reassigns it, and how to use local, export, and the linter to control scope and avoid accidental globals."
}

In MoonScript, assigning to a name creates a local variable. You never write
`local` for an ordinary variable. The exception is a name that is already
declared in an enclosing scope: assigning to it updates that variable instead
of creating a new one. Global variables are only created with `export`.

These rules remove most of Lua's accidental globals, but they cause a few
surprises of their own. This guide covers how the rules work, the mistakes
they lead to, and the tools for controlling them: `local`, `export`, and the
linter.

## Quick reference

<table class="quick_ref">
  <thead><tr><th>MoonScript</th><th>Effect</th></tr></thead>
  <tbody>
    <tr><td><code>x = 1</code></td><td>Declares a new local <code>x</code>, unless <code>x</code> is already visible, in which case it is reassigned</td></tr>
    <tr><td><code>local x</code></td><td>Declares <code>x</code> in the current scope, before assigning it or to shadow an outer <code>x</code></td></tr>
    <tr><td><code>local *</code></td><td>Declares every name assigned below it in the current scope</td></tr>
    <tr><td><code>export x</code></td><td>Assignments to <code>x</code> set a global variable</td></tr>
    <tr><td><code>import x from t</code></td><td>Declares <code>x</code> as a constant: the linter reports any later assignment to it</td></tr>
    <tr><td><code>moonc -l file.moon</code></td><td>Reports global access, unused assignments, and assignments to constants</td></tr>
  </tbody>
</table>

## Assignment declares a local

The first assignment to a name declares it as a local in the current scope.
The compiler writes the `local` for you:

```moon
name = "Ada"
count = 10
count = count + 1
```

The second assignment to `count` reuses the existing variable. Function
arguments are always new locals, so an argument named the same as an outer
variable never changes it.

A scope is a function body, a loop body, an `if` or `else` block, a `do`
block, or the file itself. A variable declared in a scope is visible in that
scope and every scope nested inside it.

## Assigning to an outer variable reassigns it

When a function assigns to a name that is already declared in an enclosing
scope, it reassigns that variable. No new local is created. This is what makes
closures convenient to write, and it is also the most common source of scoping
bugs in MoonScript:

```moon
name = "report"

format_row = (row) ->
  name = row.name
  "#{name}: #{row.score}"

print format_row name: "ada", score: 10
print name
```

The compiled Lua has no `local` on the assignment inside `format_row`, so the
function overwrites the outer `name`. The last line prints `ada`, not
`report`. The code runs without errors, and the linter doesn't report it,
because reassigning an outer variable is valid. In a long file, the outer
variable can be hundreds of lines away from the function that clobbers it.

There are two ways to make the inner `name` a new variable. Declare it with
`local` inside the function:

```moon
name = "report"

format_row = (row) ->
  local name
  name = row.name
  "#{name}: #{row.score}"
```

The inner assignment then compiles to `local name = row.name`, and the outer
`name` is untouched.

MoonScript also has a [`using`
clause](../reference/#the-language/the-using-clause-controlling-destructive-assignment)
that lists which outer variables a function may reassign. With `(row using nil) ->`,
every assignment in the function creates a new local. The linter reports
reads of outer variables inside a `using` function as global accesses, so
`local` is the better choice for now.

When choosing names at the top level of a module, remember that every function
in the file can reassign them. Short generic names like `name`, `result`, or
`out` at the top of a file are the ones most likely to be overwritten by
accident.

## Using a variable before it is declared

A name refers to a local only after the line that declares it. Above that
line, the same name refers to a global. This matters when one function calls
another that is defined later in the file:

```moon
greet = (name) ->
  format_name name

format_name = (name) ->
  name\upper!

print greet "ada"
```

Inside `greet`, `format_name` isn't declared yet, so the compiled Lua looks
up a global named `format_name`, which doesn't exist:

    lua5.4: greet.lua:3: attempt to call a nil value (global 'format_name')

On Lua 5.1 and LuaJIT:

    luajit: greet.lua:3: attempt to call global 'format_name' (a nil value)

One fix is to define `format_name` before `greet`. When functions call each
other, or when you don't want to order definitions by hand, declare the names
ahead of time with `local`:

```moon
local greet, format_name

greet = (name) ->
  format_name name

format_name = (name) ->
  name\upper!
```

`local *` declares every name that is assigned later in the current scope, so
you don't have to list them. It is useful at the top of a module with many
functions and classes:

```moon
local *

greet = (name) ->
  format_name name

format_name = (name) ->
  name\upper!
```

`local ^` is the same, but only declares names that begin with a capital
letter, such as class names.

## Variables declared inside blocks

A variable assigned for the first time inside an `if` block or a loop is local
to that block. It doesn't exist after the block ends:

```moon
value = 5

if value > 3
  message = "big"
else
  message = "small"

print message
```

Each branch declares its own `message`, and the `print` refers to a global
`message`, which is `nil`. To set a variable from inside a block, declare it
before the block with `local message`. In this case there is a better option:
`if` is an expression, so its result can be assigned directly:

```moon
value = 5

message = if value > 3
  "big"
else
  "small"

print message
```

The same applies to loops. A variable first assigned in a loop body is a new
local on each iteration, and isn't visible after the loop. The loop variable
itself, like `i` in `for i = 1, 10`, is also local to the loop. To use the
values a loop produces, assign the result of the loop with
[comprehensions](../reference/#the-language/comprehensions) or `for` as an
expression.

## Sharing variables between callbacks

Code that defines several callback functions often needs them to share state.
Each callback is its own function scope, so a variable first assigned in one
callback is local to it:

```moon
callbacks = {}

callbacks.load = ->
  player = { x: 10 }

callbacks.update = ->
  player.x += 1
```

`player` in `load` is a local that disappears when `load` returns, and
`player` in `update` refers to a global that was never set:

    lua5.4: callbacks.lua:8: attempt to index a nil value (global 'player')

Declare shared variables in the enclosing scope, before the functions that use
them. Assignments inside the callbacks then update the shared variable:

```moon
local player

callbacks = {}

callbacks.load = ->
  player = { x: 10 }

callbacks.update = ->
  player.x += 1
```

This comes up constantly in game frameworks with separate load, update, and
draw callbacks. See [Making Games with MoonScript and
LÖVE](making-games-with-love.html) for a full example.

## Imported names are constants

Names declared with `import` are tagged as constants. The compiler accepts
assignments to them, but the linter reports each one as an error. An imported
value is almost never meant to change, so an assignment to one is usually the
outer variable bug [described above](#assigning-to-an-outer-variable-reassigns-it):

```moon
import insert, concat from table

insert = 5

join = (items) ->
  concat = ", "
  table.concat items, concat
```

`join` meant to create a local named `concat`, but it reassigns the imported
function instead. The linter reports both assignments:

```bash
$ moonc -l join.moon
```

    join.moon

    line 3: assigning to constant `insert`
    ======================================
    > insert = 5

    line 6: assigning to constant `concat`
    ======================================
    >   concat = ", "

The constant tag follows the normal scoping rules. It applies in nested
functions, and a `local` declaration of the same name creates an ordinary
variable that can be assigned. Importing the same name twice in one scope is
also reported, since the second import assigns to the first. Only `import`
creates constants. A name created by destructuring, like `{:concat} = table`,
is an ordinary variable.

`import` follows the same assignment rule as `=`. If a name is already
declared in an enclosing scope, an `import` inside a function reassigns it
instead of creating a local:

```moon
insert = (t, v) -> t[#t + 1] = v

add = (list, v) ->
  import insert from table
  insert list, v
```

After `add` runs, the outer `insert` is `table.insert`. The linter reports
it:

    line 4: import overwrites existing binding `insert`
    ===================================================
    >   import insert from table

Give one of the two a different name, or call `table.insert` directly instead
of importing it.

## Creating global variables with `export`

Assignment never creates a global variable. To create one, name it with
`export`:

```moon
export VERSION = "1.0"
export log

log = (msg) -> print "[log] #{msg}"

helper = -> "internal"
```

`VERSION` and `log` are globals. `helper` is a local, so it is private to the
file. `export` can also prefix a class declaration, as in `export class
Player`.

`export *` makes every name assigned after it in the current scope a global,
and `export ^` does the same for names that begin with a capital letter.

`export` has no effect on a name that is already declared as a local in the
current scope. The assignment updates the local, and no global is created.

Most code shouldn't need globals. To share values between files, have each
file return a table or a class, and `require` it where it is needed. The last
statement in a file is its return value. See [Writing
Modules](../reference/#the-language/misc/writing-modules). Globals are still
the right tool for some cases, like a configuration file that sets global
values, or a framework that looks up callbacks by global name.

## Finding scope mistakes with the linter

Running `moonc -l` checks files for scope problems without compiling them. Two
of its checks find most scoping mistakes:

* **Global access** reports every reference to a global variable that isn't a
  standard Lua global. A misspelled variable name, a function called before it
  is declared, or a variable used outside the block that declared it all show
  up as global accesses.
* **Unused assignments** reports locals that are assigned but never read. A
  variable that was supposed to be shared, but was declared as a local in the
  wrong scope, often shows up here.

Running the linter on the `if` block example above reports both problems:

```bash
$ moonc -l message.moon
```

    message.moon

    line 4: assigned but unused `message`
    =====================================
    >   message = "big"

    line 6: assigned but unused `message`
    =====================================
    >   message = "small"

    line 8: accessing global `message`
    ==================================
    > print message

The linter also reports [assignments to imported
names](#imported-names-are-constants). It doesn't report reassigning an
ordinary outer variable, because that is valid code.
Each kind of check is a named stage that can be turned on or off with
[`--lint-stage` and
`--exclude-lint-stage`](../reference/command_line.html#command-line-tools/moonc/linter).
Globals that your environment provides, like
`love` in LÖVE or `ngx` in OpenResty, can be whitelisted with a
[lint config file](../reference/command_line.html#command-line-tools/moonc/linter/global-variable-whitelist).

## See also

* [Assignment](../reference/#the-language/assignment)
* [Local statement](../reference/#the-language/local-statement)
* [Export statement](../reference/#the-language/export-statement)
* [Conditionals with assignment](../reference/#the-language/conditionals/with-assignment)
* [The linter](../reference/command_line.html#command-line-tools/moonc/linter)
