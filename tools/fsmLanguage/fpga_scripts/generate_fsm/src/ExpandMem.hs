{--
ExpandMem.hs

This file contains all of the functionality to elaborate memory reads/writes into
a set of sequential assignment statements
--}

module ExpandMem(getAllDependencies, expandMem,elaborateBody, addressSig, readEnableSig, writeEnableSig, dataInSig, dataOutSig) where
  
import LangAST

import Data.List(nub,delete,mapAccumL,findIndex,find)
import qualified Data.Map as Map
  
expandMem :: Description -> Description
expandMem des = undefined  
  

-- Elaboration function for a list of TRANS_DECLs
--	Iteratively executes elaborateTrans in order to pass state of count
elaborateBody count mems ts = (count', concat ts') 
  where (count', ts') = mapAccumL (elaborateTrans mems) count ts

-- Function that returns the intermediate state name string
intermediateName = "_mem_extra"
			
-- Function used to generate a list of extra VHDL state names
extraStateNames 0 = []
extraStateNames i = (genName intermediateName i)++",\n"++(extraStateNames (i-1)) 

-- Elaboration function for a TRANS_DECL that will generate a list of TRANS_DECLS
elaborateTrans mems count x@(TRANS_DECL start end guard body)  =
  let chk = checkBramWrites mems start body in
	case chk of
		True ->
			if not (areThereBramReads body)
				then
					-- If no BRAM reads, then the TRANS_DECL just requires writes to be elaborated
					(count,[TRANS_DECL start end guard (initiateWrites body)])
				else
					-- First set all port numbers for memory accesses
					--let body' = (setPortNumbers [] (getAllDependencies body) body) in
					let body' = (setPortNumbers [] (getMemDependencies_LHS_and_RHS body) body) in
						-- If there are BRAM reads, then intermediate TRANS_DECLs must be generated and then writes are elaborated
						(count+2
						,[TRANS_DECL start ((start)++(genName intermediateName (count+1))) guard (initiateReads start mems body'),
						  TRANS_DECL ((start)++(genName intermediateName (count+1))) ((start)++(genName intermediateName (count+2))) NoGuard [],
					  	TRANS_DECL ((start)++(genName intermediateName (count+2))) end NoGuard (initiateWrites (finalizeMemAssignments Map.empty body'))
						])
		False -> error $ "An internal memory can only be updated twice per state, and and external memory only once per state!\n Error in state:\n"++start

-- State name generation function
genName s i = (s ++ (show i))

-- Check's to make sure that each BRAM is only updated at most once per state
{-checkBramWrites sName as =
	let md = getMaxDepth 0 (getDependenciesLHS as) in
			if (md > 1)
				then False
				else True
-}
checkBramWrites mems sName as =
  let  ds = (getDependenciesLHS as)
       md = and (map (checkPorts mems) ds) in
			if (not md)
				then False
				else True

-- Takes a list of assignment statements and generates a list of assignment statements that initiate all read requests
initiateReads sName mems as =
    let ds = (getAllDependencies as)
        md = and (map (checkPorts mems) ds) in
          if (not md)
              then error $ "An internal memory can only be referenced twice per state, and and external memory only once per state!\n Error in state "++sName
              else (concatMap (genInitialReadStmts []) ds)


-- Function used to check the legality of memory accesses
--	* Makes sure that ExternalMems are only accessed at most once per state
--	* Makes sure that InternalMems are only accessed at most twice per state
checkPorts mems (n,accesses) = case find helper mems of
                                  Just (MEM_DECL  _ _ _ InternalMem) -> length accesses <= 2 
                                  Just (MEM_DECL  _ _ _ ExternalMem) -> length accesses <= 1
                                  Nothing -> error ("Memory "++n++" is not properly declared before use")-- False
  where helper (MEM_DECL n' _ _ _ ) = n' == n

-- Assigns port numbers to all memory accesses in a list of assignments
{-setPortNumbers acc ds [] = acc 
setPortNumbers acc ds ((Assign_stmt l r):as) = let r' = (assignPortNumber ds r) in
														 let acc' = ((Assign_stmt l r'):acc) in
																setPortNumbers acc' ds as
-}
setPortNumbers acc ds [] = acc 
setPortNumbers acc ds ((Func_stmt e):as) =
   let e'   = (assignPortNumber ds e)  
       acc' = ((Func_stmt e'):acc) in
           setPortNumbers acc' ds as
setPortNumbers acc ds ((Assign_stmt l r):as) =
   let r'   = (assignPortNumber ds r) 
       l'   = (assignPortNumber ds l) 
       acc' = ((Assign_stmt l' r'):acc) in
           setPortNumbers acc' ds as
