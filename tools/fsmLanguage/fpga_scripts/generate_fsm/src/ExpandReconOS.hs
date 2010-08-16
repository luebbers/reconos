{--
ExpandReconOS.hs

This file contains all of the functionality to elaborate memory reads/writes into
a set of sequential assignment statements
--}

module ExpandReconOS(getAllDependencies, elaborateReconOSBody, addressSig, readEnableSig, writeEnableSig, dataInSig, dataOutSig) where
  
import LangAST

import Data.List(nub,delete,mapAccumL,findIndex,find)
import qualified Data.Map as Map
   

-- Elaboration function for a list of TRANS_DECLs
--	Iteratively executes elaborateTrans in order to pass state of count
elaborateReconOSBody count mems ts = (count', concat ts') 
  where (count', ts') = mapAccumL (elaborateTrans mems) count ts

-- Function that returns the intermediate state name string
intermediateName = "_reconos_extra"
			
-- Function used to generate a list of extra VHDL state names
extraStateNames 0 = []
extraStateNames i = (genName intermediateName i)++",\n"++(extraStateNames (i-1)) 

-- Look through a body (list of statements) for a system call.
-- * If there is more than 1, return an error, else return a tuple
-- * The tuple is (b,x,y) where b is a boolean value (true = syscall found, false = syscall not found) x is the system call statement, and y is the list of "done" statements
find_syscall sName statementList =
   find_syscall_helper [] [] sName statementList

find_syscall_helper scList doneList sName [] =
  let l = length scList in
      if (l > 1)
        then error ("More than 1 system call in state ("++sName++") is not allowed! -- ")
        else
          if (l ==0)
            then (False,scList,doneList)
            else (True,scList,doneList)

find_syscall_helper scList doneList sName (s:ss) =
  let b = (is_syscall s) in
      let scList' = if b then (s:scList) else scList in
         let doneList' = if b then doneList else (s:doneList) in
		(find_syscall_helper scList' doneList' sName ss)

-- abstract functions to check, if a call is a reconos system call
is_syscall (Assign_stmt lhs (FuncApp fname _)) = (is_reconos_call fname) 
is_syscall (Assign_stmt lhs _) = False
is_syscall (VAssign_stmt lhs (FuncApp fname _)) = (is_reconos_call fname) 
is_syscall (VAssign_stmt lhs _) = False
is_syscall (Func_stmt (FuncApp fname _)) = (is_reconos_call fname) 

-- all currently supported reconos system calls
is_reconos_call "read" = True
is_reconos_call "write" = True
is_reconos_call "read_s" = True
is_reconos_call "read_burst" = True
is_reconos_call "write_burst" = True
is_reconos_call "read_burst_l" = True
is_reconos_call "write_burst_l" = True
is_reconos_call "get_init_data" = True
is_reconos_call "get_init_data_s" = True
is_reconos_call "sem_post" = True
is_reconos_call "sem_wait" = True
is_reconos_call "mutex_lock" = True
is_reconos_call "mutex_trylock" = True
is_reconos_call "mutex_unlock" = True
is_reconos_call "mutex_release" = True
is_reconos_call "cond_wait" = True
is_reconos_call "cond_signal" = True
is_reconos_call "cond_broadcast" = True
is_reconos_call "mbox_get" = True
is_reconos_call "mbox_get_s" = True
is_reconos_call "mbox_tryget" = True
is_reconos_call "mbox_tryget_s" = True
is_reconos_call "mbox_put" = True
is_reconos_call "mbox_tryput" = True
is_reconos_call "mq_receive" = True
is_reconos_call "mq_send" = True
is_reconos_call "begin" = True
is_reconos_call "ready" = True
is_reconos_call "reset" = True
is_reconos_call "thread_exit" = True
is_reconos_call _ = False

-- Elaboration function for a TRANS_DECL that will generate a list of TRANS_DECLS
elaborateTrans mems count x@(TRANS_DECL start end guard body)  =
  let (b,sc,dList) = find_syscall start body in
	case b of
		True -> generate_normal_state count start guard sc dList end
--			case guard of
--				NoGuard   ->
--					case (is_normal sc) of
--                                           False -> 
--                                           	case (is_done_and_success sc) of
--                                           		True -> generate_done_and_success_state count start guard sc dList end
--                                           		False -> generate_done_state count start guard sc dList end
--                                           True -> generate_normal_state count start guard sc dList end
--                                        generate_normal_state count start guard sc dList end
--
--				(Guard c) ->  error ("State ("++start++")"++" has a guarded syscall which is not allowed!" )
--				(Guard c) ->  
--
--					case (is_normal sc) of
--                                           False -> 
--                                           	case (is_done_and_success sc) of
--                                           		True -> generate_done_and_success_state count start guard sc dList end
--                                           		False -> generate_done_state count start guard sc dList end
--                                           True -> generate_normal_state count start guard sc dList end


		False -> (count,[TRANS_DECL start end guard body])

