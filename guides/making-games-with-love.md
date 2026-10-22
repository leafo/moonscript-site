{
  title: "Making Games with MoonScript and LÖVE"
  description: "How to write a LÖVE (love2d) game in MoonScript: project setup, compiling with moonc, a complete example game, finding error line numbers, and packaging a .love file for itch.io."
}

[LÖVE](https://love2d.org) is a framework for making 2D games in Lua.
Because MoonScript compiles to plain Lua, you can write an entire LÖVE game in
MoonScript: compile each `.moon` file to a `.lua` file next to it, and LÖVE
runs the result like any other Lua game. There is no runtime library to ship
and no performance cost. MoonScript classes work well for game objects like
players, enemies, and scenes.

This guide builds a small game for LÖVE 11.5, then covers the development
loop, debugging, and packaging a `.love` file to publish.

## Project layout

LÖVE looks for `main.lua` and `conf.lua` in the game directory, so the
simplest setup is a flat directory where every `.moon` file compiles to a
`.lua` file beside it:

    star-catcher/
      conf.moon     -> conf.lua
      main.moon     -> main.lua
      player.moon   -> player.lua
      star.moon     -> star.lua
      images/
      sounds/
      Makefile

The compiled `.lua` files are build output. Add `*.lua` and `*.love` to your
`.gitignore` so only the MoonScript source is tracked.

## A complete example

The example is a game where you move left and right to catch falling stars.
Start with `conf.moon`, which configures the window:

```moon
love.conf = (t) ->
  t.version = "11.5"
  t.identity = "star_catcher"
  t.window.title = "Star Catcher"
  t.window.width = 640
  t.window.height = 480
```

The player is a class in its own file, `player.moon`. The last statement in a
file is its return value, so `require "player"` returns the class:

```moononly
class Player
  speed: 240
  size: 24

  new: (@x, @y) =>

  update: (dt) =>
    dx = 0
    dx -= 1 if love.keyboard.isDown "left"
    dx += 1 if love.keyboard.isDown "right"
    @x += dx * @speed * dt

  draw: =>
    love.graphics.setColor 0.4, 0.8, 1
    love.graphics.rectangle "fill", @x, @y, @size, @size

  touches: (other) =>
    @x < other.x + other.size and other.x < @x + @size and
      @y < other.y + other.size and other.y < @y + @size
```

`star.moon` follows the same pattern. Its `update` method returns `true` while
the star is still on screen, which makes removing finished objects easy:

```moononly
class Star
  size: 10

  new: =>
    @x = love.math.random 0, love.graphics.getWidth! - @size
    @y = -@size
    @speed = love.math.random 80, 180

  -- returns true while the star is still on screen
  update: (dt) =>
    @y += @speed * dt
    @y < love.graphics.getHeight!

  draw: =>
    love.graphics.setColor 1, 0.9, 0.3
    love.graphics.rectangle "fill", @x, @y, @size, @size
```

Finally `main.moon` sets up LÖVE's callbacks:

```moon
Player = require "player"
Star = require "star"

local player, stars, score, spawn_timer

love.load = ->
  player = Player 308, 420
  stars = {}
  score = 0
  spawn_timer = 0

love.update = (dt) ->
  player\update dt

  spawn_timer -= dt
  if spawn_timer <= 0
    table.insert stars, Star!
    spawn_timer = 0.4

  stars = for star in *stars
    continue unless star\update dt

    if player\touches star
      score += 1
      continue

    star

love.draw = ->
  star\draw! for star in *stars
  player\draw!

  love.graphics.setColor 1, 1, 1
  love.graphics.print "score: #{score}", 10, 10
```

A few things to notice:

* **The `local` line matters.** Assigning a name that isn't already declared
  creates a new local in the current function. Without the `local` line,
  `player = Player 308, 420` inside `love.load` would create a local that
  disappears when `love.load` returns, and `love.update` would see `nil`.
  Declaring the names at the top of the file lets every callback share them.
* **`for` is an expression.** `stars = for star in *stars` builds a new list
  from the values the loop body produces. `continue` skips a star, so stars
  that fell off screen or were caught are dropped.
* **Methods are called with <code>&#92;</code>.** `player\update dt` compiles to
  `player:update(dt)`. See [How to Call Methods](calling-methods.html).

Compile everything and run it:

```bash
$ moonc --correlate *.moon
$ love .
```

## The development loop

Use a `Makefile` so building and running is a single command. Use `moonc
*.moon` rather than `moonc .`, so that libraries in subdirectories aren't
compiled by accident. The `--correlate` flag keeps line numbers in error
messages matching your MoonScript files, as explained
[below](#finding-the-line-of-an-error):

    GAME = star-catcher

    build:
    	moonc --correlate *.moon

    run: build
    	love .

    watch:
    	moonc -w --correlate *.moon

    lint:
    	moonc -l *.moon

While working, run `make watch` in a terminal. `moonc -w` recompiles each file
as soon as you save it, so restarting LÖVE always runs your latest code.

The [linter](../reference/command_line.html#command-line-tools/moonc/linter)
catches typos in variable names before you run the game. LÖVE provides the
`love` global, so whitelist it in a `lint_config.moon` file and compile that
file once with `moonc lint_config.moon`:

```moononly
{
  whitelist_globals: {
    ["."]: { "love" }
  }
}
```

## Finding the line of an error

LÖVE runs the compiled Lua, so errors report line numbers in the `.lua` file.
Normally the compiled Lua has a different number of lines than the
MoonScript. If `@speed` were misspelled as `@sped` in `player.moon`, line 11,
the game would crash with:

    Error: player.lua:15: attempt to perform arithmetic on field 'sped' (a nil value)
    stack traceback:
    	player.lua:15: in function 'update'
    	main.lua:11: in function 'update'

Compiling with
[`--correlate`](../reference/command_line.html#command-line-tools/moonc)
places each line of generated Lua on the same line number as the MoonScript
it came from. The same crash then points straight at the MoonScript source:

    Error: player.lua:11: attempt to perform arithmetic on field 'sped' (a nil value)
    stack traceback:
    	player.lua:11: in function 'update'
    	main.lua:13: in function 'update'

Line 11 of `player.moon` has the typo, and line 13 of `main.moon` is the
`player\update dt` call. The cost is that correlated Lua is harder to read,
since several statements can share a line.

Without `--correlate`, pass `-X` to have the compiler print the map from Lua
lines to MoonScript lines:

```bash
$ moonc -X player.moon
```

The output includes the Lua line from the error and the MoonScript line it
came from:

    15:[ self.x = self.x + (dx * self.sped * dt) ] >> 11:[ @x += dx * @sped * dt ]

## Compiling ahead vs. loading MoonScript at runtime

We recommend compiling your MoonScript to Lua ahead of time and shipping the
`.lua` files, as this guide does. The game starts without first compiling its
code, and it doesn't need the MoonScript compiler to run.

It is also possible to bundle the MoonScript compiler with your game and
`require "moonscript"` so that `.moon` files are compiled when they are loaded.
This lets an error handler rewrite tracebacks to MoonScript line numbers, but
it has costs:

* Every file is compiled each time the game starts, which delays startup.
* The compiler uses C modules that LÖVE doesn't include: its parser, and
  [LPeg](https://www.inf.puc-rio.br/~roberto/lpeg/). A pure Lua version of the
  parser is available as `moonscript.parse.slow`, but LPeg is still required,
  so you have to ship a compiled LPeg for every platform or use a pure Lua port
  of it.
* The MoonScript loader reads files with Lua's `io` library, which can't see
  inside a zipped `.love` file. Released games need to be compiled ahead of
  time anyway.

If you want runtime loading while developing, the [LÖVE MoonScript
template](https://transmutrix.itch.io/love-moonscript-template) by transmutrix
is a ready-made setup, with LPeg binaries and an error handler that rewrites
tracebacks to MoonScript line numbers.

## Packaging a `.love` file

A `.love` file is a zip of your game directory with `main.lua` at the top
level. It needs the compiled Lua and your assets. LÖVE only loads the `.lua`
files, so any `.moon` files in the archive are ignored. You can include them
so that players who open up your game can read the MoonScript source. This
target leaves them out; add `*.moon` to the `zip` command to include them:

    $(GAME).love: build
    	rm -f $@
    	zip -9 -r $@ *.lua images sounds -x lint_config.lua

Run `make star-catcher.love`, then test the result with `love
star-catcher.love` before publishing it.

To publish on [itch.io](https://itch.io), upload the `.love` file to your
project page, or push it with [butler](https://itch.io/docs/butler/), itch.io's
command line upload tool:

    deploy: $(GAME).love
    	butler push $(GAME).love your-name/star-catcher:love

The itch.io page for a `.love` upload should tell players to install
[LÖVE](https://love2d.org) to run it. To make standalone Windows and macOS
builds, follow the [Game Distribution](https://love2d.org/wiki/Game_Distribution)
guide on the LÖVE wiki. It works the same way for a game written in MoonScript,
because the `.love` file contains only Lua.

## Games made with MoonScript

These games were written in MoonScript and run on LÖVE:

* [Rock Declutterer](https://leafo.itch.io/rock-declutterer) by leafo, the
  creator of MoonScript, is a bubble shooter style puzzle game where you fire
  rocks to clear the board. It runs in the browser and on Android.
* [X-Moon](https://leafo.itch.io/x-moon) by leafo is an action game where you
  pilot a tank to collect energy for a planet-destroying superweapon. It was
  made in 48 hours for Ludum Dare 25.
* [Wallrun Dot Love](https://leafo.itch.io/wallrun-dot-love) by leafo is a
  minimalist platformer with wall running, ledge grabbing, and dagger combat,
  made for Ludum Dare 30.
* [Linovictus](https://transmutrix.itch.io/linovictus) by transmutrix is a
  twin-stick arcade shooter made for LÖVE Jam 2026. All of the game's own code
  is written in MoonScript.

## See also

* [How to Call Methods](calling-methods.html)
* [Classes and object oriented programming](../reference/#the-language/object-oriented-programming)
* [Comprehensions](../reference/#the-language/comprehensions) and [the `for` loop](../reference/#the-language/for-loop)
* [`moonc` command line options](../reference/command_line.html#command-line-tools/moonc)
* [LÖVE wiki](https://love2d.org/wiki/Main_Page)
