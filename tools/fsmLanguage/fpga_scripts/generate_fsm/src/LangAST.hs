{--
LangAST.hs

This file describes the AST of the FSM language

--}

module LangAST where
  
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- ************************************************************************
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

-- Data type for VHDL statement
data Stmt = Assign_stmt Expr Expr
		| VAssign_stmt Expr Expr
		| Func_stmt Expr
			deriving(Show,Eq)

-- Data type for VHDL expressions
data Expr = Mem_access String Expr Int
			| Channel_access String
			| Channel_check_exists String
			| Channel_check_full String
			| Var_access Variable_access_type
			| Const_access VHDL_constants
			| BinaryOp String Expr Expr
			| UnaryOp String Expr
			| FuncApp String [Expr]
			| ParensExpr Expr
			deriving(Show,Eq)

-- Data type for VHDL constants
data VHDL_constants = V_integer Integer
					| V_tick Char
					| V_binary_quote [Char]
					| V_hex_quote [Char]
					| V_hex_quote2 [Char]
					deriving(Show,Eq)


-- Haskell data type to hold the entire AST for a description
data Description = Description {
                    reconos_version :: Node,
                    current_state :: Node,
                    next_state :: Node,
                    ports :: [Node],
                    generics :: [Node],
                    connections :: [Node],
                    mems :: [Node],
                    channels :: [Node],
                    sigs :: [Node],
                    vars :: [Node],
                    initialState :: String,
                    transitions :: [Node],
					vhdlCode :: String
                  }
					deriving(Show,Eq)
					
-- Haskell data types for nodes found in description file
data Node = CUR_SIG String
			| NEXT_SIG String
			| FSM_SIG String VHDL_Type
			| PORT_DECL String String VHDL_Type
			| GENERIC_DECL String VHDL_Type VHDL_constants
			| CONNECTION_DECL Stmt
			| TRANS_DECL String String Guard [Stmt]
			| MEM_DECL String Expr Expr Mem_type
			| CHANNEL_DECL String Expr
			| VAR_DECL String VHDL_Type
			| RECONOS_VERSION_DECL String
			deriving(Show,Eq)

-- Haskell data types for transition guards
data Guard =
	Guard Expr
	| NoGuard
	deriving(Show,Eq)

-- Haskell data types for annotating the "side" of an expression (left or right)
data Sideness =
	 Leftside
	| Rightside
	deriving(Show,Eq)

-- Haskell data type for type of memory instantiation
-- Internal = BRAM instantiated inside of FSM
-- External = BRAM is not instantiated, instead it is accessed via ports on the FSM
data Mem_type = InternalMem
				| ExternalMem
				deriving(Show,Eq)

-- Haskell data types for standard logic vector and standard logic
data VHDL_Type = -- STLV String Integer Integer
				  STLV String Expr Expr
				 | STL String
				 deriving(Show,Eq)

-- Haskell data types for the different types of VHDL variable acceses
--	* Just an identifier, i.e. "x"
--	* Identifier with a bit selected, i.e. "x(3)"
--	* Identifier with a range selected, i.e. "x(0 to 1)"
data Variable_access_type =
	JustVar String
	| VarSelBit String Expr
	| VarSelRange String Expr Expr
	deriving(Show,Eq)

