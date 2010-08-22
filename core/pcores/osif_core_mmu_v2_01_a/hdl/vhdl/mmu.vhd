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

entity mmu is
	generic
	(
		C_BASEADDR            : std_logic_vector := X"FFFFFFFF";
		C_AWIDTH              : integer          := 32;
		C_DWIDTH              : integer          := 32;
		C_DCR_AWIDTH          : integer          := 10;
		C_DCR_DWIDTH          : integer          := 32;
		C_TLB_TAG_WIDTH       : integer          := 20;
		C_TLB_DATA_WIDTH      : integer          := 21 
	);
	port
	(
		clk               : in  std_logic;
		rst               : in  std_logic;
		
		-- incoming memory interface
		i_swrq            : in  std_logic;
		i_srrq            : in  std_logic;
		i_bwrq            : in  std_logic;
		i_brrq            : in  std_logic;
		
		i_addr            : in  std_logic_vector(C_AWIDTH - 1 downto 0);
		i_laddr           : in  std_logic_vector(C_AWIDTH - 1 downto 0);
		o_data            : out std_logic_vector(C_AWIDTH - 1 downto 0);
		
		o_busy            : out std_logic;
		o_rdone           : out std_logic;
		o_wdone           : out std_logic; 
		
		-- outgoing memory interface
		o_swrq            : out std_logic;
		o_srrq            : out std_logic;
		o_bwrq            : out std_logic;
		o_brrq            : out std_logic;
		            
		o_addr            : out std_logic_vector(C_AWIDTH - 1 downto 0);
		o_laddr           : out std_logic_vector(C_AWIDTH - 1 downto 0);
		i_data            : in  std_logic_vector(C_AWIDTH - 1 downto 0);		
		
		i_busy            : in  std_logic;
		i_rdone           : in  std_logic;
		i_wdone           : in  std_logic;
				
		-- configuration interface
		i_cfg             : in  std_logic_vector(C_AWIDTH - 1 downto 0);
		i_repeat          : in  std_logic;
		i_setpgd          : in  std_logic;
		
		-- status registers
		o_state_fault            : out std_logic;
		o_state_access_violation : out std_logic;
		
		-- tlb interface
		i_tlb_match       : in  std_logic;
		i_tlb_busy        : in  std_logic;
		--i_tlb_wdone       : in  std_logic;
		o_tlb_we          : out std_logic;
		o_tlb_request     : out std_logic;
		i_tlb_data        : in  std_logic_vector(C_TLB_DATA_WIDTH - 1 downto 0);
		o_tlb_data        : out std_logic_vector(C_TLB_DATA_WIDTH - 1 downto 0);
		o_tlb_tag         : out std_logic_vector(C_TLB_TAG_WIDTH - 1 downto 0);
		
		-- diagnosis registers
		o_tlb_miss_count   : out std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
		o_tlb_hit_count    : out std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
		o_page_fault_count : out std_logic_vector(C_DCR_DWIDTH - 1 downto 0)
	);
end entity;

architecture imp of mmu is

	type state_t is (
		STATE_FETCH_REQUEST,
		STATE_TLB_LOOKUP_1,
		STATE_TLB_LOOKUP_2,
		STATE_TLB_LOOKUP_3,
		STATE_READ_PGDE,
		STATE_SAVE_PGDE,
		STATE_READ_PTE,
		STATE_SAVE_PTE,
		STATE_TLB_STORE_1,
		STATE_TLB_STORE_2,
		STATE_WAIT_FOR_BUSY,
		STATE_DONE,
		STATE_FAULT,
		STATE_ACCESS_VIOLATION
	);

	signal rq     : std_logic;
	signal busy   : std_logic;
	signal active : std_logic;
	signal pgd    : std_logic_vector(C_AWIDTH - 1 downto 0);
	signal srrq   : std_logic;
	signal data   : std_logic_vector(C_AWIDTH - 1 downto 0);
		
	signal request : std_logic_vector(3 downto 0);
	signal step    : state_t;
	
	signal tlb_miss_count   : std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
	signal tlb_hit_count    : std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
	signal page_fault_count : std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
	
	signal debug : std_logic_vector(C_DCR_DWIDTH - 1 downto 0);

