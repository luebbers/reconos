------------------------------------------------------------------------------
-- Module Declaration
------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
USE ieee.std_logic_arith.all;

------------------------------------------------------------------------------
-- Module and Port Declaration
------------------------------------------------------------------------------

entity dcr_if is
  generic (
    C_ON_INIT        : std_logic_vector(31 downto 0) := X"0000_0000";
    C_DCR_BASEADDR    : std_logic_vector(9 downto 0)  := B"10_0000_0000"
	 );
  port (
    clk		      	: in  std_logic;
	rst		      	: in  std_logic;
   DCR_ABus		: in  std_logic_vector(9 downto 0);
	DCR_Sl_DBus		: in  std_logic_vector(31 downto 0);
	DCR_Read		: in  std_logic;
	DCR_Write		: in  std_logic;
	Sl_dcrAck		: out std_logic;
	Sl_dcrDBus		: out std_logic_vector(31 downto 0);
	-- Registers
	ctrl_reg		: out std_logic_vector(31 downto 0)
    );

  attribute SIGIS : string;
  attribute SIGIS of clk : signal is "Clk";
  attribute SIGIS of rst : signal is "Rst";

end entity dcr_if;

architecture IMP of dcr_if is
------------------------------------------------------------------------------
-- Signal Declaration
------------------------------------------------------------------------------

  signal dcr_addr_hit   	: std_logic; 
  signal dcr_base_addr		: std_logic_vector(9 downto 0);
  signal dcr_read_access   : std_logic; 
  signal read_data			: std_logic_vector(31 downto 0);
  signal Sl_dcrAck_sig		: std_logic;
  signal ctrl_reg_sig		: std_logic_vector(31 downto 0);

begin

	dcr_base_addr <= C_DCR_BASEADDR;
	-- if the address specified by dcr_base_addr is the sane as the address received on DCR -> hit 
	dcr_addr_hit <= '1' when ( DCR_ABus(9 downto 1) = dcr_base_addr(9 downto 1) ) else '0';
  
	DCR_1 : process(clk) is
	begin
		if clk'event and clk = '1' then
			dcr_read_access <=  DCR_Read and dcr_addr_hit;
			Sl_dcrAck_sig  <= (DCR_Read or DCR_Write) and dcr_addr_hit;
		end if;
	end process DCR_1;
  
	DCR_2 : process(clk) is
	begin
		if clk'event and clk = '1' then
			if (rst='1') then
				ctrl_reg_sig  <= C_ON_INIT;
			elsif ( (DCR_Write = '1') and (Sl_dcrAck_sig = '0') and (dcr_addr_hit= '1') ) then
				ctrl_reg_sig  <= DCR_Sl_DBus;
			end if;
		end if;
	end process DCR_2;
  
	DCR_3 : process(clk) is
	begin
		if clk'event and clk = '1' then
			if ( (DCR_Read = '1') and (Sl_dcrAck_sig = '0') and (dcr_addr_hit= '1') ) then
				read_data  <= ctrl_reg_sig;
			end if;
		end if;
  end process DCR_3;
   
  Sl_dcrDBus <= read_data when dcr_read_access = '1' else DCR_Sl_DBus;
  Sl_dcrAck <= Sl_dcrAck_sig;
  ctrl_reg <= ctrl_reg_sig;

end architecture IMP;

