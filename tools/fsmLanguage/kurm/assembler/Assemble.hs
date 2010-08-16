module Assemble where
    import Ast
    import Util
    import Char
    import Data.Bits
    import Control.Monad.Error
    import Control.Monad.Writer

    assemble :: Compile ()
    assemble = do ast <- getAst
                  mapM asm_ ast
                  abortErr
        where asm_ (p,i,(Add s t d))    = out i $ "0"++(hx s)++(hx t)++(hx d)
              asm_ (p,i,(Sub s t d))    = out i $ "1"++(hx s)++(hx t)++(hx d)
              asm_ (p,i,(And s t d))    = out i $ "2"++(hx s)++(hx t)++(hx d)
              asm_ (p,i,(Or s t d))     = out i $ "3"++(hx s)++(hx t)++(hx d)
              asm_ (p,i,(Addc s t d))   = out i $ "8"++(hx s)++(hx t)++(hx d)
              asm_ (p,i,(Subc s t d))   = out i $ "9"++(hx s)++(hx t)++(hx d)
              asm_ (p,i,(Andc s t d))   = out i $ "A"++(hx s)++(hx t)++(hx d)
              asm_ (p,i,(Orc s t d))    = out i $ "B"++(hx s)++(hx t)++(hx d)
              asm_ (p,i,(Set s t m))    = out i $ "6"++(hx s)++(hx t)++(hx m)
              asm_ (p,i,(Ascii s))      = str i s
              asm_ (p,i,(Jump (Val o)))  = out i $ "7"++(hex 3 (o `div` 8))
              asm_ (p,i,(Jumpc (Val o))) = out i $ "F"++(hex 3 (o `div` 8))
              asm_ (p,i,(Branch m (Val o)))   = out i $ "E"++(hx m)++(hex 2 (o `div` 2))
              asm_ (p,i,(Load s t (Val o)))   = out i $ "4"++(hx s)++(hx t)++(hx (o `div` 2))
              asm_ (p,i,(Store s t (Val o)))  = out i $ "5"++(hx s)++(hx t)++(hx (o `div` 2))
              asm_ (p,i,(Loadc s t (Val o)))  = out i $ "C"++(hx s)++(hx t)++(hx (o `div` 2))
              asm_ (p,i,(Storec s t (Val o))) = out i $ "D"++(hx s)++(hx t)++(hx (o `div` 2))
              asm_ (p,i,(Data (Val r) (Val v))) = rpt r i (hex 4 v)
              asm_ (p,i,x)           = pushErr $ "Unknown Instruction: " ++ (show x)
              hx v                   = hex 1 v
              str p []               = do return ()
              str p (a:[])           = do out p $ (hex_ 2 (ord a))++(hex_ 2 0)
                                          return ()
              str p (a:(b:c))        = do out p $ (hex_ 2 (ord a))++(hex_ 2 (ord b))
                                          str (p+2) c
                                          return ()
              rpt 0 p s              = do return ()
              rpt r p s              = do out p s
                                          rpt (r-1) (p+2) s
              out i s                = do tell [(hex 4 i,s)]
                                          --liftIO $ putStr (hex 4 i)
                                          --liftIO $ putStr " "
                                          --liftIO $ putStrLn s
                                          return ()

    assemble2 :: Compile ()
    assemble2 = do ast <- getAst
                   foldM asm_ ((-2) :: Integer) ast
                   abortErr
        where asm_ b (p,i,(Add s t d))    = out b i $ "0000"++(bt s)++(bt t)++(bt d)
              asm_ b (p,i,(Sub s t d))    = out b i $ "0001"++(bt s)++(bt t)++(bt d)
              asm_ b (p,i,(And s t d))    = out b i $ "0010"++(bt s)++(bt t)++(bt d)
              asm_ b (p,i,(Or s t d))     = out b i $ "0011"++(bt s)++(bt t)++(bt d)
              asm_ b (p,i,(Addc s t d))   = out b i $ "1000"++(bt s)++(bt t)++(bt d)
              asm_ b (p,i,(Subc s t d))   = out b i $ "1001"++(bt s)++(bt t)++(bt d)
              asm_ b (p,i,(Andc s t d))   = out b i $ "1010"++(bt s)++(bt t)++(bt d)
              asm_ b (p,i,(Orc s t d))    = out b i  $ "1011"++(bt s)++(bt t)++(bt d)
              asm_ b (p,i,(Set s t m))    = out b i $ "0110"++(bt s)++(bt t)++(bt m)
              asm_ b (p,i,(Ascii s))      = str b i s
              asm_ b (p,i,(Jump (Val o)))  = out b i $ "0111"++(bz 12 (o `div` 8))
              asm_ b (p,i,(Jumpc (Val o))) = out b i $ "1111"++(bz 12 (o `div` 8))
              asm_ b (p,i,(Branch m (Val o)))   = out b i $ "1110"++(bt m)++(bz 8 (o `div` 2))
              asm_ b (p,i,(Load s t (Val o)))   = out b i $ "0100"++(bt s)++(bt t)++(bt (o `div` 2))
              asm_ b (p,i,(Store s t (Val o)))  = out b i $ "0101"++(bt s)++(bt t)++(bt (o `div` 2))
              asm_ b (p,i,(Loadc s t (Val o)))  = out b i $ "1100"++(bt s)++(bt t)++(bt (o `div` 2))
              asm_ b (p,i,(Storec s t (Val o))) = out b i $ "1101"++(bt s)++(bt t)++(bt (o `div` 2))
              asm_ b (p,i,(Data (Val r) (Val v))) = rpt b r i (bz 16 v)
              asm_ b (p,i,x)           = do pushErr $ "Unknown Instruction: " ++ (show x)
                                            return i
              bt n                   = bz 4 n
              str i p []             = do return p
              str i p (a:[])         = do out i p $ (bz_ 8 (ord a))++(bz_ 8 0)
                                          return p
              str i p (a:(b:c))      = do out i p $ (bz_ 8 (ord a))++(bz_ 8 (ord b))
                                          str (i+2) (p+2) c
                                          return p
              rpt b 0 p s            = do return (p-2)
              rpt b r p s            = do out b p s
                                          rpt (b+2) (r-1) (p+2) s
              out b i s              = do val <- rpt b ((i-b-2) `div` 2) (b+2) "0000000000000000"
                                          tell [(hex 4 i,s)]
                                          --liftIO $ putStr (hex 4 i)
                                          --liftIO $ putStr " "
                                          --liftIO $ putStrLn s
                                          return i