setPortNumbers acc ds ((VAssign_stmt l r):as) =
   let r'   = (assignPortNumber ds r) 
       l'   = (assignPortNumber ds l) 
       acc' = ((VAssign_stmt l' r'):acc) in
           setPortNumbers acc' ds as

-- Takes an expression and the dependency structure and calculates the port number any memory accesses within it
assignPortNumber ds ma@(Mem_access n i p) =
	let v = lookup n ds in
		case v of
			Nothing -> error "Memory access not found!"
			Just x  -> let iM = (findIndex (==ma) x) in
							case iM of
								Nothing -> error "Memory access index not found!"
								Just y  -> (Mem_access n i y) 
assignPortNumber ds x@(Var_access t) = x
assignPortNumber ds x@(Channel_access t) = x
assignPortNumber ds x@(Const_access t) = x
assignPortNumber ds x@(UnaryOp s t) = (UnaryOp s (assignPortNumber ds t))
assignPortNumber ds x@(BinaryOp s a b) = (BinaryOp s (assignPortNumber ds a) (assignPortNumber ds b))
assignPortNumber ds x@(FuncApp s args) = (FuncApp s (map (assignPortNumber ds) args))
assignPortNumber ds x@(ParensExpr e) = (ParensExpr (assignPortNumber ds e))

-- Takes a list of assignment statements and generates a list of assignment statements with all write requests elaborated
initiateWrites as = (concatMap genWriteStatements as)

-- Takes a list of statements and generates a list of assignment statements with all reads dereferenced
-- finalizeMemAssignments :: [Stmt] -> [Stmt]
finalizeMemAssignments acc as = snd $ mapAccumL derefMems acc as
              

-- Dereferences the RHS of as assignment statement
derefMems acc (Assign_stmt l r) = let (acc', r') = derefMemAccesses acc r
                                  in (acc', Assign_stmt l r') 
derefMems acc (VAssign_stmt l r) = let (acc', r') = derefMemAccesses acc r
                                  in (acc', VAssign_stmt l r') 
derefMems acc (Func_stmt e) = let (acc', e') = derefMemAccesses acc e
                                  in (acc', Func_stmt e') 
-- Dereferences all memory accesses within an expression
derefMemAccesses acc (Mem_access m index p)	= 
    (acc', (Var_access (JustVar (dataOutSig m p {- ++ (show dout_num) -}))))
  where dout_num = Map.findWithDefault 0 m acc
        acc' = Map.insertWith (+) m 1 acc
        
derefMemAccesses acc x@(Var_access t)		= (acc,x)
derefMemAccesses acc x@(Channel_access t)		= (acc,x)
derefMemAccesses acc x@(Const_access a)		= (acc,x)
derefMemAccesses acc (UnaryOp s a)			= let (acc',a') = derefMemAccesses acc a
                                          in (acc', (UnaryOp s a'))

derefMemAccesses acc (ParensExpr a)	 = let (acc',a') = derefMemAccesses acc a
                                          in (acc', (ParensExpr a'))
                                          
