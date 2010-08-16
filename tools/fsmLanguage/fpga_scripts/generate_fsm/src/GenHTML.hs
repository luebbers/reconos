{--
GenHTML.hs

This file contains all of the functionality to generate a "sectionalized"
HTML version of an FSM description file that can be linked against the SVG DOT files
--}

module GenHTML where
  
import LangAST
import GenVHDL

import Text.PrettyPrint
import Data.List(groupBy,sortBy,intersperse,nub,mapAccumL)
import ExpandMem(addressSig, readEnableSig, writeEnableSig, dataInSig, dataOutSig)

-- Function: genSectionName
-- Purpose : Used to generate HTML anchor/section names
genSectionName i = "sec"++(show i)

-- Function used to generate HTML for port definitions
gen_port_html as =
	unlines [
			"<br>",
			"-- Port Definitions<br>",
			"PORTS:<br>",
			concatMap f as
			]
	where f (PORT_DECL n d t) = n++", "++d++", "++(untype t)++"<br>\n"

-- Function used to generate HTML for permanent connections
gen_connect_html as =
	unlines [
			"<br>",
			"-- Permanent Connections<br>",
			"CONNECTIONS:<br>",
			concatMap f as
			]
	where f (CONNECTION_DECL as) = render $ gen_stmt_html as

-- Function used to generate HTML for memory definitions
gen_mem_html as =
	unlines [
			"<br>",
			"-- Memory Definitions<br>",
			"MEMS:<br>",
			concatMap f as
			]
	where f (MEM_DECL n d a InternalMem ) = n++", "++(show d)++", "++(show a)++"<br>\n" 
	      f (MEM_DECL n d a ExternalMem ) = n++", "++(show d)++", "++(show a)++", EXTERNAL<br>\n" 

-- Function used to generate HTML for FSM signals
gen_sigs_html as =
	unlines [
			"<br>",
			"-- FSM Signals<br>",
			"SIGS:<br>",
			concatMap f as
			]
	where f (FSM_SIG a t) = a++", "++(untype t)++"<br>\n"

-- Function used to generate HTML for FSM transitions
gen_trans_html as =
	unlines [
			"<br>",
			"-- FSM Transitions<br>",
			"TRANS:<br>",
			concat $ snd $ mapAccumL f 0 as
			]
	where f i (TRANS_DECL f t g b) =
		let guard_code = case g of
							NoGuard  -> text ""
							(Guard act) -> text "|" <+> dispExpr act
		in
		((i+1),
		show (
			text ("<A name = "++(show (genSectionName i))++"> </A>") $$ 
			text "<br>" <+> text f <+> guard_code <+> text "->" <+> text t <+> text " where { <br>\n" $$
			nest 2 (vcat (map gen_stmt_html b)) $$
			text "}<br>\n"
			)
		)

-- Function used to generate HTML for VHDL statements
gen_stmt_html as =
			text "&nbsp;&nbsp;&nbsp;&nbsp;" <+> (genAssign as) <+> text "<br>\n"	

-- Function used to generate HTML for VHDL
gen_vhdl_html as =
	unlines [
			"<br>",
			"-- VHDL Section<br>",
			"VHDL:<br>",
			unlines (intersperse "<br>\n" (lines as))
			]


