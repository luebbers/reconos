-------------------------------------------------------------------------------------
-- Copyright (c) 2006, University of Kansas - Hybridthreads Group
-- All rights reserved.
-- 
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
-- 
--     * Redistributions of source code must retain the above copyright notice,
--       this list of conditions and the following disclaimer.
--     * Redistributions in binary form must reproduce the above copyright notice,
--       this list of conditions and the following disclaimer in the documentation
--       and/or other materials provided with the distribution.
--     * Neither the name of the University of Kansas nor the name of the
--       Hybridthreads Group nor the names of its contributors may be used to
--       endorse or promote products derived from this software without specific
--       prior written permission.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
-- ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
-- ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-------------------------------------------------------------------------------------

-- *************************************************************************
-- File:	infer_bram.vhd
-- Date:	06/15/05
-- Purpose:	File used to instantiate an inferred BRAM (single port)
-- Author:	Jason Agron
-- *************************************************************************

-- *************************************************************************
-- Library declarations
-- *************************************************************************
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;

library Unisim;
use Unisim.all;
library Unisim;
use Unisim.all;


-- *************************************************************************
-- Entity declaration
-- *************************************************************************
entity infer_bram is
  generic (
	ADDRESS_BITS	: integer := 9;
	DATA_BITS		: integer := 32
	);
  port (
    CLKA 	: in std_logic; 
    ENA   	: in std_logic; 
    WEA   	: in std_logic;
    ADDRA 	: in std_logic_vector(0 to ADDRESS_BITS - 1); 
    DIA   	: in std_logic_vector(0 to DATA_BITS - 1);
    DOA   	: out  std_logic_vector(0 to DATA_BITS - 1)
    );
end entity infer_bram;


-- *************************************************************************
-- Architecture declaration
-- *************************************************************************
architecture implementation of infer_bram is

	-- Constant declarations
	constant BRAM_SIZE	: integer := 2 **ADDRESS_BITS;		-- # of entries in the inferred BRAM 

	-- BRAM data storage (array)
	type bram_storage is array( 0 to BRAM_SIZE - 1 ) of std_logic_vector( 0 to DATA_BITS - 1 );
	signal BRAM_DATA : bram_storage;


begin

	-- *************************************************************************
	-- Process:	BRAM_CONTROLLER_A
	-- Purpose:	Controller for inferred BRAM, BRAM_DATA
	-- *************************************************************************
	BRAM_CONTROLLER_A : process(CLKA) is
	begin
	    if( CLKA'event and CLKA = '1' ) then
	        if( ENA = '1' ) then
	            if( WEA = '1' ) then
	                BRAM_DATA( conv_integer(ADDRA) )  <= DIA;
	            end if;
		
	            DOA <= BRAM_DATA( conv_integer(ADDRA) );
	        end if;
	    end if; 
	end process BRAM_CONTROLLER_A;

end architecture implementation;