derefMemAccesses acc (BinaryOp s a b)	= 
  let (acc' , a') = derefMemAccesses acc a
      (acc'' , b') = derefMemAccesses acc' b
  in (acc'', BinaryOp s a' b')

derefMemAccesses acc x@(FuncApp s args) = let (acc', args') = mapAccumL derefMemAccesses acc args
                                          in (acc', FuncApp s args')

-- Elaborates an assignment statement
--	Writes to variables are left unchanged
--	Writes to memory are elaborated
genWriteStatements (Assign_stmt l@(Mem_access m i p) r) =
	[
	Assign_stmt (Var_access (JustVar (addressSig m p))) i,--(Var_access (JustVar i)),
	Assign_stmt (Var_access (JustVar (dataInSig m p))) r,
	Assign_stmt (Var_access (JustVar (writeEnableSig m p))) (Const_access (V_tick '1')),
	Assign_stmt (Var_access (JustVar (readEnableSig m p))) (Const_access (V_tick '1'))
	] 
genWriteStatements (Assign_stmt l r) = [(Assign_stmt l r)]
genWriteStatements x = [x]

-- Generates a set of assignment statements used to pre-fetch data for a memory dependency list
genInitialReadStmts acc (n,[]) = acc 
genInitialReadStmts acc (n,((Mem_access m i p):as)) =
	let acc' = 
		[
		Assign_stmt (Var_access (JustVar (addressSig m p))) i, --(Var_access (JustVar i)),
		Assign_stmt (Var_access (JustVar (readEnableSig m p))) (Const_access (V_tick '1'))
		]
		++acc in
				genInitialReadStmts acc' (n,as) 

-- Functions that generate the names of memory signals
addressSig "local_ram" portNum = "o_RAMAddr"
addressSig n portNum = n++"_addr"++(show portNum)

readEnableSig "local_ram" portNum = "o_RAMRE"
readEnableSig n portNum = n++"_rENA"++(show portNum)

writeEnableSig "local_ram" portNum = "o_RAMWE"
writeEnableSig n portNum = n++"_wENA"++(show portNum)

dataInSig "local_ram" portNum = "o_RAMData"
dataInSig n portNum = n++"_dIN"++(show portNum)

dataOutSig "local_ram" portNum = "i_RAMData"
dataOutSig n portNum = n++"_dOUT"++(show portNum)

-- Boolean function to check if an assignment statement is a BRAM write 
isBramWrite (Assign_stmt (Mem_access m i p) _) = True
isBramWrite _ = False

-- Boolean function to check if an assingment statement is a BRAM read
isBramRead (Func_stmt e) = let ms = (getMemAccesses e) in if (ms == []) then False else True
isBramRead (Assign_stmt l r) = let ms = (getMemAccesses r) in if (ms == []) then False else True
isBramRead (VAssign_stmt l r) = let ms = (getMemAccesses r) in if (ms == []) then False else True
--isBramRead _ = False

-- Boolean function to check if a list of assignment statements has any BRAM reads in it
areThereBramReads [] = False
areThereBramReads (a:as) = let s = (isBramRead a) in if (s == True) then True else areThereBramReads as

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
grabAllMemAccesses [] = []
grabAllMemAccesses (a:as) = (getMemAccesses a)++(grabAllMemAccesses as)

-- Helper functions to assist in displaying the memory dependencies of statements
getRHS (Assign_stmt a b) = b
getRHS (VAssign_stmt a b) = b
--getRHS (Func_stmt e) = (Var_access (JustVar "NULL_NO_RHS"))
getRHS (Func_stmt e) = e
getLHS (Assign_stmt a b) = a
getLHS (VAssign_stmt a b) = b
--getLHS (Func_stmt e) = (Var_access (JustVar "NULL_NO_LHS"))
getLHS (Func_stmt e) = e
dispDependencies x = unlines (map show x)

-- Function used to retrieve all memory dependencies for a group of statements
getAllDependencies ss = let allr = (grabEveryRHS ss) in genMemoryDependencies [] (nub (grabAllMemAccesses allr))

-- Function used to retrieve all memory dependencies for a group of statements (both LHS and RHS)
getMemDependencies_LHS_and_RHS ss =
  let allr = (grabEveryRHS ss)
      alll = (grabEveryLHS ss) in genMemoryDependencies [] (nub (grabAllMemAccesses (allr++alll)))
	
-- Function used to retrieve all memory dependencies on the LHS of a set of assignment statements (nub is not used b/c all accesses matter, not just unique ones)
getDependenciesLHS ss = let all = (grabEveryLHS ss) in genMemoryDependencies [] (grabAllMemAccesses all)

-- Takes a list of memory accesses and returns an association list
-- which is a list of tuples in which each tuple consists of a...
-- 1st element - memory name
-- 2nd element - list of memory accesses from this memory
genMemoryDependencies acc [] = acc
genMemoryDependencies acc (x@(Mem_access n i p):as) =
	case (lookup n acc) of
		Just xs -> let acc' = (delete (n,xs) acc) in
				let newEl = (n,(x:xs)) in
					let acc'' = newEl:acc' in
						(genMemoryDependencies acc'' as)
		Nothing -> let acc' = ((n,[x]):acc) in 
						(genMemoryDependencies acc' as)

-- Visits an expression and returns all memory accesses in sub-expressions
getMemAccesses x@(Mem_access n i p) =
  let nestedAccesses = (getMemAccesses i) in
            case nestedAccesses of
                    [] ->[x]
                    _ -> error $ "Nested memory accesses are not allowed (error in "++show x++")"
getMemAccesses (Var_access _) = []
getMemAccesses (Channel_access _) = []
getMemAccesses (Const_access _) = []
getMemAccesses (BinaryOp _ a b) = ((getMemAccesses a)++(getMemAccesses b)) 
getMemAccesses (UnaryOp _ a) = (getMemAccesses a)
getMemAccesses (ParensExpr a) = (getMemAccesses a)
getMemAccesses (FuncApp s args) = (concatMap getMemAccesses args)
		

