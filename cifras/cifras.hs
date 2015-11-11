-- Based on a simple math game: given a list of numbers use the four basic 
-- operations (+, -, /, *)  between them to find (or be as close as possible to) 
-- another given number.

-- This is my first Haskell script.
-- Arnau Sanchez <pyarnau@gmail.com>

import Data.List
--import Text.Printf(printf)

type Value = Int

data BinaryOp = Add | Substract | Multiply | Divide
  deriving (Eq)
  
data ExtNum = Num { value :: Value } | 
              BinManip { value :: Value, num1 :: ExtNum, num2 :: ExtNum, op :: BinaryOp }
  deriving (Eq)

instance Show BinaryOp where
  show Add = "+"
  show Substract = "-"
  show Multiply = "*"
  show Divide = "/"
  
instance Show ExtNum where
  show (Num value) = show value
  show (BinManip value num1 num2 op) = "(" ++ show num1 ++ show op ++ show num2 ++ ")"

show2 x = (value x, show x)                                       
 
combinations :: Value -> [a] -> [[a]]
combinations 0 _  = [[]]
combinations n xs = [y:ys | y:xs' <- tails xs, ys <- combinations (n-1) xs']

combine2Nums :: ExtNum -> ExtNum -> [ExtNum]
combine2Nums n1 n2 = removeRepeated n1 n2 $ concat buildOps 
  where buildOps = [buildBin n1 n2 Add (+) True,
                    buildBin n1 n2 Substract (-) (value n1 > value n2),
                    buildBin n2 n1 Substract (-) (value n2 > value n1),
                    buildBin n1 n2 Multiply (*) True,
                    buildBin n1 n2 Divide div (value n1 `mod` value n2 == 0),
                    buildBin n2 n1 Divide div (value n2 `mod` value n1 == 0)]                  
        buildBin n1' n2' op f guard = 
          if guard then [BinManip ((value n1') `f` (value n2')) n1' n2' op] else []
        removeRepeated n1' n2' = filter (not . (`elem` [value n1', value n2']) . value)
                                      
getPairs :: (Eq a) => Value -> [a] -> [([a], [a])]
getPairs n xs = [(c, [x | x <- xs, not (x `elem` c)]) | c <- combinations n xs]

cifras :: [Value] -> [ExtNum]
cifras xs = concat (xs' : cifras2 [xs'])
  where xs' = [Num x | x <- xs]
    
cifras2 :: [[ExtNum]] -> [[ExtNum]]
cifras2 [] = [[]]
cifras2 xss = concat $ map fst pairs : (map cifras2 $ map joinPair pairs)
  where pairs = [(combine2Nums (xs !! 0) (xs !! 1), ys) | 
                 (xs, ys) <- concatMap (getPairs 2) xss]
        joinPair (xs, ys) = [x : ys | x <- xs]
                  
                 
main = do                  
  (putStrLn . show) $ length $ map show2 $ 
    filter ((== 765) . value) $ cifras [1, 3, 7, 10, 25, 50]