-- generate normal state (parse reconos system call and attach the other assignments)
generate_normal_state count start guard sc dList end = 
 let new_state = ((start)++(genName intermediateName count)) in
  (count,
   [
    (TRANS_DECL start end guard ((elaborate_syscall sc)++dList))
   ]
  )


---- is reconos system call a 'normal' state (which does not contain a done condition)
--is_normal sc =
--  let fname = get_fname sc in
--      case fname of
--         "reset" -> True
--         "ready" -> True
--         "begin" -> True
--         "thread_exit" -> True
--         "sem_post" -> True
--         "sem_wait" -> True
--         "mutex_unlock" -> True
--         "mutex_release" -> True
--         "cond_signal" -> True
--         "cond_broadcast" -> True
--         _ -> False

---- is reconos system call connected with a 'done' and 'success' condition
--is_done_and_success sc =
--  let fname = get_fname sc in
--      case fname of
         --"cond_wait" -> True
         --"mutex_lock" -> True 
         -- these calls could use success variable for error handling.
         -- if this is needed for a system call, this call has to be removed from following list.
         --"mutex_trylock" -> True 
         --"mbox_get" -> True
         --"mbox_get_s" -> True
         --"mbox_tryget" -> True
         --"mbox_tryget_s" -> True
         --"mbox_put" -> True
         --"mbox_tryput" -> True
         --"mq_receive" -> True
         --"mq_send" -> True
--         _ -> False


-- extract function name
get_fname [(Assign_stmt lhs (FuncApp fname args))] = fname
get_fname [(VAssign_stmt lhs (FuncApp fname args))] = fname
get_fname [(Func_stmt(FuncApp fname args))] = fname
  

-- generate state containing the system call and an extra state, containing 'done' list
generate_done_state count start guard sc dList end = 
 let new_state = ((start)++(genName intermediateName count)) in
  (count+1,
   [
    (TRANS_DECL start new_state guard (elaborate_syscall sc)),
    (TRANS_DECL new_state end (makeReconosGuard) dList),
    (TRANS_DECL new_state new_state NoGuard (elaborate_syscall sc))
   ]
  )

-- generate state containing the system call and an extra state, containing 'done and success' list
generate_done_and_success_state count start guard sc dList end = 
 let new_state = ((start)++(genName intermediateName count)) in
  (count+1,
   [
    (TRANS_DECL start new_state guard (elaborate_syscall sc)),
    (TRANS_DECL new_state end (makeReconosGuard2) dList),
    (TRANS_DECL new_state new_state NoGuard (elaborate_syscall sc))
   ]
  )

-- change parameter for reconos system calls
elaborate_syscall [(VAssign_stmt lhs (FuncApp fname@("read") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_1_args_list (args++[lhs]))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("write") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_1_args_list (args))))]

elaborate_syscall [(Assign_stmt lhs (FuncApp fname@("read") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname++"_s") (make_rule_1_args_list (args++[lhs]))))]

elaborate_syscall [(Assign_stmt lhs (FuncApp fname@("read_s") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_1_args_list (args++[lhs]))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("read_burst") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_1_args_list (args))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("write_burst") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_1_args_list (args))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("read_burst_l") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_1_args_list (args))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("write_burst_l") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_1_args_list (args))))]

elaborate_syscall [(VAssign_stmt lhs (FuncApp fname@("get_init_data") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_1_args_list (args++[lhs]))))]

elaborate_syscall [(Assign_stmt lhs (FuncApp fname@("get_init_data") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname++"_s") (make_rule_1_args_list (args++[lhs]))))]

elaborate_syscall [(Assign_stmt lhs (FuncApp fname@("get_init_data_s") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_1_args_list (args++[lhs]))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("sem_post") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_2_args_list (args))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("sem_wait") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_2_args_list (args))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("mutex_lock") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_3_args_list (args))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("mutex_trylock") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_3_args_list (args))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("mutex_unlock") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_2_args_list (args))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("mutex_release") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_2_args_list (args))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("cond_wait") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_3_args_list (args))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("cond_signal") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_2_args_list (args))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("cond_broadcast") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_2_args_list (args))))]

elaborate_syscall [(VAssign_stmt lhs (FuncApp fname@("mbox_get") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_3_args_list (args++[lhs]))))]

