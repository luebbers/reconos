----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:49:05 07/20/2006 
-- Design Name: 
-- Module Name:    icapCTRL - icapCTRL_rtl 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity icapCTRL is
   generic (
		C_FAMILY					: string := "virtex5";
		C_ICAP_DWIDTH			: integer:= 32;
      C_BURST_SIZE			: natural := 16;									-- Number of DWords 
      C_DCR_BASEADDR			: std_logic_vector(9 downto 0) := b"10_0000_0000"; --DCR_BaseAddr
      C_DCR_HIGHADDR			: std_logic_vector(9 downto 0) := b"00_0000_0011"; --DCR_HighAddr, not used
      C_COUNT_ADDR			: std_logic_vector(31 downto 0) := X"00000010"
   );
   port (
      clk        : in std_logic;
      reset      : in std_logic;
      
      start      : in std_logic_vector(1 downto 0);
      
      M_rdAddr_o : out std_logic_vector(31 downto 0);
      M_rdReq_o  : out std_logic;
      M_rdNum_o  : out std_logic_vector(4 downto 0);
      M_rdAccept_i : in std_logic;
      M_rdData_i : in std_logic_vector(63 downto 0);
      M_rdAck_i  : in std_logic;
      M_rdComp_i : in std_logic;
      
      M_wrAddr_o : out std_logic_vector(31 downto 0);
      M_wrReq_o  : out std_logic;
      M_wrNum_o  : out std_logic_vector(4 downto 0);
      M_wrAccept_i : in std_logic;
      M_wrData_o : out std_logic_vector(63 downto 0);
      M_wrRdy_i  : in std_logic;
      M_wrAck_i  : in std_logic;
      M_wrComp_i : in std_logic;
      
		BUSY : out std_ulogic;
      O : out std_logic_vector((C_ICAP_DWIDTH-1) downto 0);
      CE : out std_ulogic;
      I : out std_logic_vector((C_ICAP_DWIDTH-1) downto 0);
      WRITE : out std_ulogic;
		Fifo_empty_o : out std_logic;
		Fifo_full_o : out std_logic;
		
		--- Interrupt
      done_int        : out std_logic;
		
		 --- DCR signals
		DCR_ABus        : in std_logic_vector(9 downto 0);
		DCR_Read        : in std_logic;
		DCR_Write       : in std_logic;
		DCR_Sl_DBus     : in std_logic_vector(31 downto 0);
		---
		Sl_dcrAck       : out std_logic;
		Sl_dcrDBus      : out std_logic_vector(31 downto 0);
		
		DCR_ABus_o        : out std_logic_vector(9 downto 0);
		DCR_Write_o       : out std_logic;
		DCR_Din_o         : out std_logic_vector(31 downto 0)
		
   );
end icapCTRL;

architecture icapCTRL_rtl of icapCTRL is

function log2(x : natural) return integer is
   variable i  : integer := 0;   
	begin 
		if x = 0 then 
			return 0;
		else
			while 2**i < x loop
				i := i+1;
			end loop;
			return i;
		end if;
	end function log2; 

   component ICAP_VIRTEX2
      port (
         BUSY : out std_ulogic;
         O : out std_logic_vector(7 downto 0);
         CE : in std_ulogic;
         CLK : in std_ulogic;
         I : in std_logic_vector(7 downto 0);
         WRITE : in std_ulogic
      );
   end component;
	
	component ICAP_VIRTEX4
    generic (
         ICAP_WIDTH : string := "X32" -- "X8" or "X32"
      );  
   	port (
         BUSY : out std_ulogic;
         O : out std_logic_vector(31 downto 0);
         CE : in std_ulogic;
         CLK : in std_ulogic;
         I : in std_logic_vector(31 downto 0);
         WRITE : in std_ulogic
      );
   end component;
	
	component ICAP_VIRTEX5
    generic (
         ICAP_WIDTH : string := "X32" -- "X8" or "X32"
      );  
   	port (
         BUSY : out std_ulogic;
         O : out std_logic_vector(31 downto 0);
         CE : in std_ulogic;
         CLK : in std_ulogic;
         I : in std_logic_vector(31 downto 0);
         WRITE : in std_ulogic
      );
   end component;
	
   component icapFIFO
      generic (
         C_FIFO_DEPTH   : integer := 64;
         C_DIN_WIDTH    : integer := 64;
         C_DOUT_WIDTH   : integer := 8
      );
      port (
         clk      : in std_logic;
         reset    : in std_logic;
         
         wEn_i    : in std_logic;
         wData_i  : in std_logic_vector(C_DIN_WIDTH-1 downto 0);
         
         rEn_i    : in std_logic;
         rData_o  : out std_logic_vector(C_DOUT_WIDTH-1 downto 0);
         
         full_o   : out std_logic;
         empty_o  : out std_logic
      );
   end component;
	
