{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}
module Examples where

import           Control.Lens
import           Data.Text

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

slowCamels :: Int -> Traversal' A A
slowCamels n = topSpeeds . filtered (< n)
