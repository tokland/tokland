readFileAndSize :: String -> Int -> IO (Int, String)
readFileAndSize path factor = do
  s <- readFile path
  let x = length s
  let y = sum $ [1..10000000000000000]
  return (x*factor, s)  

surfaceSquare l = do
  --let s = readFile "/etc/services"
  -- in l*l*(length s)
  l*l 
  
main = do 
  (x, s) <- readFileAndSize "/etc/hosts" 2
  print $ take 50 s
  print x
  print $ "surface: " ++ show (surfaceSquare 3)
  
data Tree a = Empty | Leaf a | Branch (Tree a) (Tree a)
  deriving (Eq, Show)