--	component DCR_control
--    generic(
--      ICAP_DCR_ADDR_L : std_logic_vector(9 downto 0) := b"10_0000_0000";
--      ICAP_DCR_ADDR_H : std_logic_vector(9 downto 0) := b"10_0000_0011"
--    );
--    port(
--      dcr_addr        : in std_logic_vector(9 downto 0);
--      dcr_mrd         : in std_logic;
--      dcr_mwr         : in std_logic;
--      dcr_din         : in std_logic_vector(31 downto 0);
--      ---
--      dcr_ack         : out std_logic;
--      dcr_dout        : out std_logic_vector(31 downto 0);
--      ---
--      start_w         : out std_logic;
--      start_r         : out std_logic;
--      addr            : out std_logic_vector(31 downto 0);
--      ---
--      clk             : in std_logic
--    );
--  end component;
  
  component dcr_if is
  generic (
    C_DCR_BASEADDR : std_logic_vector(9 downto 0) := B"00_0000_0000";
    C_ON_INIT : std_logic := '0');
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;
    DCR_ABus    : in  std_logic_vector(9 downto 0);
    DCR_Sl_DBus : in  std_logic_vector(31 downto 0);
    DCR_Read    : in  std_logic;
    DCR_Write   : in  std_logic;
    Sl_dcrAck   : out std_logic;
    Sl_dcrDBus  : out std_logic_vector(31 downto 0);
    ctrl_reg    : out std_logic_vector(31 downto 0));
  end component;

   type state_type is (IDLE, INIT, ACTIVE, BURSTING, WRITE_COUNT, DONE);
   signal state : state_type;

   --signal addr       : std_logic_vector(14 downto 0);
   --signal addr       : std_logic_vector(13 downto 0);
	
	signal addr       : std_logic_vector(18-(log2(C_BURST_SIZE)) downto 0);
	signal addr_tail  : std_logic_vector(2+(log2(C_BURST_SIZE)) downto 0);
	
   signal base_addr  : std_logic_vector(31 downto 22);
   signal base_lngth : std_logic_vector(15 downto 0);

   signal icap_busy  : std_logic;
   signal icap_dout  : std_logic_vector((C_ICAP_DWIDTH-1) downto 0);
   signal icap_din   : std_logic_vector((C_ICAP_DWIDTH-1) downto 0);
   signal icap_din_r : std_logic_vector((C_ICAP_DWIDTH-1) downto 0);
   signal icap_en_l  : std_logic;
   signal icap_rnw   : std_logic;
   
   signal fifo_rEn   : std_logic;
   signal fifo_wEn   : std_logic;
   signal fifo_full  : std_logic;
   signal fifo_empty : std_logic;
   
   signal count      : std_logic_vector(31 downto 0);
   
   signal debounce   : std_logic_vector(1 downto 0);
	
	signal dcr_reg      : std_logic_vector(31 downto 0);
	
	signal dcr_start_w   : std_logic;
	signal dcr_start_w_n : std_logic;
   signal dcr_start_r   : std_logic;
   signal dcr_addr      : std_logic_vector(31 downto 0);
	signal ctrl_reg      : std_logic_vector(31 downto 0);
	signal Sl_dcrAck_sig : std_logic;
	signal done_int_i    : std_logic;
	 