begin

	o_tlb_miss_count   <= tlb_miss_count;
	o_tlb_hit_count    <= tlb_hit_count;
	o_page_fault_count <= page_fault_count;
	
	rq      <= i_swrq or i_srrq or i_bwrq or i_brrq;
	
	memory_interface_mux : process(active, busy, srrq, i_laddr, i_busy, i_rdone, i_wdone, request, data, i_data)
	begin
		if active = '1' then
			o_laddr <= C_BASEADDR;
			o_data  <= data;
			o_busy  <= busy;
			o_rdone <= '0';
			o_wdone <= '0';
			o_srrq  <= srrq;
			o_swrq  <= '0';
			o_brrq  <= '0';
			o_bwrq  <= '0';
		else
			o_laddr <= i_laddr;
			o_data  <= i_data;
			o_busy  <= i_busy or busy;
			o_rdone <= i_rdone;
			o_wdone <= i_wdone;			
			o_srrq  <= request(3);
			o_swrq  <= request(2);
			o_brrq  <= request(1);
			o_bwrq  <= request(0);
		end if;
	end process;
	
	mmu_configuration : process(clk, rst, i_setpgd)
	begin
		if rst = '1' then
			pgd <= (others => '0');
		elsif rising_edge(clk) then 
			if i_setpgd = '1' then
				pgd <= i_cfg;
			end if;
		end if;
	end process;
	
	handle_rq : process(clk, rst, rq)
		--variable step  : integer range 0 to 6;
		variable vaddr : std_logic_vector(31 downto 0);
		variable pgdep : std_logic_vector(31 downto 0);
		variable pgde  : std_logic_vector(31 downto 0);
		variable ptep  : std_logic_vector(31 downto 0);
		variable pte   : std_logic_vector(31 downto 0);
		variable paddr : std_logic_vector(31 downto 0);
		variable waiting   : std_logic;
	begin
		if rst = '1' then
			step <= STATE_FETCH_REQUEST;
			active <= '1';
			waiting := '0';
			busy <= '0';
			srrq <= '0';
			request <= (others => '0');
			o_state_fault <= '0';
			o_state_access_violation <= '0';
			data <= X"DADADADA";
			tlb_miss_count   <= (others => '0');
			tlb_hit_count    <= (others => '0');
			page_fault_count <= (others => '0');
			o_tlb_we <= '0';
			o_tlb_request <= '0';
			debug <= X"AFFEABBA";
		elsif rising_edge(clk) then
			if rq = '1' or waiting = '1' then
				case step is
					when STATE_FETCH_REQUEST => -- 0
						debug <= X"00000001";
						request <= i_srrq & i_swrq & i_brrq & i_bwrq;
						vaddr := i_addr; -- save virtual address
						busy <= '1';
						waiting := '1';
						--step <= STATE_READ_PGDE;
						o_tlb_request <= '1';
						step <= STATE_TLB_LOOKUP_1;
						
					when STATE_TLB_LOOKUP_1 =>
						debug <= X"00000002";
						o_tlb_tag <= vaddr(31 downto 12);
						if i_tlb_busy = '0' then
							step <= STATE_TLB_LOOKUP_2;
						end if;
						
					when STATE_TLB_LOOKUP_2 =>
						debug <= X"00000003";
						step <= STATE_TLB_LOOKUP_3;
						
					when STATE_TLB_LOOKUP_3 =>
						debug <= X"00000004";
						o_tlb_request <= '0';
						if i_tlb_match = '1' then
							paddr := i_tlb_data(20 downto 1) & vaddr(11 downto 0);
							o_addr <= paddr;
							tlb_hit_count <= tlb_hit_count + 1;
							if i_tlb_data(0) = '0' and (request(0) = '1' or request(2) = '1') then
								step <= STATE_ACCESS_VIOLATION;
							else
								active <= '0'; -- release memory interface
								step <= STATE_WAIT_FOR_BUSY;
							end if;
						else
							tlb_miss_count <= tlb_miss_count + 1;
							step <= STATE_READ_PGDE;
						end if;
							
						
					when STATE_READ_PGDE =>
						debug <= X"00000005";

						-- read pgd entry
						pgdep := pgd(31 downto 12) & vaddr(31 downto 22) & b"00"; 
						srrq  <= '1';
						o_addr  <= pgdep;
						step <= STATE_SAVE_PGDE;
					
					when STATE_SAVE_PGDE => --1
						debug <= X"00000006";

						-- save pgd entry
						srrq <= '0';
						if i_rdone = '1' then
							pgde := i_data;
							if pgde(10) = '0' then
								--page_fault_count <= page_fault_count + 1;
								step <= STATE_FAULT;
							else
								step <= STATE_READ_PTE;
							end if;
						end if;
						
					when STATE_READ_PTE => -- 2
						debug <= X"00000007";

						-- read pte
						ptep := pgde(31 downto 12) & vaddr(21 downto 12) & b"00";
						srrq <= '1';
						o_addr <= ptep;
						step <= STATE_SAVE_PTE;
												
					when STATE_SAVE_PTE => -- 3
						debug <= X"00000008";

						-- save pte
						srrq <= '0';
						if i_rdone = '1' then
							pte := i_data;
							paddr := pte(31 downto 12) & vaddr(11 downto 0);
							o_addr <= paddr;
							if pte(1) = '0' then -- page not present
								--page_fault_count <= page_fault_count + 1;
								step <= STATE_FAULT;
							elsif pte(8) = '0' and (request(0) = '1' or request(2) = '1') then
								step <= STATE_ACCESS_VIOLATION;
							else
								--active <= '0'; -- release memory interface
								--step <= STATE_WAIT_FOR_BUSY;
								o_tlb_request <= '1';
								step <= STATE_TLB_STORE_1;
							end if;
						end if;
						
					when STATE_TLB_STORE_1 =>
						debug <= X"00000009";

						if i_tlb_busy = '0' then
							o_tlb_we <= '1';
							o_tlb_tag <= vaddr(31 downto 12);
							o_tlb_data <= paddr(31 downto 12) & pte(8);
							step <= STATE_TLB_STORE_2;
						end if;
						
					when STATE_TLB_STORE_2 =>
						debug <= X"0000000A";

						o_tlb_we <= '0';
						o_tlb_request <= '0';
						if pte(8) = '0' and (request(0) = '1' or request(2) = '1') then
							step <= STATE_ACCESS_VIOLATION;
						else
							active <= '0';
							step <= STATE_WAIT_FOR_BUSY;
						end if;
						
					when STATE_WAIT_FOR_BUSY => -- 4
						debug <= X"0000000B";

						request <= (others => '0');
						if i_busy = '1' then
							busy <= '0'; -- at this point o_busy is generated by the memory controller
							step <= STATE_DONE;
						end if;
						
					when STATE_DONE => -- 5
						debug <= b"000" & i_busy & b"000" & i_rdone & b"000" & i_wdone & X"0000C";
						--page_fault_count <= paddr; -- remove me: debug

						if i_busy = '0' and (i_rdone = '1' or i_wdone = '1') then -- i_done stays '1' for exactly one clock cycle after request finishes
							data <= i_data;
							active <= '1'; -- claim memory interface
							waiting := '0';
							step <= STATE_FETCH_REQUEST;
						end if;
					
					when STATE_FAULT => -- 6
						debug <= X"0000000D";

						if i_repeat = '1' then
							o_state_fault <= '0';
							page_fault_count <= page_fault_count + 1;
							step <= STATE_READ_PGDE;
						else
							o_state_fault <= '1';
							data <= vaddr;
						end if;
						
					-- when a writable page is first mapped into ram it's PTE may be marked read-only in
					-- order to create a page fault at the first write access. the page can then be marked dirty.
					-- thats why we may recover from an access violation...
					when STATE_ACCESS_VIOLATION =>
						debug <= X"0000000E";

						if i_repeat = '1' then
							o_state_access_violation <= '0';
							page_fault_count <= page_fault_count + 1;
							step <= STATE_READ_PGDE;
						else
							o_state_access_violation <= '1';
							data <= vaddr;
						end if;
						
				end case;
			end if;
		end if;
	end process;

end architecture;

