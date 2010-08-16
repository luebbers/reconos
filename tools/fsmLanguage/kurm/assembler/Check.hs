module Check where
    import Ast
    import List
    import Util
    import Control.Monad.Error
    import Control.Monad.State

    duperr (a,b) (c,d) = "label " ++ b ++ s1 ++ " previously defined" ++ s2
        where s1 = loc " in" a
              s2 = loc " at" c

    laberr (p,i,s) = "label " ++ s ++ lc ++ " is undefined"
        where lc = loc " at" p

    checkdup :: Program -> Program -> Compile ()
    checkdup a []                 = return ()
    checkdup a ((p,i,Label s):xs) = case (findlabel a s) of
                                        Nothing    -> checkdup (a ++ [(p,i,Label s)]) xs
                                        Just (o,i,r) -> do pushErr $ duperr (p,s) (o,r)
                                                           checkdup (a ++ [(p,i,Label s)]) xs 
    checkdup a (x:xs)             = checkdup (a++[x]) xs

    checklab ast = do mapM pushErr missing
                      return ()
        where miss    = filter (not . (\(p,i,x) -> haslabel ast x)) (labtargets ast)
              missing = map laberr miss

    check :: Compile ()
    check = do ast <- getAst
               checkdup [] ast
               checklab ast
               abortErr

    verify :: Compile ()
    verify = do ast <- getAst
                let (p,i,a) = unzip3 ast
                mapM verify_ a
                abortErr
        where verify_ (Add s t d)            = vregs s t d
              verify_ (Sub s t d)            = vregs s t d
              verify_ (And s t d)            = vregs s t d
              verify_ (Or s t d)             = vregs s t d
              verify_ (Addc s t d)           = vregs s t d
              verify_ (Subc s t d)           = vregs s t d
              verify_ (Andc s t d)           = vregs s t d
              verify_ (Orc s t d)            = vregs s t d
              verify_ (Set s t m)            = if not (isreg s)
                                               then regerr s
                                               else if not (isreg t)
                                               then regerr t
                                               else if not (ismask m)
                                               then mskerr m
                                               else return ()
              verify_ (Load s t (Val v))     = if not (isreg s)
                                               then regerr s
                                               else if not (isreg t)
                                               then regerr t
                                               else if not (isoff v)
                                               then offerr v
                                               else return ()
              verify_ (Store s t (Val v))    = if not (isreg s)
                                               then regerr s
                                               else if not (isreg t)
                                               then regerr t
                                               else if not (isoff v)
                                               then offerr v
                                               else return ()
              verify_ (Loadc s t (Val v))    = if not (isreg s)
                                               then regerr s
                                               else if not (isreg t)
                                               then regerr t
                                               else if not (isoff v)
                                               then offerr v
                                               else return ()
              verify_ (Storec s t (Val v))   = if not (isreg s)
                                               then regerr s
                                               else if not (isreg t)
                                               then regerr t
                                               else if not (isoff v)
                                               then offerr v
                                               else return ()
              verify_ (Branch m (Val v))     = if not (ismask m)
                                               then mskerr m
                                               else if not (isbra v)
                                               then braerr v
                                               else return ()
              verify_ (Jump (Val v))         = if not (isjmp v)
                                               then jmperr v
                                               else return ()
              verify_ (Jumpc (Val v))        = if not (isjmp v)
                                               then jmperr v
                                               else return ()
              verify_ (Data (Val r) (Val v)) = if not (isval v)
                                               then valerr v
                                               else return ()
              verify_ (Ascii s)              = return ()
              verify_ x                      = pushErr $ "Cannot Verify: " ++ (show x)
              isreg s                        = s >= 0 && s < 16
              ismask m                       = m >= 0 && m < 16
              isbra b                        = b >= -256 && b < 256 && (b `mod` 2) == 0
              isjmp j                        = (j `mod` 4) == 0
              isval v                        = v >= -32768 && v < 65536
              isoff o                        = o >= -16 && o < 16 && (o `mod` 2) == 0
              vregs s t d                    = if not (isreg s)
                                               then regerr s
                                               else if not (isreg t)
                                               then regerr t
                                               else if not (isreg d)
                                               then regerr d
                                               else return ()
              regerr s                       = do { pushErr $ "R" ++ (show s) ++ " is not a valid register"; return () }
              offerr m                       = do { pushErr $ (show m) ++ " is not a valid offset"; return () }
              mskerr m                       = do { pushErr $ (show m) ++ " is not a valid mask value"; return () }
              braerr m                       = do { pushErr $ (show m) ++ " is not a valid branch offset"; return () }
              jmperr m                       = do { pushErr $ (show m) ++ " is not a valid jump location"; return () }
              valerr v                       = do { pushErr $ (show v) ++ " is not a valid 16-bit value"; return () }
