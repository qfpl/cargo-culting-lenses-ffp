{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes        #-}
{-# LANGUAGE TemplateHaskell   #-}

module Examples where

import           Control.Lens
import           Control.Monad.State
import           Data.Map
import           Data.Text

import           Data.Semigroup      ((<>))

import           GHC.Natural

data Foo = Foo
  { _petCamelName     :: Text
  , _petCamelTopSpeed :: Int
  }
  deriving Show
makeLenses ''Foo

data Bar = Bar
  { _camelPerson :: Foo
  }
  deriving Show
makeLenses ''Bar

data A = A
  { _bars :: [Bar]
  }
  deriving Show
makeLenses ''A

nestedMultipleUpdate :: Bar -> Bar
nestedMultipleUpdate =
  camelPerson %~ \f ->
    f & petCamelName .~ "Sally"
      & petCamelTopSpeed .~ 48

nestedUpdate :: Bar -> Bar
nestedUpdate a =
  let
    nn = _petCamelName . _camelPerson $ a
  in
    a { _camelPerson =
        (_camelPerson a) {
          _petCamelName = nn <> " the Wise"
        }
      }

testA :: A
testA = A
  [ Bar (Foo "Fred" 8)
  , Bar (Foo "Sally" 9)
  , Bar (Foo "Bob" 2)
  , Bar (Foo "Shoshana" 8)
  , Bar (Foo "George" 4)
  ]

tBars :: Traversal' A Bar
tBars = bars . traverse

topSpeeds :: Traversal' A Int
topSpeeds = tBars . camelPerson . petCamelTopSpeed

slowCamels :: Int -> Traversal' A Int
slowCamels n = topSpeeds . filtered (< n)

_Nat :: Prism' Integer Natural
_Nat = prism toInteger toNatural
  where
    toNatural i = if i < 0
      then Left i
      else Right (fromInteger i)

modifyMapInStateOMG :: MonadIO m => StateT (Map Int String) m ()
modifyMapInStateOMG = do
  -- Set a value, creating an element if it doesn't exist, then return the new value
  a <- at 1 <?= "maybe"
  liftIO $ print a
  -- Set a value, creating an element if it doesn't exist, returning the old value.
  b <- at 3 <<?= "new value"
  liftIO $ print b
  -- run a function on something in state
  at 3 . _Just <>= " Fred"
