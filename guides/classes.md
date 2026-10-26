{
  title: "How Classes Work"
  description: "How to write classes in MoonScript: constructors, methods, instance fields vs shared properties, class variables, inheritance with extends and super, metamethods, and the mistakes that cause errors like attempt to index a nil value (global 'self')."
}

A class in MoonScript is declared with `class`. The `new` property is the
constructor, methods are written with the fat arrow `=>`, and `@` refers to the
instance. Calling the class like a function creates an instance. Classes
compile to plain Lua tables and metatables, so they work anywhere Lua does and
can be used from Lua code.

```moononly
class Counter
  new: (start=0) =>
    @count = start

  increment: (amount=1) =>
    @count += amount
    @count

counter = Counter 10
counter\increment!
print counter\increment 5 -- prints 16
```

## Quick reference

<table class="quick_ref">
  <thead><tr><th>MoonScript</th><th>Meaning</th></tr></thead>
  <tbody>
    <tr><td><code>class Name</code></td><td>Declare a class, stored in a local named <code>Name</code></td></tr>
    <tr><td><code>new: (a, b) =&gt;</code></td><td>The constructor</td></tr>
    <tr><td><code>new: (@name) =&gt;</code></td><td>Assign an argument directly to <code>self.name</code></td></tr>
    <tr><td><code>method: =&gt;</code></td><td>A method; <code>@</code> is the instance</td></tr>
    <tr><td><code>Name!</code>, <code>Name a, b</code></td><td>Create an instance</td></tr>
    <tr><td><code>obj&#92;method!</code></td><td>Call a method</td></tr>
    <tr><td><code>@count: 0</code></td><td>A class variable, stored on the class object</td></tr>
    <tr><td><code>@@count</code></td><td>Read a class variable from a method (<code>self.__class.count</code>)</td></tr>
    <tr><td><code>class B extends A</code></td><td>Inherit from <code>A</code></td></tr>
    <tr><td><code>super ...</code></td><td>Call the parent's version of the current method</td></tr>
    <tr><td><code>obj.__class</code></td><td>The class an instance was made from</td></tr>
  </tbody>
</table>

## What a class compiles to

A class is made of two tables. The *base* holds the methods and properties
listed in the class body, and is the metatable of every instance. The *class
object* holds the constructor, and calling it creates a new instance:

```moon
class Point
  new: (@x, @y) =>
  length: => math.sqrt @x^2 + @y^2

p = Point 3, 4
print p\length!
```

`new` becomes `__init` on the class object. Everything else in the body goes
in `_base_0`, which is stored on the class as `__base`. An instance is an
empty table with `_base_0` as its metatable, so looking up `p.length` finds
the method in the base.

The class is assigned to a local variable with the class's name. If the class
is the last statement in a file, the file returns it, which is how a module
usually exports a class.

## Put instance fields in `new`

Every property in the class body is stored in the base, which all instances
share. That is what you want for methods. For tables it means every instance
reads and modifies the same table:

```moononly
class Player
  items: {}
  add: (item) => table.insert @items, item

a = Player!
b = Player!
a\add "sword"
print #b.items, b.items[1] -- prints 1, sword
```

`b` never added anything, but it sees the sword because `@items` refers to
the one table in the base. Create each instance's own state in the
constructor:

```moononly
class Player
  new: =>
    @items = {}

  add: (item) => table.insert @items, item
```

Numbers, strings, and booleans in the class body are safe to use as defaults.
Assigning `@health -= 10` creates a field on the instance and leaves the base
alone. Only values that are modified in place, like tables, are a problem.

## Class variables and private values

A property prefixed with `@` in the class body is stored on the class object
instead of the base. Methods reach the class object with `@@`, which compiles
to `self.__class`:

```moononly
class Enemy
  @count: 0

  @spawn: (x, y) =>
    @ x, y

  new: (@x, @y) =>
    @@count += 1

e = Enemy\spawn 3, 4
print Enemy.count -- prints 1
print e.count     -- prints nil
```

`@spawn` is a class method: inside it, `@` is the class, and `@ x, y` creates
an instance. Instances don't see class variables directly, so `e.count` is
`nil`.

An assignment in the class body creates a local variable that only the class's
methods can see. Use it for private constants and helper functions:

```moononly
class Mover
  speed = 4
  clamp = (n) -> math.max 0, n

  new: (@x) =>
  move: (dx) =>
    @x = clamp @x + dx * speed
```

## Inheritance with `extends` and `super`

`extends` makes a class inherit the parent's methods and properties. A
subclass without its own `new` uses the parent's constructor:

```moononly
class Entity
  new: (@x, @y) =>
  describe: => "at #{@x}, #{@y}"

class Ghost extends Entity

print Ghost(1, 2)\describe! -- prints at 1, 2
```

Inside a method, calling `super` calls the parent's method of the same name,
passing `self` automatically. A subclass that defines `new` must call `super`
itself, because the parent's constructor no longer runs on its own:

```moononly
class Player extends Entity
  new: (@name, x, y) =>
    super x, y

  describe: =>
    "#{@name} " .. super!

p = Player "leafo", 3, 4
print p\describe! -- prints leafo at 3, 4
```

