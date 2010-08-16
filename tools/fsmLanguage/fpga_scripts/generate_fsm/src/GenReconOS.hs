{--
GenReconOS.hs

This file contains all of the necessary functions to generate an executable  VHDL model of
an ReconOS FSM description
--}
module GenReconOS where
  
import LangAST

import Text.PrettyPrint
import Data.List(groupBy,sortBy,intersperse,nub,mapAccumL,find)
import Data.Maybe(catMaybes)
import ExpandMem(addressSig, readEnableSig, writeEnableSig, dataInSig, dataOutSig, getAllDependencies)
import ExpandChannels(elaborateChannelsBody, fullSig, existsSig, channelReadEnableSig, channelWriteEnableSig, channelInSig, channelOutSig)

-- Function used to "nextify" a string
nextify s = s

-- Transforms an expression into a VHDL string
--dispExpr (Mem_access m index p) = text m <> brackets (text index)
dispExpr (Mem_access m index p) = text m <> brackets (dispExpr index)
dispExpr (Var_access t) = text (unvar t)
dispExpr (Channel_access t) = text "#" <> text t
dispExpr (Channel_check_full t) = text (fullSig t)
dispExpr (Channel_check_exists t) = text (existsSig t)
dispExpr (Const_access a) = dispConst a
dispExpr (UnaryOp s a) = text s <+> (dispExpr a)
dispExpr (BinaryOp s a b) = (dispExpr a) <+> text s <+> (dispExpr b)
dispExpr (FuncApp s args) = (text s) <> parens (hcat (punctuate comma (map dispExpr args)))
dispExpr (ParensExpr e) = text "(" <+> (dispExpr e) <+> text ")"

-- Transforms an expression into a VHDL string
expr2string (Mem_access m index p) = text m <> (expr2string index)
expr2string (Var_access t) = text (unvar t)
expr2string (Channel_access t) = text "chan" <> text t
expr2string (Channel_check_full t) = text (fullSig t)
expr2string (Channel_check_exists t) = text (existsSig t)
expr2string (Const_access a) = const2string a
expr2string (UnaryOp s a) = text s <> (expr2string a)
expr2string (BinaryOp s a b) = (expr2string a) <> text s <> (expr2string b)
expr2string (FuncApp s args) = (text s) <> (hcat (punctuate (text "_") (map expr2string args)))
expr2string (ParensExpr e) = text "p_" <> (expr2string e) <> text "_p"

-- Transforms all the types of VHDL constants to a string for use in code generation
dispConst (V_integer i) = integer i
dispConst (V_tick c) = quotes (char c)
dispConst (V_binary_quote c) = doubleQuotes (text c)
dispConst (V_hex_quote c) = text "x" <> doubleQuotes (text c)
dispConst (V_hex_quote2 c) = text "X" <> doubleQuotes (text c)

const2string (V_integer i) = integer i
const2string (V_tick c) = (char c)
const2string (V_binary_quote c) = (text c)
const2string (V_hex_quote c) = text "x" <> (text c)


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
-- Purpose: Converts a VHDL type container into a string
untype (STLV s a b) =
    let a' = render $ dispExpr a
        b' = render $ dispExpr b in
             s++"("++a'++" to "++b'++")"
untype (STL s ) = s

-- Function: unvar
-- Purpose: Converts a VHDL var access into a string
--unvar (VarSelRange s a b) = s++"("++show a++" to "++show b++")"
--unvar (VarSelBit s a) = s++"("++show a++")"
--unvar (JustVar s ) = s

unvar (VarSelRange s a b) =
    let a' = render $ dispExpr a
        b' = render $ dispExpr b in
               s++"("++a'++" to "++b'++")"
unvar (VarSelBit s a) = 
    let a' = render $ dispExpr a in
              s++"("++a'++")"
unvar (JustVar "ALL_ZEROS") = "(others => '0')"
unvar (JustVar "ALL_ONES") = "(others => '1')"
unvar (JustVar s ) = s

-- Function: genSigResets
-- Purpose: Generates a set of assignment statements to reset all FSM sigs to zero(s)
genSigResets ss = concatMap sp ss
	where sp (FSM_SIG n t) = "\t\t"++n++(resetSig t)

