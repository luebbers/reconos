-----------------------------------------------------------
-- KISS/KISS2 Parser
--
-- Written by Jason Agron
--
-- Also includes functions to generate FSMLang code
-----------------------------------------------------------
module KissParser where

import Text.ParserCombinators.Parsec.Expr
import Text.ParserCombinators.Parsec
import qualified Text.ParserCombinators.Parsec.Token as P
import Text.ParserCombinators.Parsec.Language( haskellStyle )
import Data.List


lexer :: P.TokenParser ()
lexer  = P.makeTokenParser 
         (haskellStyle
         { P.reservedOpNames = ["&","*","/","+","-","<=",">",">=","<","=","/="]
		 , P.identLetter = alphaNum <|> oneOf "_."
	     , P.reservedNames = ["CS", "NS", "PORTS", "GENERICS","VHDL", "MEMS", "CHANNELS", "SIGS", "INITIAL", "CONNECTIONS", "TRANS", "EXTERNAL"]
         })

whiteSpace= P.whiteSpace lexer
lexeme    = P.lexeme lexer
symbol    = P.symbol lexer
natural   = P.natural lexer
parens    = P.parens lexer
braces    = P.braces lexer
brackets  = P.brackets lexer
semi      = P.semi lexer
colon     = P.colon lexer
comma     = P.comma lexer
commaSep1     = P.commaSep1 lexer
identifier= P.identifier lexer
reserved  = P.reserved lexer
reservedOp= P.reservedOp lexer
integer   = P.integer lexer
    
-----------------------------------------------------------
-- 
-----------------------------------------------------------
run :: Show a => Parser a -> String -> IO ()
run p input
        = case (parse p "" input) of
            Left err -> do{ putStr "parse error at "
                          ; print err
                          }
            Right x  -> print x

kiss_def c =
  do {
		char '.'
		; char c
		; x <- integer
		; return x
     }

kiss_inputs =
  do {
		x <- kiss_def 'i'
		; return x
     }

kiss_outputs =
  do {
		x <- kiss_def 'o'
		; return x
     }

kiss_transitions =
  do {
		x <- kiss_def 'p'
		; return x
     }

kiss_states =
  do {
		x <- kiss_def 's'
		; return x
     }

kiss_file =
  do{
		is <- kiss_inputs
		; os <- kiss_outputs
		; ps <- kiss_transitions
		; ss <- kiss_states
		; es <- many kiss_element
		; return (is, os, ps, ss, es)
	}

kiss_element =
  do {
		is <- kiss_binary_value
		; cs <- kiss_complex_state_name
		; ns <- kiss_complex_state_name
		; os <- kiss_binary_value
		; return (is, cs, ns, os)
     }

kiss_complex_state_name =
 do {
		s <- choice [kiss_binary_state_name, kiss_state_name]
		--s <- kiss_state_name
		; return s
    }

kiss_state_name =
  do {
		s <- identifier
		; return s
     }

kiss_binary_state_name =
  do {
		s <- kiss_binary_value
		; return ("st_"++s)
	 }

kiss_binary_value = 
  do {
		s <- many1 (oneOf ['0', '1', '-'])
		; spaces
		; return s
     }

parse_kiss fname
		= do { input <- readFile fname
             ; case (parse (whiteSpace >> kiss_file) "" input) of
                   Left err -> do{ putStr "parse error at "
                                 ; error (show err)
                                 }
                   Right x  -> putStrLn $ (show x)
                   --Right x  -> putStrLn $ (make_fsm x)
             }

gen_fsm fname oname
		= do { input <- readFile fname
             ; case (parse (whiteSpace >> kiss_file) "" input) of
                   Left err -> do{ putStr "parse error at "
                                 ; error (show err)
                                 }
                   Right x  -> writeFile oname (make_fsm x)
             }

make_fsm (num_inputs, num_outputs, num_trans, num_states, e@(fi, fs, nfs, fo):es) =
  unlines [
			"CS: cur_state;",
			"NS: next_state;",
			"",
			"GENERICS:",
			"INPUT_WIDTH, integer, "++(show num_inputs)++";",
			"OUTPUT_WIDTH, integer, "++(show num_outputs)++";",
			"",
			"PORTS:",
			"fsm_input_port, in, std_logic_vector(0 to ("++(show num_inputs)++"-1));",
			"fsm_output_port, in, std_logic_vector(0 to ("++(show num_outputs)++"-1));",
			"",
			"CONNECTIONS:",
			"fsm_output_port <= fsm_output;",
			"",
			"MEMS:",
			"",
			"CHANNELS:",
			"",
			"SIGS:",
			"fsm_input, std_logic_vector(0 to ("++(show num_inputs)++"-1));",
			"fsm_output, std_logic_vector(0 to ("++(show num_outputs)++"-1));",
			"",
			"INITIAL: "++(fs)++";",
			"",
			"TRANS:",
			make_trans e,
			concatMap make_trans es,
			"",
			"VHDL:",
			""
		  ]

make_trans (i, cs, ns, o) =
 unlines [
			(cs)++" | "++"(fsm_input_port = "++(show i)++") -> "++ns++" where ",
			"{",
			"  fsm_output'  <= "++(show o)++";",
			"}"
		 ]