begin

			ICAP_4 : ICAP_VIRTEX5
				generic map (
					ICAP_WIDTH => "X32") -- "X8" or "X32"
				port map (
					BUSY => icap_busy, -- Busy output
					O => icap_dout,    -- 8-bit data output
					CE => icap_en_l,   -- Clock enable input
					CLK => clk,        -- Clock input
					I => icap_din_r,     -- 8-bit data input
					WRITE => icap_rnw  -- Write input
					);
						
				SWAP_BITS: process (icap_din) is
				begin  -- process Swap_bit_Order
				  for byte_i in 0 to 3 loop
					 for bit_i in 0 to 7 loop
						icap_din_r(byte_i*8 + (7-bit_i))    <= icap_din(byte_i*8 + bit_i);
					 end loop;  -- Bit
				  end loop;  -- Byte
				end process SWAP_BITS;

addr_tail <= (others => '0');

   -- Make icap signals available to chipscope at output
   BUSY <= icap_busy; -- Busy output
   O <= icap_dout;    -- 8-bit data output
   CE <= icap_en_l;   -- Clock enable input
   I <= icap_din;     -- 8-bit data input
   WRITE <= icap_rnw; -- Write input
				
	-- dcr interface instantiation
  dcr_control: dcr_if
    generic map (
      C_DCR_BASEADDR => C_DCR_BASEADDR)
    port map (
        clk         => clk,
        rst         => reset,
        DCR_ABus    => DCR_ABus,
        DCR_Sl_DBus => DCR_Sl_DBus,
        DCR_Read    => DCR_Read,
        DCR_Write   => DCR_Write,
        Sl_dcrAck   => Sl_dcrAck_sig,
        Sl_dcrDBus  => Sl_dcrDBus,
        ctrl_reg    => ctrl_reg);

	dcr_start_w <= 	Sl_dcrAck_sig and DCR_Write;
	Sl_dcrAck <= Sl_dcrAck_sig;
	-- Make DCR signals available to chipscope at output
	DCR_ABus_o <= DCR_ABus;
   DCR_Write_o <= DCR_Write;
	DCR_Din_o <= ctrl_reg;
	
	Fifo_empty_o <= fifo_empty;
	Fifo_full_o <= fifo_full;
	
	
   
--   -- WARNING!!!
--   -- The ICAP's data signals are reversed!
--   process(icap_din) begin
--      for i in 0 to 7 loop
--         icap_din_r(7-i) <= icap_din(i);
--      end loop;
--   end process;

