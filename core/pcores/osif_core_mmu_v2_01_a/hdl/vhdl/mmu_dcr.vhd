library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library proc_common_v1_00_b;
--use proc_common_v1_00_b.proc_common_pkg.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

library osif_core_mmu_v2_01_a;
use osif_core_mmu_v2_01_a.all;

entity mmu_dcr is
	generic
	(
		C_DCR_BASEADDR        : std_logic_vector := "1111111111";
		C_DCR_HIGHADDR        : std_logic_vector := "0000000000";
		C_DCR_AWIDTH          : integer          := 10;
		C_DCR_DWIDTH          : integer          := 32
	);
	port
	(
		clk                : in std_logic;
		rst                : in std_logic;
		-- mmu diagnosis registers
		i_tlb_miss_count   : in  std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
		i_tlb_hit_count    : in  std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
		i_page_fault_count : in  std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
		
		-- dcr bus protocol ports
		o_dcrAck   : out std_logic;
		o_dcrDBus  : out std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
		i_dcrABus  : in  std_logic_vector(C_DCR_AWIDTH - 1 downto 0);
		i_dcrDBus  : in  std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
		i_dcrRead  : in  std_logic;
		i_dcrWrite : in  std_logic
	);
end entity;

architecture imp of mmu_dcr is
	constant C_MMU_BASEADDR : std_logic_vector := C_DCR_BASEADDR + 4;
	
	signal dcr_hit  : std_logic;
begin

	process (i_dcrABus, i_dcrDBus, i_tlb_miss_count, i_tlb_hit_count, i_page_fault_count)
	begin
		dcr_hit <= '0';
		o_dcrDBus <= i_dcrDBus;
		if i_dcrABus = C_MMU_BASEADDR then
			dcr_hit <= '1';
			o_dcrDBus <= i_tlb_miss_count;
		elsif i_dcrABus = C_MMU_BASEADDR + 1 then
			dcr_hit <= '1';
			o_dcrDBus <= i_tlb_hit_count;		
		elsif i_dcrABus = C_MMU_BASEADDR + 2 then
			dcr_hit <= '1';
			o_dcrDBus <= i_page_fault_count;
		end if;
	end process;
	
	process (clk, rst)
	begin
		if rst = '1' then
			o_dcrAck <= '0';
		elsif rising_edge(clk) then
			o_dcrAck <= dcr_hit and i_dcrRead;
		end if;
	end process;  
	
end architecture;

