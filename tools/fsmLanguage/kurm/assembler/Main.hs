module Main where

    import Ast
    import Util
    import System
    import Parser
    import Check
    import Output
    import Assemble
    import Control.Monad.Error
    import Control.Monad.State
    import Control.Monad.Writer
    import Elaborate
    import Data.List(intersperse)

    showErrors (Err err)  = do mapM putStrLn err
                               return ()

    compiler asm file = do parseFile file
                           expand
                           check
                           elaborate
                           verify
                           asm
                           output
                           return ()
	
    output_bram x = unlines $ snd (unzip x)
    output_siml x = unlines $ map (\(x,y) -> x++" "++y) x
    output_nops x = unlines $ val ++ rpt (2*(length val))
        where val = zipWith (++) (snd $ unzip x) nop
              nop = repeat "\n0000000000000000"
              rpt c = replicate (2^16 - c) "0000000000000000"

    compile out c f = do res <- runErrorT (runStateT (runWriterT (c f)) defState)
                         either bad good res
        where bad x  = do { showErrors x; return () }
              good ((st,x),_) = do { writeFile "output.mem" (out x);
                                   ; return () }

    main = do args <- getArgs
              case (args !! 0) of
                "-s" -> compile output_siml (compiler assemble) (args !! 1)
                "-b" -> compile output_nops (compiler assemble2) (args !! 1)
                _    -> compile output_bram (compiler assemble2) (args !! 0)