---- if virtex2P or Virtex2 use ICAP_Virtex2 and invert input bits
--  V2_GEN : if (C_FAMILY = "virtex2p" or C_FAMILY = "virtex2") generate
--  
--		V2_GEN_8 : if (C_ICAP_DWIDTH = 8) generate
--			ICAP_0 : ICAP_VIRTEX2
--			port map (
--				BUSY => icap_busy, -- Busy output
--				O => icap_dout,    -- 8-bit data output
--				CE => icap_en_l,   -- Clock enable input
--				CLK => clk,        -- Clock input
--				I => icap_din_r,     -- 8-bit data input
--				WRITE => icap_rnw  -- Write input
--			);
--
--	-- WARNING!!!		
--	-- The ICAP's data signals are reversed in V2P!
--		process(icap_din) begin
--			for i in 0 to 7 loop
--				icap_din_r(7-i) <= icap_din(i);
--			end loop;
--		end process;
--			
--		end generate V2_GEN_8;
--	end generate V2_GEN;
--	
--	V4_GEN : if (C_FAMILY = "virtex4") generate
--		V4_GEN_8 : if (C_ICAP_DWIDTH = 8) generate
--			
--			ICAP_1 : ICAP_VIRTEX4
--				generic map (
--					ICAP_WIDTH => "X8") -- "X8" or "X32"
--					port map (
--						BUSY => icap_busy, -- Busy output
--						O => icap_dout,    -- 8-bit data output
--						CE => icap_en_l,   -- Clock enable input
--						CLK => clk,        -- Clock input
--						I => icap_din_r,     -- 8-bit data input
--						WRITE => icap_rnw  -- Write input
--					);
--			
--			process(icap_din) begin
--				for i in 0 to 7 loop
--					icap_din_r(7-i) <= icap_din(i);
--				end loop;
--			end process;
--					
--			end generate V4_GEN_8;
--			
--			V4_GEN_32 : if (C_ICAP_DWIDTH = 32) generate
--			
--			ICAP_2 : ICAP_VIRTEX4
--				generic map (
--					ICAP_WIDTH => "X32") -- "X8" or "X32"
--					port map (
--						BUSY => icap_busy, -- Busy output
--						O => icap_dout,    -- 8-bit data output
--						CE => icap_en_l,   -- Clock enable input
--						CLK => clk,        -- Clock input
--						I => icap_din_r,     -- 8-bit data input
--						WRITE => icap_rnw  -- Write input
--					);
--			
--			icap_din_r <= icap_din;
--			
--			end generate V4_GEN_32;
--					
--	end generate V4_GEN;
--	
--	V5_GEN : if (C_FAMILY = "virtex5") generate
--		V5_GEN_8 : if (C_ICAP_DWIDTH = 8) generate
--			
--			ICAP_3 : ICAP_VIRTEX5
--				generic map (
--					ICAP_WIDTH => "X8") -- "X8" or "X32"
--				port map (
--					BUSY => icap_busy, -- Busy output
--					O => icap_dout,    -- 8-bit data output
--					CE => icap_en_l,   -- Clock enable input
--					CLK => clk,        -- Clock input
--					I => icap_din_r,     -- 8-bit data input
--					WRITE => icap_rnw  -- Write input
--					);
--			
--			process(icap_din) begin
--				for i in 0 to 7 loop
--					icap_din_r(7-i) <= icap_din(i);
--				end loop;
--			end process;
--					
--		end generate V5_GEN_8;
--			
--		V5_GEN_32 : if (C_ICAP_DWIDTH = 32) generate
--			
--			ICAP_4 : ICAP_VIRTEX5
--				generic map (
--					ICAP_WIDTH => "X32") -- "X8" or "X32"
--				port map (
--					BUSY => icap_busy, -- Busy output
--					O => icap_dout,    -- 8-bit data output
--					CE => icap_en_l,   -- Clock enable input
--					CLK => clk,        -- Clock input
--					I => icap_din_r,     -- 8-bit data input
--					WRITE => icap_rnw  -- Write input
--					);
--						
--				SWAP_BITS: process (icap_din) is
--				begin  -- process Swap_bit_Order
--				  for byte_i in 0 to 3 loop
--					 for bit_i in 0 to 7 loop
--						icap_din_r(byte_i*8 + (7-bit_i))    <= icap_din(byte_i*8 + bit_i);
--					 end loop;  -- Bit
--				  end loop;  -- Byte
--				end process SWAP_BITS;
--			
--			end generate V5_GEN_32;			
--	end generate V5_GEN;
	
   -- fifo_empty is active high. If Fifo is not empty (fifo_empty = '0') rnw and ce gow low! 
   icap_rnw  <= fifo_empty;
   icap_en_l <= fifo_empty;
   fifo_rEn  <= not icap_busy;

   fifo_wEn  <= M_rdAck_i when(state=BURSTING) else '0';

   icapFIFO_0 : icapFIFO
      generic map (
         C_FIFO_DEPTH   => 64,
         C_DIN_WIDTH    => 64,
         C_DOUT_WIDTH   => C_ICAP_DWIDTH
      )
      port map (
         clk      => clk,
         reset    => reset,
         
         wEn_i    => fifo_wEn,
         wData_i  => M_rdData_i,
         
         rEn_i    => fifo_rEn,
         rData_o  => icap_din,
         
         full_o   => fifo_full,
         empty_o  => fifo_empty
      );

