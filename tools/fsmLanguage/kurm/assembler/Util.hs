module Util where
    import Ast
    import Char
    import Data.Bits
    import Text.ParserCombinators.Parsec.Pos

    hex d v = hex_ d (fromInteger v)
    hex_ 0 v = ""
    hex_ d v = (hex_ (d-1) (v `div` 16)) ++ [(hx (v `mod` 16))]

    bv n b = if (testBit b n) then "1" else "0"
    bz 0 v = ""
    bz n v = (bv (n-1) v) ++ (bz (n-1) v)
    bz_ n v = bz n (toInteger v)

    hx v | v>9  = chr $ ord 'A' + (v-10)
    hx v        = chr $ ord '0' + v
    
    islabel l (p,i,(Label s))       = s == l
    islabel _ _                     = False

    haslabel ast l                  = or $ map (islabel l) ast

    scanlM_ f v p []           = return []
    scanlM_ f v p ((l,i,x):xs) = let v'=(f v p (l,i,x))
                                 in do v'' <- v'
                                       l'  <- scanlM_ f v' ((l,v'',x):p) xs
                                       return $ (v):l'
    scanlM f v l               = scanlM_ f v [] l

    labtargets ast = foldl (++) [] (map lt_ ast)
        where lt_ (p,i,Store x y z) = lt__ p i z
              lt_ (p,i,Load x y z)  = lt__ p i z 
              lt_ (p,i,Branch x y)  = lt__ p i y
              lt_ (p,i,Jump x)      = lt__ p i x
              lt_ (p,i,Data x y)    = (lt__ p i x) ++ (lt__ p i y)
              lt_ (p,i,Align x y z) = (lt__ p i x) ++ (lt__ p i y) ++ (lt__ p i z)
              lt_ (p,i,Origin x)    = lt__ p i x
              lt_ x                 = []
              lt__ p i (Lab s)        = [(p,i,s)]
              lt__ p i (EMul x y)     = (lt__ p i x) ++ (lt__ p i y)
              lt__ p i (EDiv x y)     = (lt__ p i x) ++ (lt__ p i y)
              lt__ p i (EAdd x y)     = (lt__ p i x) ++ (lt__ p i y)
              lt__ p i (ESub x y)     = (lt__ p i x) ++ (lt__ p i y)
              lt__ p i x              = []

    labelloc [] l                   = 0
    labelloc (((Label b),n):as) l   = if b == l then n else (labelloc as l)
    labelloc (a:as) l               = labelloc as l

    loc n s = n ++ " " ++ (show name) ++ "(" ++ (show line) ++ "," ++ (show coln) ++ ")"
        where name = sourceName s
              line = sourceLine s
              coln = sourceColumn s
