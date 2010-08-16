module Output where
    import Ast
    import System
    import Parser
    import Check
    import Elaborate

    output :: Compile ()
    output = return ()

    {-
    output []     = do putStrLn $ ""
    output (a:as) = do putStrLn $ a
                       output as
                       return ()

    output2 v []        = do putStrLn $ ""
    output2 v (a:as)    = do putStrLn $ (hex v) ++ " " ++ a
                             output2 (v+2) as
                             return ()
    -}