--   process(state, debounce, addr, base_addr) begin
--      M_rdAddr_o <= base_addr & addr & b"0000000";
--      if(state=IDLE) then
--         if(debounce(0)='0') then
--            M_rdAddr_o <= C_CONFIG_ADDR_0;
--         else
--            M_rdAddr_o <= C_CONFIG_ADDR_1;
--         end if;
--      end if;
--   end process;

   -- Generate the read address
   
   --M_rdAddr_o <= base_addr & addr & b"0000000";
	--M_rdAddr_o <= base_addr & addr & b"00000000";
	M_rdAddr_o <= base_addr & addr & addr_tail;
	
	done_int <= done_int_i;
	
		-- delay start signal by one cycle
	process(clk) begin
      if(clk='1' and clk'event) then
         dcr_start_w_n <= dcr_start_w;
      end if;
   end process;  
   
   process(state, fifo_full, fifo_empty, addr) begin
     -- don't request data
     M_rdReq_o <= '0';
     M_rdNum_o <= "10000";
	  M_wrReq_o <= '0';

--     if(state=IDLE) then
--         -- debounce is active low, when one of the switches is pressed debounce goes low.
--         --M_rdReq_o <= not debounce(0) or not debounce(1);  -- is one of the switches pressed?
--			M_rdReq_o <= dcr_start_w;
--         M_rdNum_o <= "00001"; -- request one 64 bit word
--      els
		--if(state=ACTIVE) then
		if ((state=ACTIVE or state=BURSTING) and (addr /= base_lngth)) then
         M_rdReq_o <= not fifo_full;
      elsif(state=WRITE_COUNT) then
         M_wrReq_o <= fifo_empty;
      end if;
   end process;
   
   M_wrAddr_o <= C_COUNT_ADDR;
   M_wrNum_o  <= "00001";
   M_wrData_o(63 downto 32) <= (others=>'0');
   M_wrData_o(31 downto 0)  <= count;

   process(clk) begin
      if(clk='1' and clk'event) then
         if(state=IDLE) then
            count <= (others=>'0');
         else
            if(fifo_empty='0') then -- if Fifo is not empty increase counter
               count <= count+1;
            end if;
         end if;
      end if;
   end process;

   process(clk) begin
      if(clk='1' and clk'event) then
         if(reset='1') then
            state <= IDLE;
            addr <= (others=>'0');
            base_addr <= (others=>'0');
            base_lngth <= (others=>'0');
				dcr_reg <= (others => '0');
				done_int_i <= '0';
         else
			   done_int_i <= '0';
            case(state) is
            when IDLE =>
               addr <= (others=>'0');
					-- initialize base addr and base_lngth with the data from DCR bus once!
					base_addr <= ctrl_reg(31 downto 22);
					base_lngth <= ctrl_reg(15 downto 0);		
               if(dcr_start_w_n='1') then
                  state <= ACTIVE;
               end if;
            when ACTIVE =>
               if(M_rdAccept_i='1') then
                  addr <= addr + 1;
						--dcr_reg(21 downto 7) <= dcr_reg(21 downto 7) + 1;
                  state <= BURSTING;
               end if;
            when BURSTING =>
               if(M_rdComp_i='1') then
                  if(addr=base_lngth) then
                     state <= WRITE_COUNT;
                  else
                     state <= ACTIVE;
                  end if;
               end if;
            when WRITE_COUNT =>
               --if(M_wrAccept_i='1') then
                  state <= DONE;
               --end if;
            when DONE =>
               if(fifo_empty = '1') then
				      done_int_i <= '1';
                  state <= IDLE;
               end if;
            when others =>
               state <= IDLE;
            end case;
         end if;
      end if;
   end process;
end icapCTRL_rtl;
