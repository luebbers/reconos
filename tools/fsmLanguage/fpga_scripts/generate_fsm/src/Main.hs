module Main where

import System.Environment
import LangParser

main =
 do args	<- getArgs
    case args of
		[e, f, o] -> gen_fsm e f o
		_ 		  -> error "Usage: <entityName> <inputFileName> <outputFileName>"