Forgetting `super` in the constructor leaves the parent's fields unset. The
error shows up later, wherever the missing field is used:

```moononly
class Entity
  new: (@x, @y) =>

class Player extends Entity
  new: (@name) =>

p = Player "leafo"
print p.x + 1
```

    lua5.4: player.lua:62: attempt to perform arithmetic on a nil value (field 'x')

On Lua 5.1 and LuaJIT:

    luajit: player.lua:62: attempt to perform arithmetic on field 'x' (a nil value)

A common pattern is to take the parent's result and add to it:

```moononly
class Entity
  tags: => { "entity" }

class Player extends Entity
  tags: =>
    tags = super!
    table.insert tags, "player"
    tags
```

`super` works the same way in class methods. Here `@` is `Player`, so the
parent's `@create` builds a `Player`:

```moononly
class Entity
  new: (@x, @y) =>
  @create: (x, y) => @ x, y

class Player extends Entity
  @create: (name) =>
    player = super 0, 0
    player.name = name
    player
```

Used without calling it, `super` is a value referring to the parent class.
`super.method` gets the parent's version of a method as a plain function.

### Reacting to subclasses with `__inherited`

If a class defines the class method `@__inherited`, it's called each time
another class extends it, with the parent as `@` and the new class as the
argument:

```moononly
class Plugin
  @__inherited: (child) =>
    print "#{child.__name} extends #{@__name}"

class Markdown extends Plugin -- prints Markdown extends Plugin
```

