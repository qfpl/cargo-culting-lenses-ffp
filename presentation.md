% Cargo Culting Lenses for Fun & Profit
% QFPL @ Data61, CSIRO
% sean.chalmers@data61.csiro.au

### The Point

> - To _really_ use lenses, you _will_ need to learn the theory.
> - However, you don't _need_ to learn the theory to _start_ using lenses.
> - I hope to give you that start on the rote application of lenses.
> - I am no expert

### Sacks of Lenses

* I'll be using Haskell ``lens`` package.
* OCaml has lenses, ``ocaml-optics``, ``ocaml-lens``.
* Scala too, ``monocle``.

### Lens ~ Getter & Setter

```haskell
-- Getter
(^.) :: s -> Getting a s a -> a
-- Setter
(.~) :: ASetter s t a b -> b -> s -> t
```

Talk over, right?

### Simplest Simples

```haskell
data Foo = Foo
  { _petCamelName     :: Text
  , _petCamelTopSpeed :: Int
  }
-- Template Haskell to write the lenses for us
makeLenses ''Foo
```

### Getter

```haskell
_petCamelName foo = "Fred" = foo ^. petCamelName
```

Yay?

### [Inception Movie Pun]

Reaching deeper into a data structure:

```haskell
data Bar = Bar { _camelPerson :: Foo }

"Sally" = bar ^. camelPerson . petCamelName
--
"Sally" = _petCamelName . _camelPerson $ bar
```

### Lenses are functions

Lenses compose to make new lenses:

```haskell
camelPerson :: Lens' Bar Foo
petCamelName :: Lens' Foo Text
```

Compose these with (``.``)

```haskell
camelPerson . petCamelName :: Lens' Bar Text
```

### Setter

Simple replacement using ``(.~)``

```haskell
(petCamelName .~) :: Text -> Foo -> Foo
--
a & petCamelName .~ "Sally" = a { _petCamelName = "Sally" }
```

Using reverse apply ``(&)``:

```haskell
foo & petCamelName .~ "Sally"
```

### What about updating?

What about updating a thing in a thing in a thing?

```haskell
nestedUpdate a =
  let
    nn = _petCamelName . _camelPerson $ a
  in
    a { _camelPerson =
        _camelPerson a {
          _petCamelName = nn <> " the Wise"
        }
      }
```

### Another time, another place

```java
Helper.returnNullOrCallFunction(
        Helper.returnNullOrCallFunction(
                myObject.getSomeOtherObject(),
                SomeOtherObject::getAnotherObject
        ),
        AnotherObject::increaseTheThing
);
```

<small>Taken from: https://stackoverflow.com/a/26414202</small>

### But using lenses

```haskell
nestedUpdate =
  -- Using `set with function`
  camelPerson . petCamelName %~ (<> " the Wise")
  -- Using a mappend setter
  camelPerson . petCamelname <>~ " the Wise"
```

### Multiple Updates

```haskell
foo & petCamelName .~ "Sally"
    & petCamelTopSpeed .~ 48
--
camelPerson %~ \f -> f
  & petCamelName .~ "Sally" 
  & petCamelTopSpeed .~ 48
```

### Update with a function

Apply a function to your lens target

```haskell
petCamelTopSpeed %~ (+10)
```

There are heaps of prebaked operators:

```haskell
petCamelTopSpeed +~ 10           -- Add 10 cabbages
petCamelTopSpeed //~ 2           -- Divide by 2 cabbages
petCamelName     <>~ " the Wise" -- Reward victory with a title
```

### Getting interesting

Geddit? eh? eh? ...fine.

```haskell
data A = A { _bars :: [Bar] }
```

> - Get the names of all the camels
> - Update speed values
> - What function could possibly achieve such a thing?

### ``traverse`` <3

> - ```haskell
    tBars = bars . traverse
    ```
> - ```haskell
    -- (^..) is an alias of 'toListOf'
    a ^.. tBars . camelPerson . petCamelName
    ```
> - ```haskell
    -- Works with setters too, of course
    tBars . camelPerson . petCamelTopSpeed +~ 10
    ```
> - ```haskell
    -- Can we do this? What is the answer?
    a ^. tBars . camelPerson . petCamelName
    ```

### Traversal

```haskell
tBars :: Traversal' A Bar
tBars = bars . traverse
```

Which we can extend and reuse!

```haskell
topSpeeds :: Traversal' A Int
topSpeeds = tBars . camelPerson . petCamelTopSpeed
```

Exercise: Write the same function without lens

```haskell
topSpeeds :: Applicative f => (Int -> f Int) -> A -> f A
```

### Fold

Composing a Getter with a Traversal will yield a Fold.

```haskell
-- We saw a Fold earlier : (^..)
a ^.. tBars . camelPerson . petCamelName
```

```haskell
-- Only want the first camel person?
a ^? bars . _head :: Maybe Bar
```

### Lens Family Tree

```text
  Fold   Setter
  /  \_____/
  \ /      \
Getter  Traversal
   /  ____/
   \ /    \
  Lens   Prism
     \   /
      Iso
```

### Lets get wild

