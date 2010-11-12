{-# LANGUAGE FlexibleContexts #-}

module Language.Copilot.Examples.Examples where

import Data.Word
import Prelude (($))
import qualified Prelude as Prelude
import qualified Prelude as P

-- for specifying options
import Data.Map (fromList) 
import Data.Maybe (Maybe (..))
import System.Random
import Data.Int

import Language.Copilot 
-- import Language.Copilot.Variables

fib :: Streams
fib = do
  let fib = varW64 "fib"
  let t   = varB "t"
  fib .= [0,1] ++ fib + (drop 1 fib)
  t   .= even fib
    where even :: Spec Word64 -> Spec Bool
          even w' = w' `mod` 2 == 0

t1 :: Streams
t1 = 
  let x = varI32 "x"
      y = varB "y"
      z = varB "z"
  in do
    x .= [0, 1, 2] ++ x - (drop 1 x)
    y .= [True, False] ++ y ^ z
    z .= x <= drop 1 x

-- t2 :: Streams
-- t2 = do
--      a .= [True] ++ not (var a) 
--      b .= mux (var a) 2 (int8 3) 

-- t3 :: use an external variable called ext, typed Word32
t3 :: Streams
t3 = 
  let a    = varW32 "a"
      b    = varB "b"
      ext8 = extW32 "ext" 8
      ext1 = extW32 "ext" 1
  in do
      a .= [0,1] ++ a + ext8 + ext8 + ext1
      b .= [True, False] ++ 2 + a < 5 + ext1

t4 :: Streams
t4 = let
    a = varB "a"
    b = varB "b"
  in do
    a .= [True,False] ++ not a
    b .= drop 1 a

t5 :: Streams
t5 = 
  let x = varB "x"
      y = varB "y"
      w = varB "w"
      z = varB "z"
  in do
      x .= drop 3 y
      y .= [True, True] ++ not z
      z .= [False, False] ++ not z
      w .= x || y

yy :: Streams
yy = 
  let a = varW64 "a"
  in  do a .= 4  

zz :: Streams
zz = 
  let a = varW32 "a"
      b = varW32 "b"
  in do --a .= [0..4] ++ drop 4 (varW32 a) + 1
      a .= a + 1
      b .= drop 3 a

xx :: Streams
xx = 
  let a = varW32 "a"
      b = varW32 "b"
      c = varW32 "c"
      ext = extW32 "ext" 1
  in do 
      a .= ext
      b .= [3] ++ a
      c .= [0, 1, 3, 4] ++ drop 1 b

-- If the temperature rises more than 2.3 degrees within 0.2 seconds, then the
-- engine is immediately shut off.  From the paper.
engine :: Streams
engine = do
  -- external vars
  let temp     = extF "temp" 1      
  let shutoff  = extB "shutoff" 2
  -- Copilot vars
  let temps    = varF "temps"
  let overTemp = varB "overTemp"
  let trigger  = varB "trigger"

  temps    .= [0, 0, 0] ++ temp
  overTemp .= drop 2 temps > 2.3 + temps
  trigger  .= overTemp ==> shutoff

-- To compile: > let (streams, ss) = dist in interface $ compileOpts streams ss "dist"
-- s at phase 2 on port 1.  Not stable.
dist :: DistributedStreams
dist = 
  let a = varW8 "a"
  in 
    ( a .= [0,1] ++ a + 1
    ,     sendW8 a (2, 1)
      ..| emptySM
    )

-- greatest common divisor.
gcd :: Word16 -> Word16 -> Streams
gcd n0 n1 = do
  let a = varW16 "a"
  let b = varW16 "b"
  a .= alg n0 a b
  b .= alg n1 b a

  let ans = varB "ans"
  ans .= a == b
    where alg x0 x1 x2 = [x0] ++ mux (x1 > x2) (x1 - x2) x1

-- greatest common divisor of two external vars.  Compare to
-- Language.Atom.Example Try 
--
-- interpret gcd' 40 $ setE (emptySM {w16Map = 
--      fromList [("n", [9,9..]), ("m", [7,7..])]}) baseOpts 
--
-- Note we have to start streams a and b with a dummy value 0 before they can
-- sample the external variables.
gcd' :: Streams
gcd' = do 
  let n = extW16 "n" 1
  let m = extW16 "m" 1

  let a = varW16 "a"
  let b = varW16 "b"
  let init = varB "init"
  a .= alg n (sub a b) init
  b .= alg m (sub b a) init

  let ans = varB "ans"
  ans .= a == b && not init

  init .= [True] ++ false

  where sub hi lo = mux (hi > lo) (hi - lo) hi
        alg ext ex init = [0] ++ mux init ext ex