elaborate_syscall [(Assign_stmt lhs (FuncApp fname@("mbox_get") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname++"_s") (make_rule_3_args_list (args++[lhs]))))]

elaborate_syscall [(Assign_stmt lhs (FuncApp fname@("mbox_get_s") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_3_args_list (args++[lhs]))))]

elaborate_syscall [(VAssign_stmt lhs (FuncApp fname@("mbox_tryget") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_3_args_list (args++[lhs]))))]

elaborate_syscall [(Assign_stmt lhs (FuncApp fname@("mbox_tryget") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname++"_s") (make_rule_3_args_list (args++[lhs]))))]

elaborate_syscall [(Assign_stmt lhs (FuncApp fname@("mbox_tryget_s") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_3_args_list (args++[lhs]))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("mbox_put") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_3_args_list (args))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("mbox_tryput") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_3_args_list (args))))]

elaborate_syscall [(VAssign_stmt lhs (FuncApp fname@("mq_receive") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_3_args_list (args++[lhs]))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("mq_send") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_3_args_list (args))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("begin") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_2_args_list (args))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("ready") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_4_args_list (args))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("reset") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_2_args_list (args))))]

elaborate_syscall [(Func_stmt(FuncApp fname@("thread_exit") args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (make_rule_2_args_list (args))))]

-- default rules
elaborate_syscall [(Func_stmt(FuncApp fname args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (args)))]

elaborate_syscall [(Assign_stmt lhs (FuncApp fname args))] =
   [(Func_stmt (FuncApp ("reconos_"++fname) (args++[lhs])))]

-- different rules to extend parameters for reconos system calls
make_rule_1_args_list args =
  ([
     (Var_access (JustVar "done")),
     (Var_access (JustVar "o_osif")),
     (Var_access (JustVar "i_osif"))
  ]++args)

make_rule_2_args_list args =
  ([
     (Var_access (JustVar "o_osif")),
     (Var_access (JustVar "i_osif"))
  ]++args)

make_rule_3_args_list args =
  ([
     (Var_access (JustVar "done")),
     (Var_access (JustVar "success")),
     (Var_access (JustVar "o_osif")),
     (Var_access (JustVar "i_osif"))
  ]++args)

make_rule_4_args_list args =
  ([
     (Var_access (JustVar "o_osif"))
  ]++args)

-- define reconos 'done' guard
makeReconosGuard =
 (Guard
    (Var_access (JustVar "done")) 
 )

-- define reconos 'done and success' guard
makeReconosGuard2 =
 (Guard
    (Var_access (JustVar "done and success")) 
 )

