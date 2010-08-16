{--
LangErrorCheck.hs

This file contains some basic post-parse error checking

--}
module LangErrorCheck where

import LangAST
import Data.List

-- Function : errorCheck
-- Purpose : Checks for programming errors in an FSM
errorCheck (Description ver (CUR_SIG cs) (NEXT_SIG ns) ps generics connections mems channels ss vars initialState ts vhdl)
 = let all_rhs_sigs = (get_all_rhs_sigs ts) ++ (get_all_lhs_sigs ts) in 
      let all_generics = (generic_names generics) in
          let all = (all_generics ++ all_rhs_sigs) in
			let ss' = ss++(add_extras generics) in
			   is_everything_defined all ss' ps

generic_names generics
 = map f generics
    where f (GENERIC_DECL s t v) = (SigName s)

add_extras gs =
	(sigify gs)++[(FSM_SIG "ALL_ZEROS" (STL "junk"))]++[(FSM_SIG "ALL_ONES" (STL "junk"))]

sigify generics
 = map f generics
    where f (GENERIC_DECL s t v) = (FSM_SIG s (STL "junk"))

-- Function : is_everything_defined
-- Purpose : Checks to see if each signal used has been previously defined
is_everything_defined :: [SigName] -> [Node] -> [Node] -> [a]
is_everything_defined (s:ss) sigs ports
	-- First check to see if is a defined signal
   = case (find (isDefinedSig s) sigs) of
         (Just s) -> (is_everything_defined ss sigs ports)
         Nothing  ->  case (find (isDefinedPort s) ports) of -- then check the defined ports
                          (Just s) -> (is_everything_defined ss sigs ports)
                          Nothing  -> error (show s++" is an undefined signal")
is_everything_defined [] sigs ports = []

-- Function : isDefinedSig
-- Purpose : Checks to see if a given signal matches
isDefinedSig (SigName s) (FSM_SIG ss _) = if (s == ss) then True else (if (s == ss++"_next") then True else False)

-- Function : isDefinedPort
-- Purpose : Checks to see if a given signal matches
isDefinedPort (SigName s) (PORT_DECL n _ _) = if (s == n) then True else False

-- Function : get_all_rhs_sigs
-- Purpose : Returns a list of RHS sig names
get_all_rhs_sigs ((TRANS_DECL from_s to_s g body):xs) = (extractRHS body)++(get_all_rhs_sigs xs) 
get_all_rhs_sigs [] = []

-- Function : get_all_lhs_sigs
-- Purpose : Returns a list of LHS sig names
get_all_lhs_sigs ((TRANS_DECL from_s to_s g body):xs) = (extractLHS body)++(get_all_lhs_sigs xs) 
get_all_lhs_sigs [] = []

-- Function : extractRHS
-- Purpose : Returns a list of RHS sig names
extractRHS ((Assign_stmt l r):as) =	(getSigs r)++(extractRHS as)
extractRHS [] =	[]
-- Function : extractLHS
-- Purpose : Returns a list of LHS sig names
extractLHS ((Assign_stmt l r):as) =	(getSigs l)++(extractLHS as)
extractLHS [] =	[]

-- Signal name definition
data SigName =
	SigName String	
	deriving(Show,Eq)

-- Function : getSigs
-- Purpose : Returns a list of sig names from an expression
getSigs (Mem_access m index p) = (getSigs index)
getSigs (Var_access (VarSelRange s a b)) = (SigName s):(getSigs a)++(getSigs b)  
getSigs (Var_access (VarSelBit s a)) = (SigName s):(getSigs a) 
getSigs (Var_access (JustVar s)) = [(SigName s)] 
getSigs (Channel_access t) = []
getSigs (Const_access a) = []
getSigs (UnaryOp s a) = (getSigs a)
getSigs (BinaryOp s a b) = (getSigs a)++(getSigs b)
getSigs (FuncApp s args) = concatMap getSigs args
getSigs (ParensExpr e) = getSigs e