testCoercions :: Streams
testCoercions = do
  let word = varW8 "word"
  word .= [1] ++ word * (-2)
  let int = varI16 "int"
  int  .= 1 + cast word

testCoercions2 :: Streams
testCoercions2 = do
  let b = varB "b"
  b .= [True] ++ not b
  let i = varI16 "i"
  let j = varI16 "j"
  i .= cast j
  j .= 3

testCoercions3 :: Streams
testCoercions3 = do
  let x = varB "x"
  x .= [True] ++ not x
  let y = varI32 "y"
  y .= cast x + cast x

i8 :: Streams
i8 = 
  let v = varI8 "v" in v .= [0, 1] ++ v + 1 
    
trap :: Streams
trap = do
  let target = varW32 "target"
  target .= [0] ++ target + 1 

  let x = varW32 "x"
  let y = varW32 "y"
  x .= [0,0] ++ y + target
  y .= [0,0] ++ x + target

-- vicious :: Streams
-- vicious = do 
--     "varExt" .= extW32 "ext" 5 
--     "vicious" .= [0,1,2,3] ++ drop 4 (varW32 "varExt") + drop 1 (var "varExt") + var "varExt" 

-- testVicious :: Streams
-- testVicious = do
--     "counter" .= [0] ++ varW32 "counter" + 1 
--     "testVicious" .= [0,0,0,0,0,0,0,0,0,0] ++ drop 8 (varW32 "counter") 

-- -- The issue is when a variable v with a prophecy array of length n deps on
-- -- an external variable pv with a weight w, and that w > - n + 1 Here, w = 0 and
-- -- n = 2, so 0 > -1 holds.  That means that it is impossible to fill the last
-- -- case of the prophecy array, because it is not yet known what the external
-- -- variable will be worth.  It could be easily forbidden in the analyser.
-- -- However theoretically, nothing seems to prevent us form compiling it, we
-- -- would only need a way to say that in these case the middle of the prophecy
-- -- array should be updated and not the . (it would be safe because if another
-- -- variable was to dep on the  of it it would dep on the external
-- -- variable with a weight > 0, which is always forbidden).  It is probably
-- -- easier for now to just forbid it. But it could become an issue.
-- isBugged :: Streams
-- isBugged = do
--     "v" .= extW16 "ext" 5 
--     "v2" .= [0,1,3] ++ drop 1 (varW16 "v") 
    

-- -- The next two examples are currently refused, because they include a
-- -- non-negative weighted closed path. But they could be compiled.  More
-- -- generally I think that this restriction could be partially lifted to
-- -- forbiding non-negative circuits.  However, this would demand longer
-- -- prophecyArrays than we have for now.  (and probably a slightly different
-- -- algorithm) So even if we partially lift this restriction, a warning should
-- -- stay, because it breaks the current easy-to-evaluate bound on the memory
-- -- requirement of a Copilot monitor.
-- shouldBeRight :: Streams
-- shouldBeRight = do
--     "v1" .= [0] ++ varI32 "v1" + 1 
--     "v2" .= drop 2 (varI32 "v1") 

-- shouldBeRight2 :: Streams
-- shouldBeRight2 = do
--     "loop1" .= [0] ++ varI32 "loop2" + 2 
--     "loop2" .= [1] ++ varI32 "loop1" - 1 
--     "other" .= drop 3 (varI32 "loop1") 

-- testing external array references
testArr :: Streams
testArr = do 
  -- a .= [True] ++ extArrB ("ff", varW16 b) 5 && extArrB ("ff", varW16 b) 1 
  --       && extArrB ("ff", varW16 b) 2
  -- b .= [7] ++ varW16 b + 3 + extArrW16 ("gg", varW16 f) 2 
  -- b .= [0] ++ extArrW16 ("gg", varW16 b) 4 
  -- c .= [True] ++ var c
  -- d .= varB c 
  let e = varW16 "e"
  e .= [6,7,8] ++ 3 -- + extArrW16 ("gg", varW16 b) 2
--  f .= extArrW16 ("gg", varW16 e) 2 + extArrW16 ("gg", varW16 e) 2 
  let g = varB "g"
  let gg = extArrW16 "gg" e 
  g .= gg 1 == gg 2
  -- h .= [0] ++ drop 1 (varW16 g)


-- t3 :: use an external variable called ext, typed Word32
t99 :: Streams
t99 = do
  let ext = extW32 "ext"
  let a = varW32 "a"
  a .= [0,1] ++ a + ext 8 + ext 8 + ext 1

  let b = varB "b"
  b .= [True, False] ++ 2 + a < 5 + ext 1

-- test external idx before after and in the stream it references
-- test multiple defs
-- test defs in functions
-- test arrays at different indexes