-- Function: genSigTrans
-- Purpose: Generates a set of assignment statements to transition all FSM sigs to their next state
genSigTrans ss = concatMap sp ss
	where sp (FSM_SIG n t) = "\t\t"++n++" <= "++ (nextify n) ++";\n"

-- Function: genSigStay
-- Purpose: Generates a set of assignment statements to transition all FSM sigs to their same state
genSigStay ss = concatMap sp ss
	where sp (FSM_SIG n t) = "\t\t"++n++" <= "++ (n) ++";\n"

-- Function: genSigDefaults
-- Purpose: Generates a set of assignment statements to assign default values for each FSM signal
genSigDefaults ss = concatMap sp ss
	where sp (FSM_SIG n t) = "\t\t"++ (nextify n)++" <= "++n++";\n"

-- Function: resetSig
-- Purpose: Converts a VHDL type container into an assignment statement used during reset (assignment to zero)
resetSig (STLV s a b)	= " <= (others => '0');\n"
resetSig (STL "integer" ) = " <= 0;\n"
resetSig (STL "INTEGER" ) = " <= 0;\n"
resetSig (STL "Integer" ) = " <= 0;\n"
resetSig (STL s ) 		= " <= '0';\n"

-- Function: genBody
-- Purpose: Generates the body of the FSM (each "when" clause and it's associated transitions)
-- ns = next state signal
-- l = original list of transitions
genBody :: String -> [Node] -> String
genBody ns ts = render $ nest 8 $ vcat $ map (genState ns) groups
  where groups = groupBy grouping $ sortBy sorting ts
        sorting (TRANS_DECL s _ _ _) (TRANS_DECL s' _ _ _) = compare s s'
        grouping (TRANS_DECL s _ _ _) (TRANS_DECL s' _ _ _) = s == s'

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
  text "when" <+> text start <+> text "=>" $$
  nest 2 ((genSuperTrans start ns ts))

-- genTrans generates the signal assignments for a given transition 
genTrans ns (TRANS_DECL _ end NoGuard body) = 
  vcat (map genAssign body) $$
  text ns <+> text "<=" <+> text end <> text ";"
genTrans ns (TRANS_DECL _ end (Guard guard) body) = 
  text "if" <+> dispExpr guard <+> text "then" $$
  nest 2 ((vcat (map genAssign body)) $$
          text ns <+> text "<=" <+> text end <> text ";") $$
  text "end if;"

genVTrans ns (TRANS_DECL _ end NoGuard body) = 
  vcat (map genAssign body) $$
  text ns <+> text ":=" <+> text end <> text ";"
genVTrans ns (TRANS_DECL _ end (Guard guard) body) = 
  text "if" <+> dispExpr guard <+> text "then" $$
  nest 2 ((vcat (map genAssign body)) $$
          text ns <+> text ":=" <+> text end <> text ";") $$
  text "end if;"

unguardedCheck acc [] = acc
unguardedCheck acc ((TRANS_DECL _ _ g _):ts) =
   case g of
      NoGuard -> (unguardedCheck (acc+1) ts)
      _ -> (unguardedCheck acc ts)

genSuperTrans start ns ts =
 if ((unguardedCheck 0 ts) > 1)
    then
      error $ "Invalid FSM - state has more than one un-guarded transition! ("++start++")"
    else
      case ts of
           (a:[]) -> (genVTrans ns a)
           ts@(a:as) -> (genVIfElses ns 0 (sortBy sorting ts))
  -- Function used to make sure that "un-guarded transitions are always last
  where sorting (TRANS_DECL _ _ g1 _) (TRANS_DECL _ _ g2 _) =
            case g1 of
               NoGuard -> case g2 of
                       NoGuard -> EQ
                       _  -> GT
               _  -> EQ 

genIfElses ns acc [] = text "end if;" 
genIfElses ns acc ((TRANS_DECL _ end guard body):[]) =
 if acc == 0
    then
      text "if" <+> (checkGuard guard) <+> text "then" $$
      nest 2 ((vcat (map genAssign body)) $$
           text ns <+> text "<=" <+> text end <> text ";") $$
     (genIfElses ns (acc+1) [])
	else
      (prefixGuard guard) $$
      nest 2 ((vcat (map genAssign body)) $$
           text ns <+> text "<=" <+> text end <> text ";") $$
      (genIfElses ns (acc+1) [])

genIfElses ns acc ((TRANS_DECL _ end guard body):ts) =
 if acc == 0
    then
      text "if" <+> (checkGuard guard) <+> text "then" $$
      nest 2 ((vcat (map genAssign body)) $$
           text ns <+> text "<=" <+> text end <> text ";") $$
     (genIfElses ns (acc+1) ts)
	else
      text "elsif" <+> (checkGuard guard) <+> text "then" $$
      nest 2 ((vcat (map genAssign body)) $$
           text ns <+> text "<=" <+> text end <> text ";") $$
      (genIfElses ns (acc+1) ts)

genVIfElses ns acc [] = text "end if;" 
genVIfElses ns acc ((TRANS_DECL _ end guard body):[]) =
 if acc == 0
    then
      text "if" <+> (checkGuard guard) <+> text "then" $$
      nest 2 ((vcat (map genAssign body)) $$
           text ns <+> text ":=" <+> text end <> text ";") $$
     (genVIfElses ns (acc+1) [])
	else
      (prefixGuard guard) $$
      nest 2 ((vcat (map genAssign body)) $$
           text ns <+> text ":=" <+> text end <> text ";") $$
      (genVIfElses ns (acc+1) [])

genVIfElses ns acc ((TRANS_DECL _ end guard body):ts) =
 if acc == 0
    then
      text "if" <+> (checkGuard guard) <+> text "then" $$
      nest 2 ((vcat (map genAssign body)) $$
           text ns <+> text ":=" <+> text end <> text ";") $$
     (genVIfElses ns (acc+1) ts)
	else
      text "elsif" <+> (checkGuard guard) <+> text "then" $$
      nest 2 ((vcat (map genAssign body)) $$
           text ns <+> text ":=" <+> text end <> text ";") $$
      (genVIfElses ns (acc+1) ts)

checkGuard NoGuard = text "(true)"
checkGuard (Guard g) = dispExpr g

prefixGuard NoGuard = text "else"
prefixGuard x@(Guard g) = text "elsif" <+> (checkGuard x) <+> text "then"

-- genAssign generates the signal assignment for a statement
genAssign (Assign_stmt l r) = (dispExpr l) <+> text "<=" <+> (dispExpr r) <> text ";"
genAssign (VAssign_stmt l r) = (dispExpr l) <+> text ":=" <+> (dispExpr r) <> text ";"
genAssign (Func_stmt a) = (dispExpr a) <> text ";"

-- Function: genPorts
-- Purpose: Generates port definition strings
genPorts ps = concatMap gp ps
  where gp (PORT_DECL n d t) = "\t"++n++" : "++d++" "++(untype t)++";\n"

-- Function: genGenerics
-- Purpose: Generates generic definition strings
genGenerics [] = ""
--genGenerics ps = "generic(\n"++concatMap gp ps++"\n);"
genGenerics ps =
        "generic(\n"
        ++(concat $ intersperse ";\n" $ map gp ps)
        ++"\n);"
  where gp (GENERIC_DECL n t v) = "\t"++n++" : "++(untype t)++" := "++(render (dispConst v))

-- Function: genGenericMPD
genGenericMPD as = concatMap gg as
	where gg (GENERIC_DECL n t v) = "PARAMETER "++n++" = "++(render (dispConst v))++", DT = "++(untype t)++"\n"

memNameMPD n = n++"_PORT"
channelNameMasterMPD n = n++"_MASTER"
channelNameSlaveMPD n = n++"_SLAVE"

-- Function: genMemoryMPD
genMemoryMPD as = concatMap gg as
	where gg (MEM_DECL n t s InternalMem) = ""
	      gg (MEM_DECL n t s ExternalMem) = 
               let s' = render $ dispExpr s
                   t' = render $ dispExpr t in
				unlines [
						"BUS_INTERFACE BUS = "++(memNameMPD n)++", BUS_STD = XIL_BRAM, BUS_TYPE = INITIATOR",
						"PORT  "++(addressSig n 0)++" = BRAM_Addr, DIR = O, VEC=[0:("++s'++" - 1)], BUS = "++(memNameMPD n),
						"PORT  "++(dataInSig n 0)++" = BRAM_Dout, DIR = O, VEC=[0:("++t'++" - 1)], BUS = "++(memNameMPD n),
						"PORT  "++(dataOutSig n 0)++" = BRAM_Din, DIR = I, VEC=[0:("++t'++" - 1)], BUS = "++(memNameMPD n),
						"PORT  "++(readEnableSig n 0)++" = BRAM_En, DIR = O, BUS = "++(memNameMPD n),
						"PORT  "++(writeEnableSig n 0)++" = BRAM_WEN, DIR = O, BUS = "++(memNameMPD n),
						""
						]

-- Function : genChannelMPD
genChannelMPD as = concatMap gg as
	where gg (CHANNEL_DECL n e) = 
               let e' = render $ dispExpr e in
				unlines	[
						"BUS_INTERFACE BUS = "++(channelNameMasterMPD n)++", BUS_STD = FSL, BUS_TYPE = MASTER",
						"BUS_INTERFACE BUS = "++(channelNameSlaveMPD n)++", BUS_STD = FSL, BUS_TYPE = SLAVE",
						"PORT "++(channelInSig n)++" = FSL_M_Data, DIR = O, VEC=[0:("++e'++" - 1)], BUS = "++(channelNameMasterMPD n),
						"PORT "++(channelOutSig n)++" = FSL_S_Data, DIR = I, VEC=[0:("++e'++" - 1)], BUS = "++(channelNameSlaveMPD n),
						"PORT "++(existsSig n)++" = FSL_S_Exists, DIR = I, BUS = "++(channelNameSlaveMPD n),
						"PORT "++(fullSig n)++" = FSL_M_Full, DIR = I, BUS = "++(channelNameMasterMPD n),
						"PORT "++(channelReadEnableSig n)++" = FSL_S_Read, DIR = O, BUS = "++(channelNameSlaveMPD n),
						"PORT "++(channelWriteEnableSig n)++" = FSL_M_Write, DIR = O, BUS = "++(channelNameMasterMPD n),
						"\t"
						]
 

-- Function : genPortMPD
genPortMPD as = concatMap gg as
	where gg (PORT_DECL n d t) = "PORT "++n++" = \"\", DIR = "++(genDirMPD d)++" "++(genTypeMPD t)++"\n"

genDirMPD d = d
genTypeMPD (STL s) = ""
genTypeMPD (STLV s a b) = 
    let a' = render $ dispExpr a
        b' = render $ dispExpr b in
			", VEC = ["++a'++":"++b'++"]"


genMemPorts ms = concatMap f ms
	where f (MEM_DECL n t s InternalMem) = ""
	      f (MEM_DECL "local_ram" t s ExternalMem)  = ""
	      f (MEM_DECL n t s ExternalMem)  =
               let s' = render $ dispExpr s
                   t' = render $ dispExpr t in
				unlines	[
						"\t"++(addressSig n 0)++" : out std_logic_vector(0 to ("++s'++" - 1));",
						"\t"++(dataInSig n 0)++" : out std_logic_vector(0 to ("++t'++" - 1));",
						"\t"++(dataOutSig n 0)++" : in std_logic_vector(0 to ("++t'++" - 1));",
						"\t"++(readEnableSig n 0)++" : out std_logic;",
						"\t"++(writeEnableSig n 0)++" : out std_logic;"
						]
genChannelPorts ms = concatMap f ms
	where f (CHANNEL_DECL n e)  =
               let e' = render $ dispExpr e in
				unlines	[
						"\t"++(channelInSig n)++" : out std_logic_vector(0 to ("++e'++" - 1));",
						"\t"++(channelOutSig n)++" : in std_logic_vector(0 to ("++e'++" - 1));",
						"\t"++(existsSig n)++" : in std_logic;",
						"\t"++(fullSig n)++" : in std_logic;",
						"\t"++(channelReadEnableSig n)++" : out std_logic;",
						"\t"++(channelWriteEnableSig n)++" : out std_logic;"
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
  where sp (MEM_DECL n t s ExternalMem) = ""
        sp (MEM_DECL n t s InternalMem) =
               let s' = render $ dispExpr s
                   t' = render $ dispExpr t in
                                 unlines [ "-- **************************",
										"-- BRAM Signals for "++n,
										"-- **************************",
										"signal "++(addressSig n 0)++" : std_logic_vector(0 to ("++s'++" - 1));",
										"signal "++(dataInSig n 0)++" : std_logic_vector(0 to ("++t'++" - 1));",
										"signal "++(dataOutSig n 0)++" : std_logic_vector(0 to ("++t'++" - 1));",
										"signal "++(readEnableSig n 0)++" : std_logic;",
										"signal "++(writeEnableSig n 0)++" : std_logic;",
										"signal "++(addressSig n 1)++" : std_logic_vector(0 to ("++s'++" - 1));",
										"signal "++(dataInSig n 1)++" : std_logic_vector(0 to ("++t'++" - 1));",
										"signal "++(dataOutSig n 1)++" : std_logic_vector(0 to ("++t'++" - 1));",
										"signal "++(readEnableSig n 1)++" : std_logic;",
										"signal "++(writeEnableSig n 1)++" : std_logic;",
										""
									]

-- Function: genMemoryInstantiations
-- Purpose: Generate instantiations for each individual BRAM
genMemoryInstantiations ss = concatMap sp ss
  where  sp (MEM_DECL n t s ExternalMem) = ""
         sp (MEM_DECL n t s InternalMem) =
               let s' = render $ dispExpr s
                   t' = render $ dispExpr t in
                               unlines [ n++"_BRAM : infer_bram",
										"generic map (",
										"  ADDRESS_BITS => "++s'++",",
										"  DATA_BITS => "++t',
										")",
										"port map (",
										"  CLKA  => clk,",
										"  ENA   => "++(readEnableSig n 0)++",",
										"  WEA   => "++(writeEnableSig n 0)++",",
										"  ADDRA => "++(addressSig n 0)++",",
										"  DIA   => "++(dataInSig n 0)++",",
										"  DOA   => "++(dataOutSig n 0)++",",
										"  CLKB  => clk,",
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
										"\t"++(addressSig n 0)++" <= (others => '0');",
										"\t"++(dataInSig n 0)++"  <= (others => '0');",
										"\t"++(readEnableSig n 0)++" <= '0';",
										"\t"++(writeEnableSig n 0)++" <= '0';",
										"\t"
										] 
	      sp (MEM_DECL n t s InternalMem) = unlines [
										"\t"++(addressSig n 0)++" <= (others => '0');",
										"\t"++(dataInSig n 0)++"  <= (others => '0');",
										"\t"++(readEnableSig n 0)++" <= '0';",
										"\t"++(writeEnableSig n 0)++" <= '0';",
										"\t"++(addressSig n 1)++" <= (others => '0');",
										"\t"++(dataInSig n 1)++"  <= (others => '0');",
										"\t"++(readEnableSig n 1)++" <= '0';",
										"\t"++(writeEnableSig n 1)++" <= '0';",
										""
										] 

-- Function: genChannelDefaults
-- Purpose: Generates a set of assignment statements to assign default values for each channel
genChannelDefaults ss = concatMap sp ss
	where sp (CHANNEL_DECL n _) = unlines [
										"\t"++(channelInSig n)++" <= (others => '0');",
										"\t"++(channelReadEnableSig n)++" <= '0';",
										"\t"++(channelWriteEnableSig n)++" <= '0';",
										""
										] 

-- Function: genSigDefs
-- Purpose: Generate signal definition strings
genSigDefs ss = concatMap sp ss
  where sp (FSM_SIG n t) = "signal "++n++" : "++(untype t)++";\n"

-- Function: genVarDefs
-- Purpose: Generate variable definition strings
genVarDefs ss = concatMap sp ss
  where sp (VAR_DECL n t) = "\t\t"++"variable "++n++" : "++(untype t)++";\n"

-- Function: genSyncSensitivity
-- Purpose: Generate sensitivity list for synchronous FSM process (only the FSM SIGs)
genSyncSensitivity ss = concatMap sp ss
  where sp (FSM_SIG n t) = "\t\t"++(nextify n)++",\n"

-- Function: genCombSensitivity
-- Purpose: Generate sensitivity list for combinational FSM process (only the FSM SIGs)
genCombSensitivity ss = concatMap sp ss
  where sp (FSM_SIG n t) = "\t\t"++n++",\n"

-- Function: genMemSensitivity
-- Purpose: Generate sensitivity list for combinational FSM process for memory (BRAM) signals
genMemSensitivity ss = concatMap sp ss
  where sp (MEM_DECL n t s InternalMem) = "\t\t"++(dataOutSig n 0)++","++" "++(dataOutSig n 1)++",\n"
        sp (MEM_DECL n t s ExternalMem) = "\t\t"++(dataOutSig n 0)++",\n"

-- Function: genChannelSensitivity
-- Purpose: Generate sensitivity list for combinational FSM process for channel (FSL) signals
genChannelSensitivity ss = concatMap sp ss
  where sp (CHANNEL_DECL n _) = "\t\t"++(channelOutSig n)++", "++(fullSig n)++", "++(existsSig n)++",\n"

-- Function: genPortSensitivity
-- Purpose: Generate sensitivity list for combinational FSM process for top-level input ports
genPortSensitivity ss = concatMap sp ss
  where sp (PORT_DECL n d t) = if (d == "in") then ("\t"++n++",\n") else ""			
 
-- Function that generates an MPD template of the FSM
mpd_template entity_name ports generics mems channels = 
  unlines	[
			"BEGIN "++entity_name,
			"",
			"## Peripheral Options",
			"OPTION IPTYPE = PERIPHERAL",
			"OPTION IMP_NETLIST = TRUE",
			"OPTION HDL = verilog",
			"OPTION USAGE_LEVEL = BASE_USER",
			"OPTION STYLE = MIX",
			"##OPTION CORE_STATE = DEVELOPMENT",
			"",
			"## Generics:",
			(genGenericMPD generics),
			"",
			"## Memory Interfaces:",
			(genMemoryMPD mems),
			"",
			"## Channel Interfaces:",
			(genChannelMPD channels),
			"",
			"## Ports:",
			"PORT clock_sig = \"\", DIR = IN, SIGIS = CLK",
			"PORT reset_sig = \"\", DIR = IN, SIGIS = Rst",
			(genPortMPD ports),
			""
			]

-- Function that generates VHDL template of the FSM
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
-- signals = List of FSM variables from Description AST
-- vhdl = Big string of default VHDL to insert before architecture begin
-- *******************************************************
template ver cs_name ns_name entity_name ports generics connections mems channels transitions initialState signals variables vhdl = 
  unlines [
	  "-- ************************************",
    "-- Automatically Generated ReconOS FSM",
    "-- " ++  entity_name,
     "-- ************************************",
    "",
    "-- **********************",
    "-- Library inclusions",
    "-- **********************",
    "library ieee;",
    "use ieee.std_logic_1164.all;",
    "use ieee.numeric_std.all;",
    "use ieee.std_logic_unsigned.all;", 
    "",
    "library reconos_" ++ ver ++ ";",
    "use reconos_" ++ ver ++ ".reconos_pkg.all;",
    "",
    "-- **********************",
    "-- Entity Definition",
    "-- **********************",
   "entity " ++  entity_name ++ " is",
	(genGenerics generics),
    "generic",
         "(",
	 "\t" ++ "C_TASK_BURST_AWIDTH : integer := 11;",
         "\t" ++ "C_TASK_BURST_DWIDTH : integer := 32",
         ");",
    "port",
    "(",
	 (genMemPorts mems),
	 (genChannelPorts channels),
	 (genPorts ports),
	 "\t" ++ "clk       : in  std_logic;",
	 "\t" ++ "reset     : in  std_logic;",
	 "\t" ++ "i_osif    : in  osif_os2task_t;",
	 "\t" ++ "o_osif    : out osif_task2os_t;",
         "",
	 "\t" ++ "-- burst ram interface",
	 "\t" ++ "o_RAMAddr : out std_logic_vector( 0 to C_TASK_BURST_AWIDTH-1 );",
	 "\t" ++ "o_RAMData : out std_logic_vector( 0 to C_TASK_BURST_DWIDTH-1 );",
	 "\t" ++ "i_RAMData : in  std_logic_vector( 0 to C_TASK_BURST_DWIDTH-1 );",
	 "\t" ++ "o_RAMWE   : out std_logic;",
	 "\t" ++ "o_RAMClk  : out std_logic",
	 "\t" ++ ");",
	  "end entity " ++  entity_name ++  ";",
	  "",
	  "-- *************************",
	  "-- Architecture Definition",
	  "-- *************************",
	  "architecture Behavioral of " ++  entity_name ++  " is",
	  "",
	  "\tattribute keep_hierarchy : string;",
	  "\tattribute keep_hierarchy of Behavioral: architecture is \"true\";",
	  "",
	  "-- ****************************************************",
	  "-- Type definitions for state signals",
	  "-- ****************************************************",
	  "type STATE_MACHINE_TYPE is",
	  "( ",
	 (genStateEnum transitions),
	  ");",
	  "signal " ++  cs_name ++ ": STATE_MACHINE_TYPE := " ++  initialState ++  ";",
	  "signal o_RAMRE : std_logic := '0';",
	 "",
	 "-- ****************************************************",
	 "-- Type definitions for FSM signals",
	 "-- ****************************************************",
	(genSigDefs signals),
	(genMemorySigDefs mems),
	 "-- ****************************************************",
	"-- User-defined VHDL Section",
	 "-- ****************************************************",
	(vhdl),
	"-- Architecture Section",
	"begin",
	"",
        "\to_RAMClk <= clk;", 
	"",
	"-- ************************",
	"-- Permanent Connections",
	"-- ************************",
	(genPermanentConnections connections),
	"",
	"-- ************************",
	"-- BRAM implementations",
	"-- ************************",
	(genMemoryInstantiations mems),
	"-- ****************************************************",
	"-- Process to handle the synchronous portion of an FSM",
	"-- ****************************************************",
	"RECONOS_FSM_SYNC_PROCESS : process(",
	"\tclk, reset) is",
	"\t-- done for Reconos methods",
	"\tvariable done : boolean;",
	"\t-- success for Reconos methods",
	"\tvariable success : boolean;",
	"\t-- next state",
	"\tvariable " ++ ns_name ++ " : STATE_MACHINE_TYPE := " ++ initialState ++ ";",
 	"\t-- **********************",
	"\t-- Variable Definitions",
	"\t-- **********************",
        (genVarDefs variables),
	"begin",
        "",         
        "\tif (reset = '1') then",
	(genSigResets signals),
        "\t\to_RAMAddr <= (others=>'0');",
        "\t\to_RAMData <= (others=>'0');",
        "\t\to_RAMWE   <= '0';",
        "\t\treconos_reset( o_osif, i_osif );",
	"\t\t"++cs_name++" <= "++initialState++";",
        "\t\t" ++ ns_name ++ " := " ++ initialState ++ ";",
        "\t\tdone := false;",
	"\telsif (rising_edge(clk)) then",
        "",
        "\t\to_RAMWE <= '0';",
        "",
        "\t\treconos_begin( o_osif, i_osif );",
	"\t\tif (reconos_ready( i_osif )) then",
	"\t\t-- Transition to next state",
	"\t\tcase ("++cs_name++") is",
	"",
	genBody ns_name transitions,
	"\t\twhen others => ",
	"\t\t\t"++ns_name++" := "++initialState++";",
	"",
	"\t\t\tend case;",
	"\t\t\tif done then",
	"\t\t\t\t" ++ cs_name ++ " <= " ++ ns_name ++ ";",
	"\t\t\tend if;",
	"\t\tend if;",
	"\tend if;",
	"end process RECONOS_FSM_SYNC_PROCESS;",
	"",
	"end architecture Behavioral;",
	""
	]

