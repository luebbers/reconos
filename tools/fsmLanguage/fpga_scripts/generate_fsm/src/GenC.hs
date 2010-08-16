{--
GenC.hs

This file contains all of the functionality to generate an executable FSM description in C.

--}

module GenC(dispExpr,c_template) where
  
import LangAST

import Text.PrettyPrint
import Data.List(groupBy,sortBy,intersperse,nub,mapAccumL,find)
import Data.Maybe(catMaybes)
import ExpandMem(addressSig, readEnableSig, writeEnableSig, dataInSig, dataOutSig, getAllDependencies)
import SoftwareizeChannels(channelReadEnableSig, channelWriteEnableSig, channelInSig, channelOutSig,channelJunkSig, channelAccessFunction, channelID, channelFullSig, channelExistsSig)

-- Function used to "nextify" a string
nextify s = s++"_next"

-- Transforms an expression into a C string
--dispExpr (Mem_access m index p) = text m <> brackets (text index)
dispExpr direction (Mem_access m index p) = text m <> brackets (dispExpr direction index)
dispExpr Leftside (Channel_access t) = text "#" <> text t
dispExpr Rightside (Channel_access t) = text "#" <> text t
dispExpr direction (Channel_check_full t) = text (channelFullSig t)
dispExpr direction (Channel_check_exists t) = text (channelExistsSig t)
dispExpr direction (Var_access t) = text (unvar t)
dispExpr direction (Const_access a) = dispConst a
dispExpr direction (UnaryOp s a) = text s <+> (dispExpr direction a)
dispExpr direction (BinaryOp s a b) = (dispExpr direction a) <+> text (changeOp s) <+> (dispExpr direction b)
dispExpr direction (FuncApp s args) = (text s) <> parens (hcat (punctuate comma (map (dispExpr direction) args)))
dispExpr direction (ParensExpr e) = text "(" <+> (dispExpr direction e) <+> text ")"

-- Function used to change built-in operations to C-style operations
changeOp "and" = "&"
changeOp "or" = "|"
changeOp "xor" = "^"
changeOp "=" = "=="
changeOp "/=" = "!="
changeOp s = s

-- Transforms all the types of C constants to a string for use in code generation
dispConst (V_integer i) = integer i
dispConst (V_tick c) = text [c]
dispConst (V_binary_quote c) = text "0b" <> (text c)
dispConst (V_hex_quote c) = text "0x" <> (text c)

-- Function: getStates
-- Purpose: get a list of all of the states in a machine
getStates :: [Node] -> [String]
getStates trans = nub $ concatMap getState trans
  where getState (TRANS_DECL from to _ _) = [from,to]

-- Function: getReverseTranstitions
-- Purpose: get a list of all of the transitions in a machine in reversed tuple form (to,from)
getReverseTransitions trans = map getTs trans
  where getTs (TRANS_DECL from to _ _) = (to, from)

-- Function: getTranstitions
-- Purpose: get a list of all of the transitions in a machine in tuple form (from,to)
getTransitions trans = map getTs trans
  where getTs (TRANS_DECL from to _ _) = (from, to)

genReachabilityTable initialState ts =
  let all_states 			= (getStates ts)
      reachabilityTable 	= (gatherReachability all_states (getTransitions ts))
      (transitive_closure,root_reachable) = tclose reachabilityTable initialState
  in
					unlines $ [
							   "**** Unreachable States: ****",
								unlines (displayUnreachable initialState all_states root_reachable),
							   --"**** Transitive Closure: ****",
							   --(displayReachability transitive_closure),
							   --"**** Reachability Table: ****",
								--(displayReachability reachabilityTable),
								""
							   ]

displayUnreachable initialState [] tclos = []
displayUnreachable initialState (s:ss) tclos =
	if (s /= initialState)
		then
			case (find (==s) tclos) of
				Nothing -> s:(displayUnreachable initialState ss tclos)
				Just x ->  displayUnreachable initialState ss tclos
		else
			displayUnreachable initialState ss tclos

