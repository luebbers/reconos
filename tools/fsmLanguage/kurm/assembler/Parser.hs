module Parser where
    import Control.Monad.Error
    import Control.Monad.State
    import Text.ParserCombinators.Parsec
    import Text.ParserCombinators.Parsec.Expr
    import qualified Text.ParserCombinators.Parsec.Token as P
    import Text.ParserCombinators.Parsec.Language
    import Text.ParserCombinators.Parsec.Combinator
    import qualified Ast as A

    langDef     = emptyDef {
        commentStart    = "/*",
        commentEnd      = "*/",
        commentLine     = ";",
        nestedComments  = False,
        caseSensitive   = False,
        reservedNames   = [ "add", "sub", "or", "and", "addc", "subc", "orc",
                            "andc", "lw", "sw", "set", "bra", "jmp", ".word",
                            ".align", ".ascii", ".asciz", ".include", ".fill",
                            ".org", ".skip", ".space", ".string", ".include",
                            "jmpc", "lwc", "swc", "cmpg", "cmpge", "cmpl",
                            "cmple", "cmpz", "cmpeq","cmpne", "brag", "brage",
                            "bral", "brale", "braz", "braeq", "brane", "nop"]
    }

    lexer       = P.makeTokenParser langDef
    reserved    = P.reserved        lexer
    reservedOp  = P.reservedOp      lexer
    whiteSpace  = P.whiteSpace      lexer
    parens      = P.parens          lexer
    braces      = P.braces          lexer
    integer     = P.integer         lexer
    float       = P.float           lexer
    natural     = P.natural         lexer
    identifier  = P.identifier      lexer
    stringLit   = P.stringLiteral   lexer
    charLit     = P.charLiteral     lexer
    symbol      = P.symbol          lexer
    lexeme      = P.lexeme          lexer
    commaSep    = P.commaSep        lexer
    commaSep1   = P.commaSep1       lexer
    semiSep     = P.semiSep         lexer
    semiSep1    = P.semiSep1        lexer
    comma       = P.comma           lexer
    semi        = P.semi            lexer

    -- Register Names for the KURM ISA
    dreg n v = do { reserved n; return v }
    r0  = dreg "r0" 0
    r1  = dreg "r1" 1
    r2  = dreg "r2" 2
    r3  = dreg "r3" 3
    r4  = dreg "r4" 4
    r5  = dreg "r5" 5
    r6  = dreg "r6" 6
    r7  = dreg "r7" 7
    r8  = dreg "r8" 8
    r9  = dreg "r9" 9
    r10 = dreg "r10" 10
    r11 = dreg "r11" 11
    r12 = dreg "r12" 12
    r13 = dreg "r13" 13
    r14 = dreg "r14" 14
    r15 = dreg "r15" 15
    reg      = r0  <|> r1  <|> r2  <|> r3  <|> r4  <|> r5  <|> r6  <|> r7  <|>
               r8  <|> r9  <|> r10 <|> r11 <|> r12 <|> r13 <|> r14 <|> r15

    -- Arithmetic instructions for the KURM ISA
    darith n v  = do p <- getPosition
                     reserved n
                     s <- reg
                     symbol ","
                     t <- reg
                     symbol ","
                     d <- reg
                     return $ [A.instr p (v s t d)]

    stmt_nop    = do p <- getPosition
                     reserved "nop"
                     return $ [A.instr p (A.add 0 0 0)]

    stmt_add    = darith "add" A.add
    stmt_sub    = darith "sub" A.sub
    stmt_or     = darith "or"  A.aor
    stmt_and    = darith "and" A.aand

    stmt_addc   = darith "addc" A.addc
    stmt_subc   = darith "subc" A.subc
    stmt_orc    = darith "orc"  A.orc
    stmt_andc   = darith "andc" A.andc

    -- Control Flow Instructions for the KURM ISA
    stmt_cmp n m = do p <- getPosition
                      reserved n
                      s <- reg
                      symbol ","
                      t <- reg
                      return $ [A.instr p (A.set s t m)]

    stmt_brc n m = do p <- getPosition
                      reserved n
                      o <- expr
                      return $ [A.instr p (A.branch m o)]

    stmt_cmpg    = stmt_cmp "cmpg"  4
    stmt_cmpge   = stmt_cmp "cmpge" 6
    stmt_cmpl    = stmt_cmp "cmpl"  1
    stmt_cmple   = stmt_cmp "cmple" 3
    stmt_cmpz    = stmt_cmp "cmpz"  8
    stmt_cmpeq   = stmt_cmp "cmpeq" 2
    stmt_cmpne   = stmt_cmp "cmpne" 5

    stmt_brag    = stmt_brc "brag"  4
    stmt_brage   = stmt_brc "brage" 6
    stmt_bral    = stmt_brc "bral"  1
    stmt_brale   = stmt_brc "brale" 3
    stmt_braz    = stmt_brc "braz"  8
    stmt_braeq   = stmt_brc "braeq" 2
    stmt_brane   = stmt_brc "brane" 5

    stmt_set    = do p <- getPosition
                     reserved "set"
                     s <- reg
                     symbol ","
                     t <- reg
                     symbol ","
                     m <- number
                     return $ [A.instr p (A.set s t m)]

    stmt_bra    = do p <- getPosition
                     reserved "bra"
                     m <- number
                     symbol ","
                     o <- expr
                     return $ [A.instr p (A.branch m o)]

    stmt_jmp    = do p <- getPosition
                     reserved "jmp"
                     o <- expr
                     return $ [A.instr p (A.jump o)]

    stmt_jmpc   = do p <- getPosition
                     reserved "jmpc"
                     o <- expr
                     return $ [A.instr p (A.jumpc o)]

    stmt_label  = do p <- getPosition
                     i <- identifier
                     symbol ":"
                     return $ [A.instr p (A.label i)]

    -- Memory Access Instructions for the KURM ISA
    dmem n v  = do p <- getPosition
                   reserved n
                   s <- reg
                   symbol ","
                   t <- reg
                   symbol ","
                   o <- expr
                   return $ [A.instr p (v s t o)]

    stmt_lw   = dmem "lw" A.load
    stmt_sw   = dmem "sw" A.store
    stmt_lwc  = dmem "lwc" A.loadc
    stmt_swc  = dmem "swc" A.storec

    -- Constant Value Support for the Assembler
    bit      = ((string "0") <|> (string "1"))

    bits :: CharParser st Integer
    bits     = lexeme $ do string "0b"
                           bts <- many bit
                           return $ foldl comb 0 bts
        where comb c n = case n of
                            "0" -> 2*c
                            "1" -> 2*c + 1

    number  = (try bits) <|> integer

    exTab   = [[iop "*" A.EMul AssocLeft,
                iop "/" A.EDiv AssocLeft],
               [iop "+" A.EAdd AssocLeft,
                iop "-" A.ESub AssocLeft]]
        where iop s f assoc = Infix (do {reservedOp s; return f}) assoc
              pop s f       = Prefix (do {reservedOp s; return f})

    exFact  = parens expr <|> term
    expr    = buildExpressionParser exTab exFact
    term    = do { num <- number; return $ A.Val num } <|>
              do { lab <- identifier; return $ A.Lab lab }

    -- Data Value Instructions
    stmt_word = do pos <- getPosition
                   reserved ".word"
                   wrd <- commaSep expr
                   return $ map (update pos) wrd
        where update pos val = A.instr pos (A.word (A.Val 1) val)

    stmt_algn = do pos <- getPosition
                   reserved ".align"
                   aln <- expr
                   val <- option (A.Val 0) (do { comma; n <- expr; return $ n })
                   max <- option (A.Val 0) (do { comma; n <- expr; return $ n })
                   return $ [A.instr pos (A.align aln val max)]

    stmt_stng = do pos <- getPosition
                   reserved ".string"
                   str <- stringLit
                   return $ [A.instr pos (A.ascii (str ++ "\0"))]

    stmt_asci = do pos <- getPosition
                   reserved ".ascii"
                   str <- stringLit
                   return $ [A.instr pos (A.ascii str)]

    stmt_ascz = do pos <- getPosition
                   reserved ".asciz"
                   str <- stringLit
                   return $ [A.instr pos (A.ascii (str ++ "\0"))]

    stmt_fill = do pos <- getPosition
                   reserved ".fill"
                   rpt <- expr
                   val <- option (A.Val 0) (do { comma; n <- expr; return $ n })
                   return $ [A.instr pos (A.word rpt val)]

    stmt_skip = do pos <- getPosition
                   reserved ".skip"
                   sze <- expr
                   val <- option (A.Val 0) (do { comma; n <- expr; return $ n })
                   return $ [A.instr pos (A.word sze val)]

    stmt_spce = do pos <- getPosition
                   reserved ".space"
                   sze <- expr
                   val <- option (A.Val 0) (do { comma; n <- expr; return $ n })
                   return $ [A.instr pos (A.word sze val)]

    stmt_org  = do pos <- getPosition
                   reserved ".org"
                   org <- expr
                   return $ [A.instr pos (A.origin org)]

    stmt_inc  = do pos  <- getPosition
                   reserved ".include"
                   file <- stringLit
                   return $ [A.instr pos (A.include file)]

    -- Global Parser Definitions
    insr        = stmt_add <|>
                  stmt_sub <|>
                  stmt_or <|>
                  stmt_and <|>
                  stmt_nop <|>
                  stmt_addc <|>
                  stmt_subc <|>
                  stmt_orc <|>
                  stmt_andc <|>
                  stmt_lw <|>
                  stmt_sw <|>
                  stmt_lwc <|>
                  stmt_swc <|>
                  stmt_set <|>
                  stmt_cmpg <|>
                  stmt_cmpge <|>
                  stmt_cmpl <|>
                  stmt_cmple <|>
                  stmt_cmpz <|>
                  stmt_cmpeq <|>
                  stmt_cmpne <|>
                  stmt_bra <|>
                  stmt_brag <|>
                  stmt_brage <|>
                  stmt_bral <|>
                  stmt_brale <|>
                  stmt_braz <|>
                  stmt_braeq <|>
                  stmt_brane <|>
                  stmt_jmp <|>
                  stmt_jmpc <|>
                  stmt_label <|>
                  stmt_word <|>
                  stmt_algn <|>
                  stmt_stng <|>
                  stmt_asci <|>
                  stmt_ascz <|>
                  stmt_fill <|>
                  stmt_skip <|>
                  stmt_spce <|>
                  stmt_org <|>
                  stmt_inc

    program     = do p  <- many insr
                     return $ foldl (++) [] p

    file        = do whiteSpace
                     p <- program
                     eof
                     return p

    -- Parser Functions
    runLexer :: Show a => Parser a -> String -> IO ()
    runLexer p i = run (do {whiteSpace
                            ;x <- p
                            ;eof
                            ;return x}) i

    run :: Show a => Parser a -> String -> IO ()
    run p input = case (parse p "" input) of
                    Left err    -> do putStr "Parse Error: "
                                      print err
                    Right x     -> print x

    parseLang f = parseFromFile file f

    parseFile :: String -> A.Compile ()
    parseFile f = do ast <- liftIO $ parseFromFile file f  
                     either bad good ast
        where bad b  = do { throwError (A.Err [(show b)]); return () }
              good g = do { A.putAst g; return () }