`__inherited` is itself inherited, so it also runs when a subclass is
extended. Its main use is copying metamethods, shown
[below](#metamethods/metamethods-arent-inherited).

## Sharing methods between classes

A class can only extend one parent. To share methods between unrelated
classes, write them in a class of their own and copy its methods into each
class's base:

```moononly
class Serializable
  serialize: =>
    parts = for k, v in pairs @
      "#{k}=#{v}"
    table.sort parts
    table.concat parts, "&"

include = (cls, mixin) ->
  for name, fn in pairs mixin.__base
    if not name\match("^__") and rawget(cls.__base, name) == nil
      cls.__base[name] = fn

class Player
  new: (@name, @score) =>
  include @, Serializable

print Player("leafo", 10)\serialize! -- prints name=leafo&score=10
```

`include @, Serializable` runs in the class body, where `@` is the class
being declared. Skipping names that start with `__` leaves `__index`,
`__class`, and the target's own metamethods alone.

A copied method keeps the `super` it was compiled with. If the mixin class
extends another class, `super` inside its methods calls that class, not the
parent of the class it was copied into.

[Lapis](https://leafo.net/lapis/) provides `@include` for widgets and
applications, which mixes in another class's methods the same way.

## Inspecting classes and instances

Every class and instance carries a few fields that describe it:

* `obj.__class` is the class an instance was created from.
* `Name.__name` is the class's name as a string.
* `Name.__base` is the base table. Adding a function to it adds a method to
  every instance, including ones that already exist.
* `Name.__parent` is the parent class, if the class extends one.

To check what an instance is, compare its `__class`, or use `switch` to
branch on it:

```moononly
if p.__class == Player
  print "a player"

switch p.__class
  when Player
    print "a player"
  when Entity
    print "some other entity"

print "unknown object: #{p.__class.__name}"
```

These checks match the exact class only. A `Player` instance isn't
`== Entity`, even though `Player` extends `Entity`.

Because methods live in `__base`, tests can replace a method for every
instance at once. With [busted](https://lunarmodules.github.io/busted/),
`stub User.__base, "save"` stubs the method, and reverting the stub restores
it.

The `moon` module that comes with MoonScript has functions for checking
types, including ones that follow the inheritance chain:

```moononly
import is_class, is_instance, is_instance_of from require "moon"
moon = require "moon"

class Entity
class Player extends Entity

p = Player!
print is_class(Player), is_instance(p)  -- prints true, true
print is_instance_of p, Entity          -- prints true
print moon.type(p) == Player            -- prints true
```

`moon.type` works like Lua's `type`, but returns the class for an instance
and `"class"` for a class object.

### Checking types with tableshape

[tableshape](https://github.com/leafo/tableshape) is a separate library for
validating values, installed with `luarocks install tableshape`. Its
`tableshape.moonscript` module has type checkers for classes. Each one is a
function that returns `true`, or `nil` and an error message:

```moononly
import instance_of, subclass_of from require "tableshape.moonscript"

class Entity
class Player extends Entity
class Item

is_entity = instance_of Entity
print is_entity Player! -- prints true
print is_entity Item!   -- prints nil, table is not instance of Entity

print instance_of("Entity") Player! -- prints true
print subclass_of(Entity) Player    -- prints true
```

* `instance_of(cls)` matches instances of `cls` or any of its subclasses.
* `subclass_of(cls)` matches classes that extend `cls`, but not `cls` itself
  unless you pass `allow_same: true` as the second argument.
* Both accept a class name as a string instead of the class object, which
  avoids requiring a module just to check against its class.
* `class_type` and `instance_type` match any class or any instance.

The checkers combine with the rest of tableshape, so you can validate a
table of options that contains objects, such as a constructor's argument:

```moononly
import types from require "tableshape"
import instance_of from require "tableshape.moonscript"

class Player
class Item

team_options = types.shape {
  leader: instance_of Player
  name: types.string
}

class Team
  new: (opts) =>
    assert team_options opts
    @leader = opts.leader
    @name = opts.name

Team leader: Item!, name: "red"
```

The error names the field that failed:

    lua5.4: team.lua:56: field "leader": table is not instance of Player

## Metamethods

Properties with metamethod names like `__tostring`, `__eq`, `__add`, `__lt`,
and `__call` go in the base, which is the instances' metatable, so they work
as operators on instances:

```moononly
class Vec
  new: (@x, @y) =>
  __tostring: => "(#{@x}, #{@y})"
  __eq: (other) => @x == other.x and @y == other.y
  __add: (other) => Vec @x + other.x, @y + other.y

print tostring Vec(1, 2) + Vec(3, 4) -- prints (4, 6)
print Vec(1, 2) == Vec(1, 2)         -- prints true
```

### Metamethods aren't inherited

A subclass of `Vec` prints as `table: 0x...`, not `(1, 2)`. Lua looks up
metamethods directly in an object's metatable without following `__index`,
and the subclass's base doesn't contain `__tostring` itself. To pass
metamethods down, copy them into each subclass from `__inherited`:

```moononly
class Vec
  new: (@x, @y) =>
  __tostring: => "(#{@x}, #{@y})"

  @__inherited: (child) =>
    for key, value in pairs @__base
      if key\match("^__") and rawget(child.__base, key) == nil
        child.__base[key] = value

class Vec3 extends Vec
  new: (x, y, @z=0) => super x, y

print tostring Vec3 1, 2, 3 -- prints (1, 2)
```

The `rawget` check keeps anything the subclass defines itself, including its
own `__index` and `__class`.

### Custom `__index`

An `__index` property in the class body has no effect, because the class
sets the base's `__index` to the base itself so instances can find their
methods. To add a fallback for missing keys, replace it from the class body,
checking the base first:

```moononly
class Config
  defaults: { color: "red" }

  base = @__base
  @__base.__index = (key) =>
    value = base[key]
    if value == nil
      value = @defaults[key]
    value

c = Config!
print c.color -- prints red
```

## Using a class from Lua

A compiled class is a table that Lua code calls to create instances, and
methods are called with `:` as usual:

```lua
local Player = require("player")
local p = Player("leafo")
p:greet()
```

To add a method from Lua, put it in `Player.__base`. Assigning a function to
`Player` itself only makes it a class-level value, invisible to instances.

## Common mistakes

### Using `->` instead of `=>`

A function written with `->` gets no `self` argument, so any use of `@`
inside it refers to a global `self` that doesn't exist:

```moononly
class Player
  new: (name) ->
    @name = name

Player "leafo"
```

    lua5.4: player.lua:8: attempt to index a nil value (global 'self')

On Lua 5.1 and LuaJIT:

    luajit: player.lua:8: attempt to index global 'self' (a nil value)

Without `@`, the mistake is quieter. The instance arrives in the first
parameter, so `name` holds a table and every argument is off by one. Use `=>`
for `new` and every method. [How to Call Methods](calling-methods.html#using-inside-methods/-vs-)
covers the difference in more detail.

### Using `@` in a property value

Property values in the class body are evaluated once, when the class is
created, and there's no instance at that point. This fails with the same
`global 'self'` error as above:

```moononly
class Rect
  width: 10
  height: @width * 2
```

Compute values that depend on other fields in `new`, or in a method:

```moononly
class Rect
  new: (@width=10) =>
    @height = @width * 2
```

### Expecting `:name` to declare a field

In a class body, `:name` is the same shorthand as in a table literal. It means
`name: name`, and copies the value of a variable called `name` from the
surrounding scope:

```moononly
name = "outer"

class Thing
  :name

print Thing!.name -- prints outer
```

There's no syntax for declaring a field without a value. Assign fields in
`new`, or give them a default in the class body.

### Calling methods with `:` or `.`

Methods are called with <code>obj&#92;method!</code>. A Lua-style
`obj:method!` creates a table and calls a global function named `method`,
and `obj.method!`
calls the method without `self`. See
[How to Call Methods](calling-methods.html) for the error messages each one
produces.

## See also

* [Object oriented programming](../reference/#the-language/object-oriented-programming)
* [Inheritance](../reference/#the-language/object-oriented-programming/inheritance)
* [Super](../reference/#the-language/object-oriented-programming/super)
* [Class variables](../reference/#the-language/object-oriented-programming/class-variables)
* [Class declaration statements](../reference/#the-language/object-oriented-programming/class-declaration-statements)
* [Class and object functions in the `moon` module](../reference/standard_lib.html#moonscript-standard-library/classobject-functions)
* [How to Call Methods](calling-methods.html)
* [tableshape](https://github.com/leafo/tableshape)