tclose states start = let states' = expand states
                          Just snow = lookup start states
                          Just snext = lookup start states'
                      in if snow == snext 
						   then (states',snext)
                           else tclose states' start


expand states = map exp states
  where exp (cur,nexts) = (cur, nub $ nexts ++ (concat $ catMaybes $ map (\v ->  lookup v states) nexts))


displayReachability [] = []
displayReachability ((a,t):ts) =
	a ++ ":\n" ++ unlines t ++ "\n" ++ (displayReachability ts)

gatherReachability ss all_ts = map (calcReachability [] all_ts) ss

calcReachability acc [] start = (start,(nub acc))
calcReachability acc ((src,dest):ts) start =
	if start == src && start /= dest
		then
			(calcReachability (dest:acc) ts start )
		else
			(calcReachability acc ts start)
		
-- Function: genStateEnum
-- Purpose: Generate the contents of the state enumeration type
genStateEnum :: [Node] -> String
genStateEnum ts = concat $ intersperse ",\n" (getStates ts)
				    
-- Function: untype
-- Purpose: Converts a C type container into a string
untype (STLV s a b) =
    let a' = render $ dispExpr Rightside a
        b' = render $ dispExpr Rightside b in
             (morphType s)-- ++" : ("++a'++" to "++b'++")"
untype (STL s ) = (morphType s)

morphType "integer" = "int"
morphType "std_logic_vector" = "int"
morphType "std_logic" = "int"
morphType s = s

-- Function: unvar
-- Purpose: Converts a C var access into a string
--unvar (VarSelRange s a b) = s++"("++show a++" to "++show b++")"
--unvar (VarSelBit s a) = s++"("++show a++")"
--unvar (JustVar s ) = s

unvar (VarSelRange s a b) =
    let a' = render $ dispExpr Rightside a
        b' = render $ dispExpr Rightside b in
               s++"("++a'++" to "++b'++")"
unvar (VarSelBit s a) = 
    let a' = render $ dispExpr Rightside a in
              s++"("++a'++")"
unvar (JustVar "ALL_ZEROS") = "0x00000000"
unvar (JustVar "ALL_ONES") = "0xFFFFFFFF"
unvar (JustVar s ) = s

-- Function: genSigResets
-- Purpose: Generates a set of assignment statements to reset all FSM sigs to zero(s)
genSigResets ss = concatMap sp ss
	where sp (FSM_SIG n t) = "      "++n++(resetSig t)

-- Function: genSigTrans
-- Purpose: Generates a set of assignment statements to transition all FSM sigs to their next state
genSigTrans ss = concatMap sp ss
	where sp (FSM_SIG n t) = "          "++n++" = "++ (nextify n) ++";\n"

-- Function: genSigDefaults
-- Purpose: Generates a set of assignment statements to assign default values for each FSM signal
genSigDefaults ss = concatMap sp ss
	where sp (FSM_SIG n t) = "  "++ (nextify n)++" = "++n++";\n"

-- Function: resetSig
-- Purpose: Converts a C type container into an assignment statement used during reset (assignment to zero)
resetSig (STLV s a b)	= " = 0;\n"
resetSig (STL s ) 		= " = 0;\n"

-- Function: genBody
-- Purpose: Generates the body of the FSM (each "when" clause and it's associated transitions)
-- ns = next state signal
-- l = original list of transitions
genBody :: String -> [Node] -> String
genBody ns ts = render $ nest 12 $ vcat $ map (genState ns) groups
  where groups = groupBy grouping $ sortBy sorting ts
        sorting (TRANS_DECL s _ _ _) (TRANS_DECL s' _ _ _) = compare s s'
        grouping (TRANS_DECL s _ _ _) (TRANS_DECL s' _ _ _) = s == s'


genCycleEstimate as =
  let ds = (getAllDependencies as) in
           case ds of
			(x:xs) -> text "clockEstimate+=3;" 
			[]     -> text "clockEstimate+=1;"

-- Old version
-- Generates if-endifs

-- genState generates a 'when' clause for a set of state originating in the same 
-- start state
{-genState ns ts@((TRANS_DECL start _ _ _):_) = 
  text "when" <+> text start <+> text "=>" $$
  nest 2 (vcat (map (genTrans ns) ts))
-}

-- New version
-- Generates if-elseif-else-endifs
genState ns ts@((TRANS_DECL start _ _ _):_) = 
  text "case" <+> text start <+> text ":" $$
  nest 2 (text ("printf(\"Current State = "++start++"(%d)\\n\",clockEstimate);")) $$
  nest 2 ((genSuperTrans start ns ts)) $$ nest 2 (text "break;")

-- genTrans generates the signal assignments for a given transition 
genTrans ns (TRANS_DECL _ end NoGuard body) = 
  vcat (map genAssign body) $$
  nest 2 (genCycleEstimate body) $$
  text ns <+> text "=" <+> text end <> text ";"
genTrans ns (TRANS_DECL _ end (Guard guard) body) = 
  text "if" <+> dispExpr Rightside guard <+> text "{" $$
  nest 2 (genCycleEstimate body) $$
  nest 2 ((vcat (map genAssign body)) $$
          text ns <+> text "=" <+> text end <> text ";") $$
  text "}"

unguardedCheck acc [] = acc
unguardedCheck acc ((TRANS_DECL _ _ g _):ts) =
   case g of
      NoGuard -> (unguardedCheck (acc+1) ts)
      (Guard _) -> (unguardedCheck acc ts)

genSuperTrans start ns ts =
 if ((unguardedCheck 0 ts) > 1)
    then
      error $ "Invalid FSM - state has more than one un-guarded transition! ("++start++")"
    else
      case ts of
           (a:[]) -> (genTrans ns a)
           ts@(a:as) -> (genIfElses ns 0 (sortBy sorting ts))
  -- Function used to make sure that "un-guarded transitions are always last
  where sorting (TRANS_DECL _ _ g1 _) (TRANS_DECL _ _ g2 _) =
            case g1 of
               NoGuard -> case g2 of
                       NoGuard -> EQ
                       _  -> GT
               _  -> EQ 

genIfElses ns acc [] = text "" 
genIfElses ns acc ((TRANS_DECL _ end guard body):[]) =
 if acc == 0
    then
      text "if (" <+> (checkGuard guard) <+> text ") {" $$
      nest 2 (genCycleEstimate body) $$
      nest 2 ((vcat (map genAssign body)) $$
           text ns <+> text "=" <+> text end <> text ";") $$
	  text "}" $$
     (genIfElses ns (acc+1) [])
	else
      (prefixGuard guard) $$
      nest 2 (genCycleEstimate body) $$
      nest 2 ((vcat (map genAssign body)) $$
           text ns <+> text "=" <+> text end <> text ";") $$
	  text "}" $$
      (genIfElses ns (acc+1) [])

genIfElses ns acc ((TRANS_DECL _ end guard body):ts) =
 if acc == 0
    then
      text "if (" <+> (checkGuard guard) <+> text ") {" $$
      nest 2 (genCycleEstimate body) $$
      nest 2 ((vcat (map genAssign body)) $$
           text ns <+> text "=" <+> text end <> text ";") $$
	  text "}" $$
     (genIfElses ns (acc+1) ts)
	else
      text "else if (" <+> (checkGuard guard) <+> text ") {" $$
      nest 2 (genCycleEstimate body) $$
      nest 2 ((vcat (map genAssign body)) $$
           text ns <+> text "=" <+> text end <> text ";") $$
	  text "}" $$
      (genIfElses ns (acc+1) ts)

checkGuard guard = case guard of
                      NoGuard -> text "(true)"
                      (Guard g) -> dispExpr Rightside g
prefixGuard guard = case guard of
                      NoGuard -> text "else {"
                      (Guard _)  -> text "else if (" <+> (checkGuard guard) <+> text ") {"

-- genAssign generates the signal assignment for a statement
genAssign (Assign_stmt l r) = (dispExpr Leftside l) <+> text "=" <+> (dispExpr Rightside r) <> text ";"


-- Function: genPorts
-- Purpose: Generates port definition strings
genPorts ps = concatMap gp ps
  where gp (PORT_DECL n d t) = (untype t)++" "++n++"; //"++d++"\n"

-- Function: genGenerics
-- Purpose: Generates generic definition strings
genGenerics [] = ""
genGenerics ps =
        (concatMap gp ps)
  --where gp (GENERIC_DECL n t v) = "const "++(untype t)++" "++n++" = "++render (dispConst v)++";\n"
  where gp (GENERIC_DECL n t v) = "#define "++n++" "++render (dispConst v)++"\n"


genMemPorts ms = concatMap f ms
	where f (MEM_DECL n t s InternalMem) = ""
	      f (MEM_DECL n t s ExternalMem)  =
               let s' = render $ dispExpr Rightside s
                   t' = render $ dispExpr Rightside t in
				unlines	[
						"  "++(addressSig n 0)++" : out std_logic_vector(0 to ("++s'++" - 1));",
						"  "++(dataInSig n 0)++" : out std_logic_vector(0 to ("++t'++" - 1));",
						"  "++(dataOutSig n 0)++" : in std_logic_vector(0 to ("++t'++" - 1));",
						"  "++(readEnableSig n 0)++" : out std_logic;",
						"  "++(writeEnableSig n 0)++" : out std_logic;"
						]
 
-- Function: genPermanentConnections
-- Purpose: Generate permanent connections
genPermanentConnections ss = concatMap sp ss
  where sp (CONNECTION_DECL a) =  case (getAllDependencies [a]) of
                                    []     -> render $ genAssign a <+> text "\n"
                                    (x:xs) -> error $ ("Connections cannot contain memory accesses! Error in:\n"++ (render (genAssign a)))

-- Function: genMemorySigDefs
-- Purpose: Generate signal definition strings for the memories
genMemorySigDefs ss = concatMap sp ss
  where sp (MEM_DECL n t s _) = 
               let s' = render $ dispExpr Rightside s
                   t' = render $ dispExpr Rightside t in
                                 unlines [ "// **************************",
										"// BRAM Signals for "++n,
										"// **************************",
										(untype (STL "integer"))++" "++n++"[(2 << ("++(render $ dispExpr Rightside s)++" - 1))];",
										""
									]
-- Function: genChannelSigDefs
-- Purpose: Generate FSL IDs for the channels
genChannelIDs acc [] = []
genChannelIDs acc ((CHANNEL_DECL n _):ss) = "#define "++(channelID n)++" "++(show acc)++"\n"++(genChannelIDs (acc+1) ss) 

-- Function: genChannelSigDefs
-- Purpose: Generate signal definition strings for the channels
genChannelSigDefs ss = concatMap sp ss
  where sp (CHANNEL_DECL n s) = 
               let s' = render $ dispExpr Rightside s in
                                 unlines [ "// **************************",
										"// Channel Components for "++n,
										"// **************************",
										(untype (STL "integer"))++" "++(channelReadEnableSig n)++";",
										(untype (STL "integer"))++" "++(channelWriteEnableSig n)++";",
										(untype (STL "integer"))++" "++(channelInSig n)++";",
										(untype (STL "integer"))++" "++(channelOutSig n)++";",
										(untype (STL "integer"))++" "++(channelJunkSig n)++";",
										"int "++(channelAccessFunction n)++"(){",
										"  int tempVal = 0;",
										"  // Check for a read or a write operation",
										"  if ("++(channelReadEnableSig n)++"){",
										"     getfsl(&tempVal,"++(channelID n)++");",
										"  }",
										"  else{",
										"     putfsl(&"++(channelInSig n)++","++(channelID n)++");",
										"  }",
										"  // De-assert enable signals",
										"  "++(channelReadEnableSig n)++" = 0;",
										"  "++(channelWriteEnableSig n)++" = 0;",
										"  return tempVal;",
										"}",
										""
									]

-- Function: genMemoryInstantiations
-- Purpose: Generate instantiations for each individual BRAM
genMemoryInstantiations ss = concatMap sp ss
  where  sp (MEM_DECL n t s ExternalMem) = ""
         sp (MEM_DECL n t s InternalMem) =
               let s' = render $ dispExpr Rightside s
                   t' = render $ dispExpr Rightside t in
                               unlines [ n++"_BRAM : infer_bram",
										"generic map (",
										"  ADDRESS_BITS => "++s'++",",
										"  DATA_BITS => "++t',
										")",
										"port map (",
										"  CLKA  => clock_sig,",
										"  ENA   => "++(readEnableSig n 0)++",",
										"  WEA   => "++(writeEnableSig n 0)++",",
										"  ADDRA => "++(addressSig n 0)++",",
										"  DIA   => "++(dataInSig n 0)++",",
										"  DOA   => "++(dataOutSig n 0)++",",
										"  CLKB  => clock_sig,",
										"  ENB   => "++(readEnableSig n 1)++",",
										"  WEB   => "++(writeEnableSig n 1)++",",
										"  ADDRB => "++(addressSig n 1)++",",
										"  DIB   => "++(dataInSig n 1)++",",
										"  DOB   => "++(dataOutSig n 1),
										");",
										""
										]

-- Function: genMemDefaults
-- Purpose: Generates a set of assignment statements to assign default values for each memory (BRAM signal)
genMemDefaults ss = concatMap sp ss
	where sp (MEM_DECL n t s ExternalMem) = unlines [
										"  "++(addressSig n 0)++" <= (others => '0');",
										"  "++(dataInSig n 0)++"  <= (others => '0');",
										"  "++(readEnableSig n 0)++" <= '0';",
										"  "++(writeEnableSig n 0)++" <= '0';",
										""
										] 
	      sp (MEM_DECL n t s InternalMem) = unlines [
										"  "++(addressSig n 0)++" <= (others => '0');",
										"  "++(dataInSig n 0)++"  <= (others => '0');",
										"  "++(readEnableSig n 0)++" <= '0';",
										"  "++(writeEnableSig n 0)++" <= '0';",
										"  "++(addressSig n 1)++" <= (others => '0');",
										"  "++(dataInSig n 1)++"  <= (others => '0');",
										"  "++(readEnableSig n 1)++" <= '0';",
										"  "++(writeEnableSig n 1)++" <= '0';",
										""
										] 

-- Function: genSigDefs
-- Purpose: Generate signal definition strings
genSigDefs ss = concatMap sp ss
  where sp (FSM_SIG n t) = (untype t)++" "++n++", "++ (nextify n)++";\n"

-- Function: genSyncSensitivity
-- Purpose: Generate sensitivity list for synchronous FSM process (only the FSM SIGs)
genSyncSensitivity ss = concatMap sp ss
  where sp (FSM_SIG n t) = "  "++(nextify n)++",\n"

-- Function: genCombSensitivity
-- Purpose: Generate sensitivity list for combinational FSM process (only the FSM SIGs)
genCombSensitivity ss = concatMap sp ss
  where sp (FSM_SIG n t) = "  "++n++",\n"

-- Function: genMemSensitivity
-- Purpose: Generate sensitivity list for combinational FSM process for memory (BRAM) signals
genMemSensitivity ss = concatMap sp ss
  where sp (MEM_DECL n t s InternalMem) = "  "++(dataOutSig n 0)++","++" "++(dataOutSig n 1)++",\n"
        sp (MEM_DECL n t s ExternalMem) = "  "++(dataOutSig n 0)++",\n"

-- Function: genPortSensitivity
-- Purpose: Generate sensitivity list for combinational FSM process for top-level input ports
genPortSensitivity ss = concatMap sp ss
  where sp (PORT_DECL n d t) = if (d == "in") then ("  "++n++",\n") else ""			
  

-- Function that generates C template of the FSM
-- *******************************************************
-- cs_name = Name of signal for current state
-- ns_name = Name of signal for next state
-- entity_name = Name of entity
-- ports = List of ports from Description AST
-- connections = List of connections from the Description AST
-- mems = List of mems from Description AST
-- transitions = List of transitions from Desription AST
-- initialState = String that represents the initial state to start at
-- signals = List of FSM signals from Description AST
-- vhdl = Big string of default C to insert before architecture begin
-- *******************************************************
c_template cs_name ns_name entity_name ports generics connections mems channels transitions initialState signals vhdl = 
  unlines [
	"// ************************************",
    "// Automatically Generated FSM",
    "// " ++  entity_name,
    "// ************************************",
    "",
	"#include <stdio.h>",
	"#include <mb_interface.h>",
    "",
    "// ************************************",
	"// Generics",
    "// ************************************",
	"",
	(genGenerics generics),
	"",
    "// ************************************",
	"// Ports",
    "// ************************************",
	"",
	 (genPorts ports),
    "// ************************************",
	"// Channels Identifiers",
    "// ************************************",
	 (genChannelIDs 0 channels),
	"",
    "// ************************************",
	"// Channels Definitions and Functions",
    "// ************************************",
	 (genChannelSigDefs channels),
    "// ************************************",
	"// State Enumeration",
    "// ************************************",
	"typedef enum",
	"{",
	(genStateEnum transitions),
	"} STATE_MACHINE_TYPE;",
	  "STATE_MACHINE_TYPE " ++  cs_name ++  ", " ++  ns_name ++ " = " ++  initialState ++  ";",
	"",
	 "// ****************************************************",
	 "// Definitions for FSM signals",
	 "// ****************************************************",
	(genSigDefs signals),
	(genMemorySigDefs mems),
	"",
	 "// ****************************************************",
	 "// Initialization/Finalization Functions",
	 "// ****************************************************",
	"void initialize_simulation(){",
	"}",
	"",
	"void finalize_simulation(){",
	"}",
	"",
	"int main()",
	"{",
	 "",
	 "      // Clock-cycle estimate",
	 "      int clockEstimate = 0;",
	 "      int stopSimulationNow = 0;",
	 "",
	"",
	"      initialize_simulation();",
	"",
	 "      // ****************************************************",
	 "      // Initialization for FSM signals",
	 "      // ****************************************************",
	(genSigResets signals),
	"",
	 "      // ****************************************************",
	"       // FSM Loop...",
	 "      // ****************************************************",
	"       while(stopSimulationNow == 0){",
	"",
	"          // ****************************************************",
	"          // Transition all state variables",
	"          // ****************************************************",
	"          // Transition the current state",
	"          "++ cs_name++" = "++ns_name++";",
	"",
	"          // Transition all signals",
	(genSigTrans signals),
	"",
	"          // ****************************************************",
	"          // FSM Body",
	"          // ****************************************************",
	"          //printf(\"Current state = %x\\n\","++cs_name++");",
	"          switch ("++cs_name++") {",
	genBody ns_name transitions,
	"            default :",
    "              "++ns_name++" = "++initialState++";",
    "              break;",
	"          }",
	 "",
	"       }",
	"      printf(\"\\n**** Simulation Halted! ****\\n\");",
	"      printf(\"\\nClock cycle estimate = %d cycles\\n\",clockEstimate);",
	"",
	"      finalize_simulation();",
	"",
	"      return 0;",
	"}",
	""
	]
