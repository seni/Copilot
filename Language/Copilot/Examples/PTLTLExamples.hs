{-# LANGUAGE FlexibleContexts #-}

module Language.Copilot.Examples.PTLTLExamples where

import Prelude (($), String, repeat, replicate, IO())
import qualified Prelude as P
import Data.Map (fromList)

import Language.Copilot
import Language.Copilot.Libs.PTLTL

-- Next examples are for testing of the ptLTL library

-- test of previous
tstdatprv :: Streams
tstdatprv = do
  let a = varB "a"
  a .= [True, False] ++ a 
               
tprv :: Streams
tprv = do
  tstdatprv 
  c `ptltl` previous a

-- test of alwaysBeen
tstdatAB ::  Streams
tstdatAB = d .= [True, True, True, True, True, True, True, False] ++ varB d

tAB :: Streams
tAB = do
   tstdatAB 
   f `ptltl` alwaysBeen d

-- test of eventuallyPrev
tstdatEP ::  Streams
tstdatEP = g .= [False, False, False, False, False, True, False] ++ varB g 

tEP :: Streams
tEP = do
    tstdatEP 
    h `ptltl` eventuallyPrev g

q1, q2, z1:: Spec Bool
q1 = varB "q1"
q2 = varB "q2"
z = varB "z"

-- test of since
tstdat1Sin :: Streams
tstdat1Sin = q1 .= [False, False, False, False, True] ++ true --varB "q1"

tstdat2Sin :: Streams
tstdat2Sin = q2 .= [False, False, True, False, False, False, False ] ++ q2

                  
tSince :: Streams 
tSince = do
    tstdat1Sin 
    tstdat2Sin 
    z `ptltl` q1 `since` q2

-- with external variables
-- interface $ setE (emptySM {bMap = fromList [("e1", [True,True ..]), ("e2", [False,False ..])]}) $ interpretOpts tSinExt 20
tSinExt :: Streams 
tSinExt = do
  let e1 = extB "e1" 2
  let e2 = extB "e2" 3
  z `ptltl` e1 `since` e2

tSinExt2 :: Streams 
tSinExt2 = do
  let e1 = extB "e1" 2
  let e2 = extB "e2" 2
  let a = varB "a"
  let b = varW16 "b"
  let s = varB "s"
  let t = varB "t"
  let e = varB "e"

  a .= not e1
  b .= 3 > 2
  s `ptltl` e2 `since` b
  t `ptltl` (alwaysBeen $ not a)
  e .= e1 ==> d

-- "If the engine temperature exeeds 250 degrees, then the engine is shutoff
-- within the next 10 periods, and in the period following the shutoff, the
-- cooler is engaged and remains engaged."
engine :: Streams
engine = do
  let engineTemp = extW8 "engineTemp" 1
  let temp = varB "temp"
  temp    `ptltl` alwaysBeen (engineTemp > 250)

  let cnt = varW8 "cnt"
  cnt     .=      [0] ++ mux (temp && cnt < 10) 
                             (cnt + 1)
                             cnt

  let engineOff = extB engineOff 1
  let off = varB "off"
  off     .=      cnt >= 10 ==> engineOff

  let coolerOn = extB coolerOn 1
  let cooler = varB "cooler"
  cooler  `ptltl` coolerOn `since` extB engineOff 1

  let monitor = varB "monitor"
  monitor .=      off && cooler

engineRun :: IO ()
engineRun = 
  interpret engine 40 $ 
    setE (emptySM { bMap = fromList 
                            [ (engineOff, replicate 8 False P.++ repeat True)
                            , (coolerOn, replicate 9 False P.++ repeat True)
                            ]
                  , w8Map = fromList [(engineTemp, [99,100..])]
                  }) baseOpts

