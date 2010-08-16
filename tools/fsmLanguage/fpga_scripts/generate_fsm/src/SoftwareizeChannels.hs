{--
SoftwareizeChannels.hs

This file contains all of the functionality to elaborate channel reads/writes into
a set of software-based channel accesses
--}

module SoftwareizeChannels(elaborateChannelsBody_sw, channelFullSig, channelExistsSig, channelReadEnableSig, channelWriteEnableSig, channelInSig, channelOutSig, channelJunkSig, channelAccessFunction, channelID) where
  
import LangAST
import Data.List(nub,delete,mapAccumL,findIndex,find)
import qualified Data.Map as Map 

-- Elaboration function for a list of TRANS_DECLs
--	Iteratively executes elaborateTrans in order to pass state of count
elaborateChannelsBody_sw count channels ts = (count', concat ts') 
  where (count', ts') = mapAccumL (elaborateTrans channels) count ts

-- Function that returns the intermediate state name string
intermediateName = "extra"
			
-- Function used to generate a list of extra VHDL state names
extraStateNames 0 = []
extraStateNames i = (genName intermediateName i)++",\n"++(extraStateNames (i-1)) 

-- Elaboration function for a TRANS_DECL that will generate a list of TRANS_DECLS
elaborateTrans channels count x@(TRANS_DECL start end guard body)  =
 let (writeChannels, readChannels) = extractUsedChannels start body in
	  let chk = checkChannelWrites channels start body in
		case chk of
			True ->
				if not (areThereChannelReads body) 
					then
						case writeChannels of
							[] -> (count, [(TRANS_DECL start end guard body)])	-- No writes or reads
							_  ->
									-- If only writes then...
									(count,
									   [--(TRANS_DECL start start (guardifyWriteStay writeChannels guard) []),
									   --(TRANS_DECL start end (guardifyWriteComplete writeChannels guard) (initiateWrites body))
									   (TRANS_DECL start end (guard) (initiateWrites body))
										])
					else
							-- If only reads then...
									(count,
									   [--(TRANS_DECL start start (guardifyReadStay readChannels guard) []),
									   --(TRANS_DECL start end (guardifyReadComplete readChannels guard) (initiateReads start channels body))
									   (TRANS_DECL start end (guard) (initiateReads start channels body))
										])
			False -> error $ "A given channel can only be written to once per state!\n Error in state:\n"++start

constructGuards rule [] = (Const_access $ V_tick '1')
constructGuards rule (c:[]) = rule c
constructGuards rule (c:cs) = (BinaryOp "and" (rule c) (constructGuards rule cs))

guardifyWriteStay wc (NoGuard) = (Guard (constructGuards writeGuardStay wc))
guardifyWriteStay wc (Guard g) = (Guard (BinaryOp "and" g (constructGuards writeGuardStay wc)))
writeGuardStay (Channel_access wc) = (BinaryOp "/=" (Var_access $ JustVar (channelFullSig wc)) (Const_access $ V_tick '0'))

guardifyWriteComplete wc (NoGuard) = (Guard (constructGuards writeGuardComplete wc))
guardifyWriteComplete wc (Guard g) = (Guard (BinaryOp "and" g (constructGuards writeGuardComplete wc)))
writeGuardComplete (Channel_access wc) = (BinaryOp "=" (Var_access $ JustVar (channelFullSig wc)) (Const_access $ V_tick '0'))

guardifyReadStay wc (NoGuard) = (Guard (constructGuards readGuardStay wc))
guardifyReadStay wc (Guard g) = (Guard (BinaryOp "and" g (constructGuards readGuardStay wc)))
readGuardStay (Channel_access wc) = (BinaryOp "=" (Var_access $ JustVar (channelExistsSig wc)) (Const_access $ V_tick '0'))

guardifyReadComplete wc (NoGuard) = (Guard (constructGuards readGuardComplete wc))
guardifyReadComplete wc (Guard g) = (Guard (BinaryOp "and" g (constructGuards readGuardComplete wc)))
readGuardComplete (Channel_access wc) = (BinaryOp "/=" (Var_access $ JustVar (channelExistsSig wc)) (Const_access $ V_tick '0'))


-- State name generation function
genName s i = (s ++ (show i))

extractUsedChannels sName as =
  let ls = (getListDependenciesLHS as) in
      let rs = (getListDependenciesRHS as) in
			let res = (ls,rs) in
				case ls of
					[] -> res
					_  -> case rs of
							[] -> res
							_  -> error ("A state can have either channel reads or channel writes, but not both\n Error in state "++sName)

checkChannelWrites channels sName as =
  let  ds = (getDependenciesLHS as)
       md = and (map (checkPorts channels) ds) in
			if (not md)
				then False
				else True

-- Takes a list of assignment statements and generates a list of assignment statements that initiate all read requests
initiateReads sName channels as =
    let ds = (getAllDependencies as)
        md = and (map (checkPorts channels) ds) in
          if (not md)
              then error $ "A channel can only be read once per state!\n Error in state "++sName
              else (concatMap genReadStatements as)

