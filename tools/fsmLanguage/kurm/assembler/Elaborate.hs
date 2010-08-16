module Elaborate where
    import Ast
    import Util
    import Parser
    import Control.Monad.Error
    import Text.ParserCombinators.Parsec.Pos;

    layout :: Compile ()
    layout = do ast <- getAst
                lay <- layout_ ast
                putAst (map (\(p,i,n) -> (p,2*i,n)) lay)
        where layout_ ast                 = let (p,i,a) = unzip3 ast in helper p a ast
              lo_ v p (z,i,(Origin l))    = do { l' <- compute p l; return l' }
              lo_ v p (z,i,(Label l))     = do { v' <- v; return $ v' }
              lo_ v p (z,i,(Align a d m)) = do v' <- v
                                               a' <- compute p a
                                               m' <- compute p m
                                               return $ align v' a' m'
              lo_ v p (z,i,(Data r d))    = do v' <- v
                                               r' <- compute p  r
                                               return $ v'+r'
              lo_ v p (z,i,(Ascii s))     = do v' <- v
                                               return $ v' + (strwords s)
              lo_ v p n                   = do { v' <- v; return $ v'+1 }
              helper p a ast              = do scn <- scanlM lo_ (return 0) ast
                                               seq <- sequence scn
                                               return $ zip3 p seq a
              align v a m                 = if m>0 && m<(shift v a) then v else v+(shift v a)
              shift v a                   = (a - (v `mod` a)) `mod` a
              strwords s                  = let s'=(length s) in toInteger $ (s' `div` 2)+(s' `mod` 2)

    canon :: Compile ()
    canon = do ast <- getAst
               can <- canon_ ast ast
               putAst can
        where canon_ ast []                       = do return []
              canon_ ast ((p,i,(Label l)):xs)     = do l' <- canon_ ast xs
                                                       return $ l'
              canon_ ast ((p,i,(Origin l)):xs)    = do l' <- canon_ ast xs
                                                       return $ l'
              canon_ ast ((p,i,(Load s t o)):xs)  = do o' <- compute ast o
                                                       l' <- canon_ ast xs
                                                       let n' = Load s t (Val o')
                                                       return $ (p,i,n') : l'
              canon_ ast ((p,i,(Store s t o)):xs) = do o' <- compute ast o
                                                       l' <- canon_ ast xs
                                                       let n' = Store s t (Val o')
                                                       return $ (p,i,n'):l'
              canon_ ast ((p,i,(Loadc s t o)):xs)  = do o' <- compute ast o
                                                        l' <- canon_ ast xs
                                                        let n' = Loadc s t (Val o')
                                                        return $ (p,i,n') : l'
              canon_ ast ((p,i,(Storec s t o)):xs) = do o' <- compute ast o
                                                        l' <- canon_ ast xs
                                                        let n' = Storec s t (Val o')
                                                        return $ (p,i,n'):l'
              canon_ ast ((p,i,(Branch m (Lab l))):xs)  = do o' <- compute ast (Lab l)
                                                             l' <- canon_ ast xs
                                                             let n' = Branch m (Val (o'-i))
                                                             return $ (p,i,n'):l'
              canon_ ast ((p,i,(Branch m o)):xs)  = do o' <- compute ast o
                                                       l' <- canon_ ast xs
                                                       let n' = Branch m (Val o')
                                                       return $ (p,i,n'):l'
              canon_ ast ((p,i,(Jump o)):xs)      = do o' <- compute ast o
                                                       l' <- canon_ ast xs
                                                       let n' = Jump (Val o')
                                                       return $ (p,i,n'):l'
              canon_ ast ((p,i,(Jumpc o)):xs)     = do o' <- compute ast o
                                                       l' <- canon_ ast xs
                                                       let n' = Jumpc (Val o')
                                                       return $ (p,i,n'):l'
              canon_ ast ((p,i,(Data r v)):xs)    = do r' <- compute ast r
                                                       v' <- compute ast v
                                                       l' <- canon_ ast xs
                                                       let n' = Data (Val r') (Val v')
                                                       return $ (p,i,n'):l'
              canon_ ast ((p,i,(Align a v m)):xs) = do a' <- compute ast a
                                                       v' <- compute ast v
                                                       m' <- compute ast m
                                                       l' <- canon_ ast xs
                                                       let s' = align i a' m'
                                                       let n' = Data (Val s') (Val v')
                                                       return $ (p,i,n'):l'
              canon_ ast (x:xs)                   = do l' <- canon_ ast xs
                                                       return $ x:l'
              align v a m                         = if m>0 && m<(shift v a) then 0 else (shift v a)
              shift v a                           = (a - (v `mod` a)) `mod` a
        

    expand :: Compile ()
    expand = do ast <- getAst
                exp <- expand_ ast
                putAst exp
                return ()
        where expand_  ast                = do list <- mapM expand__ ast
                                               return $ foldl (++) [] list
              expand__ (p,i,Include file) = do inc <- liftIO $ parseLang file
                                               either bad good inc
              expand__ x                  = return [x]
              good x                      = return x
              bad x                       = do { throwError (Err [(show x)]); return [] }

    elaborate :: Compile ()
    elaborate = do layout
                   canon
                   abortErr
