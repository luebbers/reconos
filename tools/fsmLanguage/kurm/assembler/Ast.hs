module Ast where
    import Text.ParserCombinators.Parsec.Pos;
    import Control.Monad.Error
    import Control.Monad.State
    import Control.Monad.Writer

    data CVAL =   Val Integer
                | Lab String
                | EMul CVAL CVAL
                | EDiv CVAL CVAL
                | EAdd CVAL CVAL
                | ESub CVAL CVAL
                deriving(Show,Eq)

    data KURM =   Add       Integer Integer Integer
                | Sub       Integer Integer Integer
                | Or        Integer Integer Integer
                | And       Integer Integer Integer
                | Addc      Integer Integer Integer
                | Subc      Integer Integer Integer
                | Orc       Integer Integer Integer
                | Andc      Integer Integer Integer
                | Load      Integer Integer CVAL
                | Store     Integer Integer CVAL
                | Loadc     Integer Integer CVAL
                | Storec    Integer Integer CVAL
                | Set       Integer Integer Integer
                | Branch    Integer CVAL
                | Jump      CVAL
                | Jumpc     CVAL
                | Label     String
                | Data      CVAL CVAL
                | Align     CVAL CVAL CVAL
                | Origin    CVAL
                | Ascii     String
                | Include   String
                deriving (Show,Eq)

    type Instr      = (SourcePos,Integer,KURM)
    type Program    = [Instr]
    newtype Err     = Err [String] deriving (Show,Eq)
    newtype Ast     = Ast Program deriving (Show,Eq)
    newtype Env     = Env (Err,Ast) deriving (Show,Eq)
    type Compile a  = WriterT [(String,String)] (StateT Env (ErrorT Err IO)) a

    instance Error Err where
        noMsg    = Err []
        strMsg s = Err [s]

    findlabel [] l                  = Nothing
    findlabel ((p,i,Label s):xs) l  = if s == l
                                      then Just (p,i,Label s)
                                      else findlabel xs l
    findlabel (x:xs) l              = findlabel xs l

    compute ast (Val i)     = return i
    compute ast (Lab s)     = case (findlabel ast s) of
                                Nothing      -> do throwError $ (Err ["Internal Error 1"])
                                                   return 0
                                Just (p,i,n) -> do return i
    compute ast (EMul x y)  = do x' <- compute ast x
                                 y' <- compute ast y
                                 return $ x' * y'
    compute ast (EDiv x y)  = do x' <- compute ast x
                                 y' <- compute ast y
                                 return $ x' `div` y'
    compute ast (EAdd x y)  = do x' <- compute ast x
                                 y' <- compute ast y
                                 return $ x' + y'
    compute ast (ESub x y)  = do x' <- compute ast x
                                 y' <- compute ast y
                                 return $ x' - y'

    getAst :: Compile Program
    getAst      = do (Env (Err err,Ast ast)) <- get
                     return ast

    putAst :: Program -> Compile ()
    putAst ast  = do err <- getErr
                     put (Env (Err err,Ast ast))
                     return ()

    getErr :: Compile [String]
    getErr      = do (Env (Err err,Ast ast)) <- get
                     return err

    putErr :: [String] -> Compile ()
    putErr err  = do ast <- getAst
                     put (Env (Err err, Ast ast))
                     return ()

    pushErr :: String -> Compile ()
    pushErr err = do (Env (Err errs,Ast ast)) <- get
                     put (Env (Err (errs++[err]),Ast ast))
                     return ()

    abortErr :: Compile ()
    abortErr    = do err <- getErr
                     case err of
                        [] -> do { return () }
                        _  -> do { throwError (Err err); return () }

    defState     = Env (Err [], Ast [])

    instr p i    = (p,-1,i)

    add s t d    = Add s t d
    sub s t d    = Sub s t d
    aor  s t d   = Or  s t d
    aand s t d   = And s t d

    addc s t d   = Addc s t d
    subc s t d   = Subc s t d
    orc  s t d   = Orc  s t d
    andc s t d   = Andc s t d

    load  s t o  = Load s t o
    store s t o  = Store s t o

    loadc  s t o = Loadc s t o
    storec s t o = Storec s t o

    set    s t m = Set s t m
    branch m o   = Branch m o
    jump   l     = Jump l
    jumpc   l    = Jumpc l

    label n      = Label n
    word r n     = Data r n
    align n v m  = Align n v m
    ascii s      = Ascii s
    origin o     = Origin o
    include s    = Include s
