% Cargo Culting Lenses for Fun & Profit
% QFPL @ Data61, CSIRO
% sean.chalmers@data61.csiro.au

### Lenses are functions

- Easy to lose sight of, but important to remember!
- Lenses are still only functions, which is why we can compose them!

### Housekeeping

- I'll be using Haskell ``lens``
- Scala has lenses too!
- I don't claim to be an expert!

### Getter & Setter

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

-- What units of speed? Cabbages?!
let foo = Foo "Fred" 35
```

### Getter
```haskell
_petCamelName foo == "Fred" ==  foo ^. petCamelName
```
Yay?

### [Inception Movie Pun]
Reach deeper into ``Bar`` to retrieve the pet name:
```haskell
data Bar = Bar { _camelPerson :: Foo }

"Sally" = bar ^. camelPerson . petCamelName
```
Works for setting a value too:
```haskell
bar & camelPerson . petCamelName .~ "Sally"
```

### Lenses are functions!
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
petCamelName .~ "Sally"
```
Using reverse apply ``(&)``:
```haskell
foo & petCamelName .~ "Sally"
```

### Multiple Updates ?
```haskell
f :: Foo -> Foo
f = petCamelName .~ "Sally" & petCamelTopSpeed .~ 48
```
Applied directly:
```haskell
foo & petCamelName .~ "Sally"
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

### ``traverse``, it's always traverse
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
    -- What do you think this would do?
    a ^. tBars . camelPerson . petCamelName
    ```

### Traversal
This is called a ``Traversal``.
```haskell
tBars :: Traversal' A Bar
tBars = bars . traverse
```
Which we can extend and reuse!
```haskell
topSpeeds :: Traversal' A Int
topSpeeds = tBars . camelPerson . petCamelTopSpeed
```
Exercise: Write the same function without using lenses.
```haskell
topSpeeds :: Applicative f => (Int -> f Int) -> A -> f A
```

### Fold
Combining a Getter with a Traversal will yield a Fold.
```haskell
-- We saw a Fold earlier : (^..)
a ^.. tBars . camelPerson . petCamelName
```
```haskell
-- Only want the first camel person?
a ^? bars . _head
```
```haskell
-- Calculate maximum cabbage units?
maximumOf (tBars . camelPerson . petCamelTopSpeed) a
```

### Lens Family Tree
```
  Fold   Setter
   / \_____/
   \       \
Getter  Traversal
   /  ____/
   \ /    \
  Lens   Prism
     \   /
      Iso
```

### Lets get wild.
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

### Build Giant Updates
```haskell
\n ds -> 
  ds & dataSet_max %~ max n
     & dataSet_min %~ min n
     & dataSet_lines . traverse %~
     ( ( line_end . _Point . _1 +~ stepToTheRight )
     . ( line_start . _Point . _1 +~ stepToTheRight )
     )
     & dataSet_lines %~ (\xs -> addNewDataPoint n xs $ uncons xs)
```