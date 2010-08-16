{--
LangParser.hs

This file contains all of the parsing logic as well as some DOT-file generation
capabilities for the FSM language

--}
-- *****************************************************************
-- Module	: LangParser
-- Author	: Jason Agron (with help from Garrin Kimmel)
-- Date		: 12/20/07
-- Purpose	: Parse the Description format files
-- Usage	: > :load LangParser.hs
--			  > run "<entity_name>" "<VHDL_filename>"
-- *****************************************************************
module LangParser where

import LangAST
--import GenVHDL
import GenReconOS
import GenC(c_template)
import Text.PrettyPrint(render)
import GenHTML
import ExpandMem
import ExpandChannels
import ExpandReconOS
import SoftwareizeChannels
import LangErrorCheck
import Data.HashTable
import Text.ParserCombinators.Parsec.Expr
import Text.ParserCombinators.Parsec
import qualified Text.ParserCombinators.Parsec.Token as P
import Text.ParserCombinators.Parsec.Language( haskellStyle )
import Data.List
import Prelude

-- *****************************************************
-- Setup Lexer/Parser style for Parsec
-- *****************************************************
lexer :: P.TokenParser ()
lexer  = P.makeTokenParser 
         (haskellStyle
         { P.reservedOpNames = ["&","*","/","+","-","<=",">",">=","<","=","/="]
		 , P.identLetter = alphaNum <|> oneOf "_."
	     , P.reservedNames = ["RECONOS", "CS", "NS", "PORTS", "GENERICS","VHDL", "MEMS", "CHANNELS", "SIGS", "VARIABLES", "INITIAL", "CONNECTIONS", "TRANS", "EXTERNAL"]
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
commaSep     = P.commaSep lexer
identifier= P.identifier lexer
reserved  = P.reserved lexer
reservedOp= P.reservedOp lexer
integer   = P.integer lexer
-- *****************************************************************

-- Function used to conditionally set elaboration of states for CFG generation
elaborate_cfg_transitions mems ts = let (counter,ts') = elaborateBody 0 mems ts in (ts') -- Use ts' for elaboration, use ts for non-elaborated

-- Function: genHTML
-- Purpose: Generates HTML version of description file for use in linking with CFG 
genHTML name (Description ver (CUR_SIG cs) (NEXT_SIG ns) ps generics connections mems channels ss vars initialState ts vhdl) =
	let ts' = elaborate_cfg_transitions mems ts in 
	unlines [
		"<HTML>",
		"<HEAD>",
		" <TITLE> "++name++" </TITLE>",
		" <STYLE type=\"text/css\">",
		"  BODY { background: white; color: black}",
		"  A:link { color: red }",
		"  A:visited { color: maroon }",
		"  A:active { color: fuchsia }",
		" </STYLE>",
		"</HEAD>",
		" <BODY> ",
		" -- FSM State Definitions<br>",
		"CS: "++cs++"<br>",
		"NS: "++ns++"<br>",
		"",
		gen_port_html ps,
		gen_connect_html connections,
		gen_mem_html mems,
		gen_sigs_html ss,
		"<br>",
		" -- FSM Initial State<br>",
		"INITIAL: "++initialState++"<br>",
		gen_trans_html ts',
		gen_vhdl_html vhdl,
		"",
		"</BODY>",
		"</HTML>",		
			""
			]

-- Function : genDOT
-- Purpose : Generates the CFG (DOT) for an FSM
genDOT fname (Description ver (CUR_SIG cs) (NEXT_SIG ns) ps generics connections mems channels ss vars initialState ts vhdl) = dotTemplate fname mems initialState ts

-- Function : getTransDOT
-- Purpose: Generates the set of transitions for the DOT file
-- Takes a 4-tupled version of the FSMs transitions and produces the body of a DOT file (all of the transitions)
--	Note: Unguarded transitions will be solid/black, while guarded ones will be dashed/blue
genTransDOT fname i [] = []
genTransDOT fname i (theTrans@(TRANS_DECL f t g b):ts) =
	let g' = (formGuardString g) in
     let all_lhs = get_all_lhs_sigs [theTrans] in 
      let fname' = fname++"#"++(genSectionName i) in
	      let color  = case g of
			  		     NoGuard -> []
					     (Guard guard) -> ",color=\"blue\", style=dashed"
						in "  "++f++" -> "++t++"[ label = "++(show (adjustGuard g'))++" "++color++", URL = "++(show fname')++"]\n"++(genTransDOT fname (i+1) ts)
-- Function: formGuardString
-- Purpose: Translates a guard expression into a string 
formGuardString g =
          case g of
               NoGuard -> []
               (Guard guard) -> render $ dispExpr guard

-- Function used to conditionally adjust a guard's format based on it's length
adjustGuard cs =
	let len = length cs in
		if (len > 10) then (trimGuard cs) else cs

-- Function used to make guards more visible in the CFG
-- Works by inserting newlines where spaces existed
trimGuard [] = []
trimGuard (c:cs) =
--	if c == ' '
	if c == ')'
		then
--			'\n':(trimGuard cs)
			')':'\n':(trimGuard cs)
		else
			c:(trimGuard cs)

-- Function: dotTemplate
-- Purpose:  Generates the DOT template to be written to file
-- Template for the DOT file
-- transitions = List of TRANS_DECLs from the Description AST
dotTemplate fname mems initialState transitions =
  let ts' = elaborate_cfg_transitions mems transitions in
  unlines [ "digraph G {",
				"",
				"  node [color=lightblue2, style=filled]",
				"  "++initialState++" [shape = Mcircle, style=\"filled,bold,diagonals\", fillcolor=lightgrey]",
			--	"  graph[page=\"8.5,11\",size=\"10,10\",ratio=auto,center=1,nodesep=0.8]",
				"  graph[ratio=auto,center=1,nodesep=0.5]",
				(genTransDOT fname 0 ts'),
				"}",
				""
				] 

-- Function	: run
-- Purpose	: Runs the description parser and displays the resulting VHDL
-- Usage	: run <entity_name> "<filename>"
run ename fname
		= do { input <- readFile fname
             ; case (parse (whiteSpace >> decls) "" input) of
                   Left err -> do{ putStr "parse error at "
                                 ; error (show err)
                                 }
                   --Right x  -> putStrLn (genVHDL ename x)
                   Right x  -> error (show x)	-- Use this to look at the Description AST
                   --Right x  -> putStrLn ((errorCheck x))	-- Use this to look at the Description AST
             }

-- Function	: gen_fsm
-- Purpose	: Generates VHDL from a description file
-- Usage	: gen_fsm <entity_name> "<descrip_filename>" "<VHDL_output_filename>"
gen_fsm ename fname oname
		= do { input <- readFile fname
             ; case (parse (whiteSpace >> decls) "" input) of
                   Left err -> do{ putStr "parse error at "
                                 ; error (show err)
                                 }
                   Right x  -> writeFile oname (genReconOS ename x)
             }


-- Function	: gen_mpd
-- Purpose	: Generates MPD from a description file
-- Usage	: gen_fsm <entity_name> "<descrip_filename>" "<MPD_output_filename>"
gen_mpd ename fname oname
		= do { input <- readFile fname
             ; case (parse (whiteSpace >> decls) "" input) of
                   Left err -> do{ putStr "parse error at "
                                 ; error (show err)
                                 }
                   Right x  -> writeFile oname (genMPD ename x)
             }


-- Function	: gen_sw
-- Purpose	: Generates C from a description file
-- Usage	: gen_fsm <entity_name> "<descrip_filename>" "<C_output_filename>"
gen_sw ename fname oname
		= do { input <- readFile fname
             ; case (parse (whiteSpace >> decls) "" input) of
                   Left err -> do{ putStr "parse error at "
                                 ; error (show err)
                                 }
                   Right x  -> writeFile oname (genC ename x)
             }

-- Function	: gen_cfg
-- Purpose	: Generates CFG (DOT format) and it's associative HTML-form of the description file from a description file
-- Usage	: gen_cfg "<descrip_filename>" "<DOT_output_filename>"
gen_cfg fname oname
		= do { input <- readFile fname
             ; case (parse (whiteSpace >> decls) "" input) of
                   Left err -> do{ putStr "parse error at "
                                 ; error (show err)
                                 }
                   Right x  -> do {
									writeFile oname (genDOT (oname++".html") x)
									; writeFile (oname++".html") (genHTML fname x)
								  }
		}

-- Function	: reachable
-- Purpose	: Performs an reachability check on the states of an FSM
-- Usage	: reachable "<descrip_filename>"
reachable fname
		= do { input <- readFile fname
             ; case (parse (whiteSpace >> decls) "" input) of
                   Left err -> do{ putStr "parse error at "
                                 ; error (show err)
                                 }
                   Right x  -> do {
									putStrLn $ (genReachability x)
								  }
		}


-- ***************************************************
-- Statement parser code...
-- ***************************************************
-- Parser for a list of statements
stmt_list = do {as <- many stmt
		; return as
		}

stmt = do { choice' [assign_stmt, vassign_stmt, func_stmt] }

-- Parser for a statement (assignment statement)
assign_stmt = do { a <- nexted_lhs
		  ; reservedOp "<="
		  ; b <- expr
		  ; semi
		  ; return (Assign_stmt a b)
		 }

-- variable assignment
vassign_stmt = do { a <- nexted_lhs
		  ; reservedOp ":="
		  ; b <- expr
		  ; semi
		  ; return (VAssign_stmt a b)
		 }

-- function statement
func_stmt = do { e <- func_app
		  ; semi
		  ; return (Func_stmt e)
		 }


-- Parser for LHS of assignment statments - Must be a:
--	* Nexted Variable Access, i.e. "x'"
--	* Memory access, i.e. "mem[4]"
nexted_lhs = do { choice' [channel_access, mem_access, (var_access NotNexted)] }
			   <?> "valid LHS (either a \"nexted\" variable, channel access, or a memory access)"

-- ***************************************************
-- Expression parser code...
-- ***************************************************
expr   = buildExpressionParser table factor
        <?> "expression"

table   = [
		[prefix "not" (UnaryOp "not")]
		,[op "*" (BinaryOp "*") AssocLeft, op "/" (BinaryOp "/") AssocLeft]
		,[op "+" (BinaryOp "+" ) AssocLeft, op "-" (BinaryOp "-") AssocLeft]
		,[op "and" (BinaryOp "and" ) AssocLeft, op "or" (BinaryOp "or") AssocLeft, op "xor" (BinaryOp "xor") AssocLeft, op "&" (BinaryOp "&") AssocLeft ]
		,[op ">" (BinaryOp ">" ) AssocLeft, op ">=" (BinaryOp ">=") AssocLeft, op "<" (BinaryOp "<") AssocLeft, op "<=" (BinaryOp "<=") AssocLeft, op "=" (BinaryOp "=") AssocLeft, op "/=" (BinaryOp "/=") AssocLeft ]
          ]          
        where
          op s f assoc = Infix (do{ reservedOp s; return f}) assoc
          prefix s f = Prefix (do {reservedOp s; return f})

-- Parser for each "term" in an expression
factor = do{ x <- parens expr
            ; return (ParensExpr x) 
            }
        <|> do { x <- choice' [vhdl_hex_quote, vhdl_hex_quote2, vhdl_binary_quote, vhdl_tick, vhdl_integer]
			   ; return (Const_access x)
			   }
		<|> do { choice' [channel_access, mem_access, func_app, (var_access NotNexted)] }
        <?> "simple expression"

func_app = do	{ f <- identifier
				; args <- parens (commaSep expr)
--				; args <- parens (commaSep1 expr)
				; return (FuncApp f args)
				}

vhdl_integer = do	{ x <- integer
				  	; return (V_integer x)
					}

vhdl_tick = do	{ symbol "'"
				; x <- (oneOf ['0', '1'])
				; symbol "'"
				; return (V_tick x)
				}

vhdl_binary_quote = do	{ symbol "\""
						; x <- many (oneOf ['0', '1'])
						; symbol "\""
						; return (V_binary_quote x)
						}

vhdl_hex_quote = do	{ symbol "x\""
						; x <- many hexDigit
						; symbol "\""
						; return (V_hex_quote x)
						}

vhdl_hex_quote2 = do	{ symbol "X\""
						; x <- many hexDigit
						; symbol "\""
						; return (V_hex_quote2 x)
						}


vhdl_constant = do { x <- choice' [vhdl_hex_quote, vhdl_hex_quote2, vhdl_binary_quote, vhdl_tick, vhdl_integer]
                   ; return x
				  }

-- Parser for variable (signal) accesses
-- Data type used to represent ticks and noticks
data SigType =
	Nexted
	| NotNexted
	deriving(Show,Eq)	

var_access tickVal = do	{t <- any_var_access tickVal 
						; return (Var_access t)
						}

any_var_access tickVal = do { choice' [name_and_range tickVal, name_and_bit tickVal, just_name tickVal] }

name_and_range NotNexted=
	do	{ i <- identifier
		; (a,b) <- parens range
		; return (VarSelRange i a b)
		}

name_and_range Nexted=
	do	{ i <- identifier
		; nexted_symbol
		; (a,b) <- parens range
		; return (VarSelRange (nextify i) a b)
		}


name_and_bit NotNexted = do { i <- identifier
					; b <- parens expr
					; return (VarSelBit i b)
					}

name_and_bit Nexted = do { i <- identifier
					; nexted_symbol
					; b <- parens expr
					; return (VarSelBit (nextify i) b)
					}

just_name NotNexted = do { i <- identifier
				; return (JustVar i)
				}
just_name Nexted = do { i <- identifier
				; nexted_symbol
				; return (JustVar (nextify i))
				}

-- Parser for memory (BRAM) accesses
mem_access = do		{ n <- identifier
			; i <- brackets expr
		 	; return (Mem_access n i 0)
			}

-- Parser for channel accesses
--channel_access = do { char '#'
--                    ; n <- identifier
--		 			; return (Channel_access n)
--					}
channel_access = do { choice' [channel_check_full, channel_check_exists, traditional_channel_access] }
traditional_channel_access = do		{ char '#'
                    ; n <- identifier
		 			; return (Channel_access n)
					}
channel_check_full = do		{
					; char '#'
                    ; n <- identifier
					; char '#'
					; reserved "full"
		 			; return (Channel_check_full n)
					}
channel_check_exists = do		{
					; char '#'
                    ; n <- identifier
					; char '#'
					; reserved "exists"
		 			; return (Channel_check_exists n)
					}

-- ***************************************************
-- Functions to handle VHDL generation of statements
-- ***************************************************

-- Parser	: type_expr
-- Purpose	: Handles VHDL types
type_expr = do	{ choice' [stlv, stl] }

nexted_symbol = do { reserved "'" }

-- Parser	: stlv
-- Purpose	: Handles "std_logic_vector(<A> to <B>)"
stlv = do	{ i <- identifier
				; (a,b) <- parens range
				; return (STLV i a b) 
				}

-- Parser	: stl
-- Purpose	: Handles "std_logic"
stl = do	{ i <- identifier
			; return (STL i) 
			}

-- Parser	: range
-- Purpose	: Handles "<A> to <B>"
range = do	{ a <- expr
			; reserved "to"
			; b <- expr
			; return (a,b)
			}

-- Parser	: current_state_decl
-- Purpose	: Handles "CS: <current_sig>"
current_state_decl = do { reserved "CS"
						;  colon
						; i <- identifier
						; semi
						;  return (CUR_SIG i)
						}

-- Parser	: next_state_decl
-- Purpose	: Handles "NS: <current_sig>"
next_state_decl = do { 	reserved "NS"
					 ;	colon
					 ; i <- identifier
					 ; semi
					 ;	return (NEXT_SIG i)
				     }

-- Parser	: reconos_version_decl
-- Purpose	: Handles "RECONOS: <version_number>"
reconos_version_decl = do { reserved "RECONOS"
						;  colon
						; i <- identifier
						; semi
						;  return (RECONOS_VERSION_DECL i)
						}


-- Parser	: port_decl
-- Purpose	: Handles "<sig_name>, <sig_dir>, <sig_type>"
port_decl = do 		 { n <- identifier
					 ;  comma
					 ;	d <- identifier
					 ;  comma
					 ;	t <- type_expr
					 ; semi
					 ; return (PORT_DECL n d t)
				     }

-- Parser	: generic_decl
-- Purpose	: Handles "<generic_name>, <sig_type>, <value>"
generic_decl = do 		 { n <- identifier
					 ;  comma
					 ;	t <- type_expr
					 ;  comma
					 ;	v <- vhdl_constant
					 ; semi
					 ; return (GENERIC_DECL n t v)
				     }

-- Parser	: connection_decl
-- Purpose	: Handles "<sig_a> <= <sig_b>"
connection_decl =
		do { a <- connection_lhs
		  ; reservedOp "<="
		  ; b <- expr
		  ; semi
		  ; return (CONNECTION_DECL (Assign_stmt a b))
		 }

connection_lhs = do { var_access NotNexted }
			   <?> "valid connection LHS must be a variable access)"




-- Parser	: mem_decl
-- Purpose	: Handles "<mem_name>, <mem_type>, <mem_size>"
mem_decl = do 		 { n <- identifier
					 ;  comma
					 ;	t <- expr
					 ;  comma
					 ;	s <- expr
					 ; k <- option InternalMem ( comma >> reserved "EXTERNAL" >> return ExternalMem)
					 ; semi
					 ; return (MEM_DECL n t s k)
				     }



-- Parser	: channel_decl
-- Purpose	: Handles "<channel_name>"
channel_decl = do 		 { n <- identifier
					 ; comma
					 ; s <- expr
					 ; semi
					 ; return (CHANNEL_DECL n s)
				     }

-- Parser	: sig_decl
-- Purpose	: Handles "<sig_name>, <sig_type>"
sig_decl = do 		 { n <- identifier
					 ;  comma
					 ;	t <- type_expr
					 ; semi
					 ; return (FSM_SIG n t)
				     }


-- Parser	: var_decl
-- Purpose	: Handles "<var_name>, <var_type>"
var_decl = do 		 { n <- identifier
					 ;  comma
					 ;	t <- type_expr
					 ; semi
					 ; return (VAR_DECL n t)
				     }

-- Parser	: trans_decl
-- Purpose	: Handles "<from_state> -> <to_state>" with an optional guard
					--; g <- guard <|> (reserved "->" >> return [])
-- FIXME - turn this into an expression parser so that guards can be parsed and code-gen'd
trans_decl = do 	{ from_s <- identifier
					--; g <- (reserved "->" >> return NoGuard) <|> guard_decl
					; g <- guard_decl
		        		; reserved "->"
					; to_s <- identifier
					; body <- option [] trans_body
					; return (TRANS_DECL from_s to_s g body)
				    }

trans_decl_with_block = do    { from_s <- identifier
				; g <- guard_decl
		        	; reserved "->"
				; to_s <- identifier
				; body <- option [] block_list
				; return (elaborate_blocks from_s to_s g body)
			    }

block_state_name s (Guard g) i = s++"_g_"++(show $ abs $ hashString (render $ expr2string g))++"_"++(show i)
block_state_name s (NoGuard) i = s++"_g_NOGUARD_"++(show i)

elaborate_blocks start final guard [] = [(TRANS_DECL start final guard [])]
elaborate_blocks start final guard (b:[]) = [(TRANS_DECL start final guard b)]
elaborate_blocks start final guard (b:bs) =
  [(TRANS_DECL start (block_state_name start guard 0) guard b)]++(convert_blocks [] 0 start final guard bs)


gen_first_block start_state first_block_name cond (b:bs) =
  (TRANS_DECL start_state first_block_name cond b)

convert_blocks accumTrans count start_state final_state cond [] = 
 let lastName = (block_state_name start_state cond count) in
  let lastTrans = (TRANS_DECL lastName final_state NoGuard []) in
  	(lastTrans:accumTrans)

convert_blocks accumTrans count start_state final_state cond (b:[]) = 
  let newName = (block_state_name start_state cond count) in
    let nextName = (block_state_name start_state cond (count+1)) in
	  let newTrans' = (TRANS_DECL newName final_state NoGuard b) in
		let accumTrans' = (newTrans':accumTrans) in
	             accumTrans'

convert_blocks accumTrans count start_state final_state cond (b:bs) = 
  let newName = (block_state_name start_state cond count) in
    let nextName = (block_state_name start_state cond (count+1)) in
	  let newTrans' = (TRANS_DECL newName nextName NoGuard b) in
		let accumTrans' = (newTrans':accumTrans) in
	             (convert_blocks accumTrans' (count+1) start_state final_state cond bs)


-- Parser	: guard
-- Purpose	: Handles the optional guard of the form "| <guard> ->"
guard_decl = option NoGuard guard_exists

guard_exists = do { reservedOp "|"
		        ; x <- expr
		        ; return (Guard x)
		        }
-- ****************************************************************************
-- FIXME: to get sequential blocks
-- * Use block list inside of trans_decl parser
-- * Then create an elaborate trans_decl function that creates many trans_decls
--   from ones that contain several block_lists
-- * The result is trans_decls with only lists of statements!
-- ****************************************************************************
--block_list = do	{ reserved "where"
--				; symbol "{"
--				; ss <- many block_body
--				; symbol "}"
--				; return ss
--				}

block_list = do	{ symbol "{"
				; ss <- many block_body
				; symbol "}"
				; return ss
				}

-- Parser	: trans_body
-- Purpose	: Handles "where { <vhdl statements> }"
block_body =
 do { symbol "{"
	; ss <- many stmt
	; symbol "}"
	; return ss
	}



-- Parser	: trans_body
-- Purpose	: Handles "where { <vhdl statements> }"
trans_body = do	{ reserved "where"
				; symbol "{"
				; ss <- many stmt
				; symbol "}"
				; return ss
				}

-- Parser	: decls
-- Purpose	: Parses an entire description program
decls = do 	{ ver <- reconos_version_decl
		; cs <- current_state_decl
		; ns <- next_state_decl
		; reserved "GENERICS"
		; colon
		; generics <- many generic_decl
		; reserved "PORTS"
		; colon
		; ports <- many port_decl
		; reserved "CONNECTIONS"
		; colon
		; connections <- many connection_decl
		; reserved "MEMS"
		; colon
		; mems <- many mem_decl
		; reserved "CHANNELS"
		; colon
		; channels <- many channel_decl
		; reserved "SIGS"
		; colon
		; sigs <- many sig_decl
		; reserved "VARIABLES"
		; colon
		; vars <- many var_decl
		; reserved "INITIAL"
		; colon
		; initialState <- identifier
		; semi
		; reserved "TRANS"
		; colon
		--; trans <- many trans_decl
		; trans <- (many trans_decl_with_block)
		; reserved "VHDL"
		; colon
		; vhdl <- many anyToken
--		; return (Description cs ns ports generics connections (reconosMem:mems) channels sigs vars initialState trans vhdl)
		; return (Description ver cs ns ports generics connections (reconosMem:mems) channels sigs vars initialState (foldr (++) [] trans) vhdl)
--		; return (Description ver cs (nextStateDef) ports generics connections (reconosMem:mems) channels sigs vars initialState (foldr (++) [] trans) vhdl)
		}


-- local_ram memory access for ReconOS 
reconosMem = (MEM_DECL "local_ram" (Const_access (V_integer 32)) (Const_access (V_integer 11))  ExternalMem )

-- define (unused) dummy next state
nextStateDef = (NEXT_SIG "dummy_next_state")

-- Haskell function for backtracking choices for node_types
choice' ps = choice $ map try ps



-- Haskell data type for sourcePos: Srcp <filename> <extension> <line_number>
data SrcPos = Srcp String String Integer
				  deriving(Show,Eq)

 
-- Function : genVHDL
-- Purpose : Generates the VHDL for an FSM
genReconOS eName (Description (RECONOS_VERSION_DECL ver) (CUR_SIG cs) (NEXT_SIG ns) ps generics connections mems channels ss vars initialState ts vhdl)
	= let (counter,ts') = elaborateBody 0 mems ts in
		let (counter', ts'') = elaborateChannelsBody counter channels ts' in
		     let (counter'', ts''') = elaborateReconOSBody counter' channels ts'' in
			template
				ver
				cs
				ns
				eName
				ps
				generics
				connections
				mems
				channels
				ts'''
				initialState
				ss
 				vars
				vhdl


-- Function : genMPD
-- Purpose : Generates the MPD for an FSM
genMPD eName (Description ver (CUR_SIG cs) (NEXT_SIG ns) ps generics connections mems channels ss vars initialState ts vhdl)
	= let (counter,ts') = elaborateBody 0 mems ts in
		let (counter', ts'') = elaborateChannelsBody counter channels ts' in
			mpd_template
				eName
				ps
				generics
				mems
				channels

-- Function : genC
-- Purpose : Generates the C for an FSM
genC eName (Description ver (CUR_SIG cs) (NEXT_SIG ns) ps generics connections mems channels ss vars initialState ts vhdl) = 
	let (counter, ts') = elaborateChannelsBody_sw 0 channels ts in
		c_template
			cs
			ns
			eName
			ps
			generics
			connections
			mems
			channels
			ts'
			initialState
			ss
			vhdl

-- Function : genReachability
-- Purpose : Generates a Reachability table
genReachability (Description ver (CUR_SIG cs) (NEXT_SIG ns) ps generics connections mems channels ss vars initialState ts vhdl)
	= genReachabilityTable initialState ts