-- Function used to check the legality of memory accesses
--	* Makes sure that ExternalChannels are only accessed at most once per state
--	* Makes sure that InternalChannels are only accessed at most twice per state
checkPorts channels (n,accesses) = case find helper channels of
                                  Just (CHANNEL_DECL  _ _) -> length accesses <= 1 
                                  Nothing -> error ("Channel "++n++" is not properly declared before use")-- False
  where helper (CHANNEL_DECL n' _) = n' == n




-- Takes a list of assignment statements and generates a list of assignment statements with all write requests elaborated
initiateWrites as = (concatMap genWriteStatements as)

-- Elaborates an assignment statement
--	Writes to variables are left unchanged
--	Writes to memory are elaborated
genWriteStatements (Assign_stmt l@(Channel_access n) r) =
	[
	Assign_stmt (Var_access (JustVar (channelInSig n))) r,
	Assign_stmt (Var_access (JustVar (channelWriteEnableSig n))) (Const_access (V_tick '1')),
	Assign_stmt (Var_access (JustVar (channelJunkSig n))) (FuncApp (channelAccessFunction n) [])
	] 
genWriteStatements (Assign_stmt l r) = [(Assign_stmt l r)] 

genReadStatements (Assign_stmt l r@(Channel_access n)) =
	[
	Assign_stmt (Var_access (JustVar (channelReadEnableSig n))) (Const_access (V_tick '1')),
	Assign_stmt l (FuncApp (channelAccessFunction n) [])
	] 
genReadStatements (Assign_stmt l r) = [(Assign_stmt l r)] 



-- Functions that generate the names of channel signals
channelFullSig n = n++"_full"
channelExistsSig n = n++"_exists"
channelReadEnableSig n = n++"_channelRead"
channelWriteEnableSig n = n++"_channelWrite"
channelInSig n = n++"_channelDataIn"
channelOutSig n  = n++"_channelDataOut"
channelJunkSig n  = n++"_channelJunkSig"
channelAccessFunction n  = "_channelAccessFunction_"++n
channelID n  = "_channelID_"++n

-- Boolean function to check if an assignment statement is a BRAM write 
isChannelWrite (Assign_stmt (Mem_access m i p) _) = True
isChannelWrite _ = False

-- Boolean function to check if an assingment statement is a BRAM read
isChannelRead (Assign_stmt l r) = let ms = (getChannelAccesses r) in if (ms == []) then False else True

-- Boolean function to check if a list of assignment statements has any BRAM reads in it
areThereChannelReads [] = False
areThereChannelReads (a:as) = let s = (isChannelRead a) in if (s == True) then True else areThereChannelReads as

-- Calculates the max depth of the memory dependency structure
getMaxDepth max [] = max
getMaxDepth max ((a,b):ms) =
  let cl = length b in
    if (cl > max) then (getMaxDepth cl ms) else (getMaxDepth max ms)

-- Returns the a list of every RHS of a list of statements
grabEveryRHS []     = []
grabEveryRHS (a:as) = (getRHS a):(grabEveryRHS as)

-- Returns the a list of every LHS of a list of statements
grabEveryLHS []     = []
grabEveryLHS (a:as) = (getLHS a):(grabEveryLHS as)

-- Returns a list of every mem access within a list of expressions
grabAllChannelAccesses [] = []
grabAllChannelAccesses (a:as) = (getChannelAccesses a)++(grabAllChannelAccesses as)

-- Helper functions to assist in displaying the memory dependencies of statements
getRHS (Assign_stmt a b) = b
getLHS (Assign_stmt a b) = a
dispDependencies x = unlines (map show x)

-- Function used to retrieve all memory dependencies for a group of statements
--getAllDependencies ss = let allr = (grabEveryRHS ss) in genChannelDependencies [] (nub (grabAllChannelAccesses allr))
getAllDependencies ss = let allr = (grabEveryRHS ss) in genChannelDependencies [] ((grabAllChannelAccesses allr))

-- Function used to retrieve all memory dependencies for a group of statements (both LHS and RHS)
getChannelDependencies_LHS_and_RHS ss =
  let allr = (grabEveryRHS ss)
      alll = (grabEveryLHS ss) in genChannelDependencies [] (nub (grabAllChannelAccesses (allr++alll)))
	
-- Function used to retrieve all memory dependencies on the LHS of a set of assignment statements (nub is not used b/c all accesses matter, not just unique ones)
getDependenciesLHS ss = let all = (grabEveryLHS ss) in genChannelDependencies [] (grabAllChannelAccesses all)

getListDependenciesLHS ss = let all = (grabEveryLHS ss) in (grabAllChannelAccesses all)
getListDependenciesRHS ss = let all = (grabEveryRHS ss) in (grabAllChannelAccesses all)

-- Takes a list of memory accesses and returns an association list
-- which is a list of tuples in which each tuple consists of a...
-- 1st element - channel name
-- 2nd element - list of channel accesses from this memory
genChannelDependencies acc [] = acc
genChannelDependencies acc (x@(Channel_access n):as) =
	case (lookup n acc) of
		Just xs -> let acc' = (delete (n,xs) acc) in
				let newEl = (n,(x:xs)) in
					let acc'' = newEl:acc' in
						(genChannelDependencies acc'' as)
		Nothing -> let acc' = ((n,[x]):acc) in 
						(genChannelDependencies acc' as)

-- Visits an expression and returns all memory accesses in sub-expressions
getChannelAccesses (Mem_access n i p) = (getChannelAccesses i)
getChannelAccesses (Var_access _) = []
getChannelAccesses x@(Channel_access _) = [x]
getChannelAccesses (Const_access _) = []
getChannelAccesses (BinaryOp _ a b) = ((getChannelAccesses a)++(getChannelAccesses b)) 
getChannelAccesses (UnaryOp _ a) = (getChannelAccesses a)
getChannelAccesses (ParensExpr a) = (getChannelAccesses a)
getChannelAccesses (FuncApp s args) = (concatMap getChannelAccesses args)
		