Update a value in a StateT?

```haskell
-- Assuming : StateT Foo m
petCamelName     .= "Bub"         -- Replace
petCamelTopSpeed %= (-10)         -- Map
petCamelName     <>= " the Swift" -- Mappend
```

> - What if it's in a thing in the thing in StateT?
> - ```haskell
    -- Assuming : StateT Bar m
    camelPerson . petCamelTopSpeed %= (-10)
    ```

### Giant Updates

Update several different fields on a record.

```haskell
\n ds ->
  ds & dataSet_max %~ max n
     & dataSet_min %~ min n
     & dataSet_lines . traverse %~
     ( ( line_end . _Point . _1 +~ stepToTheRight )
     . ( line_start . _Point . _1 +~ stepToTheRight )
     )
     & dataSet_lines %~ (\xs -> addNewDataPoint n xs (uncons xs))
```

### The Heck was ``_Point`` / ``_1``

That was a ``Prism``.

> - Prisms are Traversals that may become Getters.
> - One way to think of Prisms is as a Lens that is partial in one direction, with laws.
> - ```haskell
    Right 'c' ^? _Left == Nothing
    Left 'c' ^? _Left == Just 'c'
    ```
> - ```haskell
    5 ^. re _Left == Left 5
    ```
> - ```haskell
    ( ( Left 5 ) & _Left .~ 6 ) == Left 6
    ```

### Handling Failure

Consider the following JSON:

```json
{ "alpha":
  { "beta":
    [.., { "gamma": [.., {"delta": <some bool> }, ...] }, ..]
  }
}
```

* Assuming ``gamma`` is at index 3, and ``delta`` is at index 2.
> Your mission is to flip the value at ``delta``.

### First Hack

```js
a = getAtKey blob "alpha"
if ( null != a ) {
  b = getAtKey a "beta" {
    if ( null != b && isArray b ) {
      c = getAtIndex b 3
      if ( null != c ) {
        fooList = getAtKey "gamma"
        if ( null != fooList && isArray fooList ) {
          fooObj = getAtIndex c 2
          if ( null != fooObj ) {
            fooVal = getBoolValAtKey "delta" fooObj
            if ( null != fooVal ) {
              newFoo = setValueAtKey "delta" (not fooVal)
              return ( setValueAtKey "beta" a
                ( setValueAtIndex 3 b
                  ( setValueAtKey  "gamma" c
                    ( setValueAtIndex 2 fooList newFoo )
                  )
                )
              )
            }
          }
        }
      }
    }
  }
}
```

<small>This pseudo-code is an exaggeration, but not by much and you know it.</small>

### Yay

Using ``lens-aeson`` and ``lens``.

```haskell
( key "alpha"
. key "beta" . _Array . ix 3
. key "gamma" . _Array . ix 2
. key "delta" . _Bool %~ not
) :: AsValue t => t -> t
```

<small>*ahem*</small>

### Prisms

The ``_Array`` and ``_Bool`` things are both a ``Prism``.

```haskell
"[1,2,3]" ^? _Array
--
[1,2,3] ^. re _Array
```

### Prisms are Traversals

```haskell
Just 3 ^? _Just = Just 3
Nothing ^? _Just = Nothing
```

```haskell
('a', Just 3) & _2 . _Just %~ (+1) = ('a', Just 4)
```

### Lens Operator Grammar

Lens operators are formed from a symbol DSL.

* ``^`` - refers to a fold
* ``~`` - modification or setting
* ``?`` - results optional
* ``<`` - return the new value
* ``<<`` - return the old value
* ``%`` - use a given function
* ``%%`` - use a given traversal
* ``=`` - apply lens to ``MonadState``
* ``.`` - which side should have the lenses

### Modifying a Map

```haskell
let
  m = Map.fromList [(1, "susan"), (2, "jo")]
in
  m & at 1 .~ "bob"
    & at 3 ?~ "pixie"
    & at 2 %~ _f :: ??
```

### Oh my

Modifying a map in your StateT, setting a new value if one exists, but
creating a new key-value pair if it doesn't exist, and returning the previous
value if there was one?

```haskell
data A = A
  { _theFoo :: Foo
  , _theMap :: Map String Int
  }
```

> - ```haskell
    a <- theMap . at "foo" <<?= 37
    ```

### The 'Of' family

Use a lens to target a part of a structure.

* traverseOf, itraverseOf
* maximumOf, minimumOf
* foldMapOf, mapMOf

### How I learned

* Haddock diving
* Playing in the REPL
* "Lets Lens" introductory course

### Trying it yourself

REPL REPL REPL REPL REPL REPL REPL REPL REPL REPL
REPL REPL REPL REPL REPL REPL REPL REPL REPL REPL
REPL REPL REPL REPL REPL REPL REPL REPL REPL REPL
REPL REPL REPL REPL REPL REPL REPL REPL REPL REPL
REPL REPL REPL REPL REPL REPL REPL REPL REPL REPL
REPL REPL REPL REPL REPL REPL REPL REPL REPL REPL

### Thanks for suffering through

Questions ?

Lets Lens! - https://github.com/data61/lets-lens