-- Elaboration function for a TRANS_DECL that will generate a list of TRANS_DECLS
elaborateTransOld mems count x@(TRANS_DECL start end guard body)  =
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
					let body' = (setPortNumbers [] (getReconOSDependencies_LHS_and_RHS body) body) in
						-- If there are BRAM reads, then intermediate TRANS_DECLs must be generated and then writes are elaborated
						(count+2
						,[TRANS_DECL start ((start)++(genName intermediateName (count+1))) guard (initiateReads start mems body'),
						  TRANS_DECL ((start)++(genName intermediateName (count+1))) ((start)++(genName intermediateName (count+2))) NoGuard [],
					  	TRANS_DECL ((start)++(genName intermediateName (count+2))) end NoGuard (initiateWrites (finalizeReconOSAssignments Map.empty body'))
						])
		False -> error $ "An internal memory can only be updated twice per state, and and external memory only once per state!\n Error in state:\n"++start

-- State name generation function
genName s i = (s ++ (show i))

-- State name generation function
genName2 s sName i = (s ++ (show sName) ++ (show i))

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
setPortNumbers acc ds ((Assign_stmt l r):as) =
   let r'   = (assignPortNumber ds r) 
       l'   = (assignPortNumber ds l) 
       acc' = ((Assign_stmt l' r'):acc) in
           setPortNumbers acc' ds as


-- Takes an expression and the dependency structure and calculates the port number any  memory accesses within it
assignPortNumber ds ma@(Mem_access n i p) =
	let v = lookup n ds in
		case v of
			Nothing -> error "ReconOSory access not found!"
			Just x  -> let iM = (findIndex (==ma) x) in
							case iM of
								Nothing -> error "ReconOSory access index not found!"
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
-- finalizeReconOSAssignments :: [Stmt] -> [Stmt]
finalizeReconOSAssignments acc as = snd $ mapAccumL derefReconOSs acc as
              

-- Dereferences the RHS of as assignment statement
derefReconOSs acc (Assign_stmt l r) = let (acc', r') = derefReconOSAccesses acc r
                                  in (acc', Assign_stmt l r') 

-- Dereferences all memory accesses within an expression
derefReconOSAccesses acc (Mem_access m index p)	= 
    (acc', (Var_access (JustVar (dataOutSig m p {- ++ (show dout_num) -}))))
  where dout_num = Map.findWithDefault 0 m acc
        acc' = Map.insertWith (+) m 1 acc
        
derefReconOSAccesses acc x@(Var_access t)		= (acc,x)
derefReconOSAccesses acc x@(Channel_access t)		= (acc,x)
derefReconOSAccesses acc x@(Const_access a)		= (acc,x)
derefReconOSAccesses acc (UnaryOp s a)			= let (acc',a') = derefReconOSAccesses acc a
                                          in (acc', (UnaryOp s a'))

derefReconOSAccesses acc (ParensExpr a)	 = let (acc',a') = derefReconOSAccesses acc a
                                          in (acc', (ParensExpr a'))
                                          
derefReconOSAccesses acc (BinaryOp s a b)	= 
  let (acc' , a') = derefReconOSAccesses acc a
      (acc'' , b') = derefReconOSAccesses acc' b
  in (acc'', BinaryOp s a' b')

derefReconOSAccesses acc x@(FuncApp s args) = let (acc', args') = mapAccumL derefReconOSAccesses acc args
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
addressSig n portNum = n++"_addr"++(show portNum)
readEnableSig n portNum = n++"_rENA"++(show portNum)
writeEnableSig n portNum = n++"_wENA"++(show portNum)
dataInSig n portNum = n++"_dIN"++(show portNum)
dataOutSig n portNum = n++"_dOUT"++(show portNum)

-- Boolean function to check if an assignment statement is a BRAM write 
isBramWrite (Assign_stmt (Mem_access m i p) _) = True
isBramWrite _ = False

-- Boolean function to check if an assingment statement is a BRAM read
isBramRead (Assign_stmt l r) = let ms = (getReconOSAccesses r) in if (ms == []) then False else True

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
grabAllReconOSAccesses [] = []
grabAllReconOSAccesses (a:as) = (getReconOSAccesses a)++(grabAllReconOSAccesses as)

-- Helper functions to assist in displaying the memory dependencies of statements
getRHS (Assign_stmt a b) = b
getLHS (Assign_stmt a b) = a
dispDependencies x = unlines (map show x)

-- Function used to retrieve all memory dependencies for a group of statements
getAllDependencies ss = let allr = (grabEveryRHS ss) in genReconOSoryDependencies [] (nub (grabAllReconOSAccesses allr))

-- Function used to retrieve all memory dependencies for a group of statements (both LHS and RHS)
getReconOSDependencies_LHS_and_RHS ss =
  let allr = (grabEveryRHS ss)
      alll = (grabEveryLHS ss) in genReconOSoryDependencies [] (nub (grabAllReconOSAccesses (allr++alll)))
	
-- Function used to retrieve all memory dependencies on the LHS of a set of assignment statements (nub is not used b/c all accesses matter, not just unique ones)
getDependenciesLHS ss = let all = (grabEveryLHS ss) in genReconOSoryDependencies [] (grabAllReconOSAccesses all)

-- Takes a list of memory accesses and returns an association list
-- which is a list of tuples in which each tuple consists of a...
-- 1st element - memory name
-- 2nd element - list of memory accesses from this memory
genReconOSoryDependencies acc [] = acc
genReconOSoryDependencies acc (x@(Mem_access n i p):as) =
	case (lookup n acc) of
		Just xs -> let acc' = (delete (n,xs) acc) in
				let newEl = (n,(x:xs)) in
					let acc'' = newEl:acc' in
						(genReconOSoryDependencies acc'' as)
		Nothing -> let acc' = ((n,[x]):acc) in 
						(genReconOSoryDependencies acc' as)

-- Visits an expression and returns all memory accesses in sub-expressions
getReconOSAccesses x@(Mem_access n i p) =
  let nestedAccesses = (getReconOSAccesses i) in
            case nestedAccesses of
                    [] ->[x]
                    _ -> error $ "Nested memory accesses are not allowed (error in "++show x++")"
getReconOSAccesses (Var_access _) = []
getReconOSAccesses (Channel_access _) = []
getReconOSAccesses (Const_access _) = []
getReconOSAccesses (BinaryOp _ a b) = ((getReconOSAccesses a)++(getReconOSAccesses b)) 
getReconOSAccesses (UnaryOp _ a) = (getReconOSAccesses a)
getReconOSAccesses (ParensExpr a) = (getReconOSAccesses a)
getReconOSAccesses (FuncApp s args) = (concatMap getReconOSAccesses args)
		

