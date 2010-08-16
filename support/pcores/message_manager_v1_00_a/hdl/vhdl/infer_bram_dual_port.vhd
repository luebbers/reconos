-- *************************************************************************
-- File:	infer_bram_dual_port.vhd
-- Date:	06/22/05
-- Purpose:	File used to instantiate an inferred BRAM (dual port),
--			According to Xilinx, this will only work with 7.1 b/c of shared variables.
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

-- Comment out for simulation
--library Unisim;
--use Unisim.all;
--library Unisim;
--use Unisim.all;

-- *************************************************************************
-- Entity declaration
-- *************************************************************************
entity infer_bram_dual_port is
  generic (
    ADDRESS_BITS	: integer := 9;
    DATA_BITS	: integer := 32
    );
  port (
    CLKA 	: in std_logic; 
    ENA   	: in std_logic; 
    WEA   	: in std_logic;
    ADDRA 	: in std_logic_vector(0 to ADDRESS_BITS - 1); 
    DIA   	: in std_logic_vector(0 to DATA_BITS - 1);
    DOA   	: out  std_logic_vector(0 to DATA_BITS - 1);

    CLKB 	: in std_logic; 
    ENB   	: in std_logic; 
    ADDRB 	: in std_logic_vector(0 to ADDRESS_BITS - 1); 
    DOB   	: out  std_logic_vector(0 to DATA_BITS - 1)
    );
end entity infer_bram_dual_port;


-- *************************************************************************
-- Architecture declaration
-- *************************************************************************
architecture implementation of infer_bram_dual_port is

	-- Constant declarations
	constant BRAM_SIZE	: integer := 2**ADDRESS_BITS;		-- # of entries in the inferred BRAM 

	-- BRAM data storage (array)
	type bram_storage is array( 0 to BRAM_SIZE - 1 ) of std_logic_vector( 0 to DATA_BITS - 1 );
	shared variable BRAM_DATA : bram_storage;

begin

	-- *************************************************************************
	-- Process:	BRAM_CONTROLLER_A
	-- Purpose:	Controller for Port A of inferred dual-port BRAM, BRAM_DATA
	-- *************************************************************************
	BRAM_CONTROLLER_A : process(CLKA) is
	begin
	    if( CLKA'event and CLKA = '1' ) then
	        if( ENA = '1' ) then
	            if( WEA = '1' ) then
	                BRAM_DATA( conv_integer(ADDRA) )  := DIA;
	            end if;
		
	            DOA <= BRAM_DATA( conv_integer(ADDRA) );
	        end if;
	    end if; 
	end process BRAM_CONTROLLER_A;

    	-- *************************************************************************
    	-- Process: BRAM_CONTROLLER_B
    	-- Purpose: Controller for Port B of inferred dual-port BRAM, BRAM_DATA
    	-- *************************************************************************
    	BRAM_CONTROLLER_B : process(CLKB) is
 	   begin
        	if( CLKB'event and CLKB = '1' ) then
	            if( ENB = '1' ) then
                	DOB <= BRAM_DATA( conv_integer(ADDRB) );
 	           end if;
      	 	 end if;
   	 end process BRAM_CONTROLLER_B;

end architecture implementation;
