--!
--! \file third.vhd
--!
--! \author     Ariane Keller
--! \date       23.03.2011
-- Demo file for the multibus. This file will be executed in slot 2.
-- It can also send and receive data to/from the Ethernet interface.
-----------------------------------------------------------------------------
-- %%%RECONOS_COPYRIGHT_BEGIN%%%
-- %%%RECONOS_COPYRIGHT_END%%%
-----------------------------------------------------------------------------
--
	
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

library unisim;
use unisim.vcomponents.all;


library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity third is

	generic (
    	C_BURST_AWIDTH 	: integer := 11;
    	C_BURST_DWIDTH 	: integer := 32;
    	C_NR_SLOTS 		: integer := 3
    	);

  	port (
		-- user defined signals: use the signal names defined in the system.ucf file!
		-- user defined signals only work if they are before the reconos signals!

		-- Signals for the Ethernet interface
  		TXP              : out std_logic;
   		TXN              : out std_logic;
		RXP              : in  std_logic;
		RXN              : in  std_logic;
		-- SGMII-transceiver reference clock buffer input
		MGTCLK_P         : in  std_logic;
		MGTCLK_N         : in  std_logic;
		-- Asynchronous reset
		PRE_PHY_RESET    : in  std_logic;
		PHY_RESET        : out std_logic;

		-- Signals for the Multibus
		ready_2 		: out std_logic;
    	req_2   		: out std_logic_vector(0 to 3 - 1);
    	grant_2 		: in std_logic_vector(0 to 3 - 1);
    	data_2  		: out std_logic_vector(0 to 3 * 32 - 1);
    	sof_2   		: out std_logic_vector(0 to C_NR_SLOTS - 1);
    	eof_2   		: out std_logic_vector(0 to C_NR_SLOTS - 1);
   		src_rdy_2 		: out std_logic_vector(0 to C_NR_SLOTS - 1);
    	dst_rdy_2 		: in std_logic_vector(0 to C_NR_SLOTS - 1);
   		busdata_2		: in std_logic_vector(0 to 32 - 1);
   		bussof_2 		: in std_logic;
    	buseof_2 		: in std_logic;
 		bus_dst_rdy_2	: out std_logic;
   		bus_src_rdy_2 	: in std_logic;
		-- end user defined ports

		-- normal reconOS signals
		clk    			: in  std_logic;
		reset  			: in  std_logic;
		i_osif 			: in  osif_os2task_t;
		o_osif 			: out osif_task2os_t;

   		-- burst ram interface
   		o_RAMAddr 		: out std_logic_vector(0 to C_BURST_AWIDTH-1);
   		o_RAMData 		: out std_logic_vector(0 to C_BURST_DWIDTH-1);
   		i_RAMData 		: in  std_logic_vector(0 to C_BURST_DWIDTH-1);
   		o_RAMWE   		: out std_logic;
   		o_RAMClk  		: out std_logic;

		-- second ram
		o_RAMAddr_x 	: out std_logic_vector(0 to C_BURST_AWIDTH-1);
		o_RAMData_x 	: out std_logic_vector(0 to C_BURST_DWIDTH-1);
		i_RAMData_x 	: in  std_logic_vector(0 to C_BURST_DWIDTH-1); 
		o_RAMWE_x   	: out std_logic;
		o_RAMClk_x  	: out std_logic
    );

end third;

architecture Behavioral of third is

-----------------start component declaration------------------------------  
  	-- Component declaration for the LocalLink-level EMAC wrapper
 	component v6_emac_v1_4_locallink is
   	port(
      	-- 125MHz clock output from transceiver
    	CLK125_OUT               : out std_logic;
      	-- 125MHz clock input from BUFG
      	CLK125                   : in  std_logic;

      	-- LocalLink receiver interface
     	RX_LL_CLOCK              : in  std_logic;
      	RX_LL_RESET              : in  std_logic;
      	RX_LL_DATA               : out std_logic_vector(7 downto 0);
      	RX_LL_SOF_N              : out std_logic;
      	RX_LL_EOF_N              : out std_logic;
      	RX_LL_SRC_RDY_N          : out std_logic;
      	RX_LL_DST_RDY_N          : in  std_logic;
      	RX_LL_FIFO_STATUS        : out std_logic_vector(3 downto 0);

      	-- LocalLink transmitter interface
      	TX_LL_CLOCK              : in  std_logic;
      	TX_LL_RESET              : in  std_logic;
      	TX_LL_DATA               : in  std_logic_vector(7 downto 0);
      	TX_LL_SOF_N              : in  std_logic;
      	TX_LL_EOF_N              : in  std_logic;
      	TX_LL_SRC_RDY_N          : in  std_logic;
      	TX_LL_DST_RDY_N          : out std_logic;

      	-- Client receiver interface
      	EMACCLIENTRXDVLD         : out std_logic;
      	EMACCLIENTRXFRAMEDROP    : out std_logic;
      	EMACCLIENTRXSTATS        : out std_logic_vector(6 downto 0);
      	EMACCLIENTRXSTATSVLD     : out std_logic;
      	EMACCLIENTRXSTATSBYTEVLD : out std_logic;

      	-- Client Transmitter Interface
      	CLIENTEMACTXIFGDELAY     : in  std_logic_vector(7 downto 0);
      	EMACCLIENTTXSTATS        : out std_logic;
      	EMACCLIENTTXSTATSVLD     : out std_logic;
      	EMACCLIENTTXSTATSBYTEVLD : out std_logic;

      	-- MAC control interface
      	CLIENTEMACPAUSEREQ       : in  std_logic;
      	CLIENTEMACPAUSEVAL       : in  std_logic_vector(15 downto 0);

      	-- EMAC-transceiver link status
      	EMACCLIENTSYNCACQSTATUS  : out std_logic;
      	EMACANINTERRUPT          : out std_logic;

      	-- SGMII interface
      	TXP                      : out std_logic;
      	TXN                      : out std_logic;
      	RXP                      : in  std_logic;
      	RXN                      : in  std_logic;
      	PHYAD                    : in  std_logic_vector(4 downto 0);
      	RESETDONE                : out std_logic;

      	-- SGMII transceiver clock buffer input
      	CLK_DS                   : in  std_logic;

      	-- Asynchronous reset
      	RESET                    : in  std_logic
   	);
  	end component;

	-- Component declaration for the ll_fifo. This is used on the transmit
	-- and on the receive side to convert from a data width of 8 bits to 32 bits.
	component ll_fifo
   	generic (
        MEM_TYPE				: integer := 0;		-- 0 choose BRAM, 
													-- 1 choose Distributed RAM
        BRAM_MACRO_NUM  		: integer := 16;    -- Memory Depth. For BRAM only
        DRAM_DEPTH      		: integer := 16;    -- Memory Depth. For DRAM only                  
        WR_DWIDTH       		: integer := 32;    -- FIFO write data width,
                                                    -- Acceptable values are
                                                    -- 8, 16, 32, 64, 128.
        RD_DWIDTH       		: integer := 8;     -- FIFO read data width,
                                                    -- Acceptable values are
                                                    -- 8, 16, 32, 64, 128.
        RD_REM_WIDTH    		: integer := 1;     -- Remainder width of read data
        WR_REM_WIDTH    		: integer := 2;     -- Remainder width of write data
        USE_LENGTH      		: boolean := false; -- Length FIFO option
        glbtm           		: time    := 1 ns -- Global timing delay for simulation
	);
   port (
        -- Reset
        areset_in				: in std_logic;

        -- clocks
        write_clock_in			: in std_logic;
        read_clock_in			: in std_logic;

        -- Interface to downstream user application
        data_out				: out std_logic_vector(0 to RD_DWIDTH-1);
        rem_out					: out std_logic_vector(0 to RD_REM_WIDTH-1);
        sof_out_n				: out std_logic;
        eof_out_n				: out std_logic;
        src_rdy_out_n			: out std_logic;
        dst_rdy_in_n			: in std_logic;

        -- Interface to upstream user application        
        data_in					: in std_logic_vector(0 to WR_DWIDTH-1);
        rem_in					: in std_logic_vector(0 to WR_REM_WIDTH-1);
        sof_in_n				: in std_logic;
        eof_in_n				: in std_logic;
        src_rdy_in_n			: in std_logic;
        dst_rdy_out_n			: out std_logic;

        -- FIFO status signals   
        fifostatus_out			: out std_logic_vector(0 to 3)
	);
    end component;
-----------------end component declaration------------------------------  

-----------------signal declaration ------------------------------------
	-- Constants for the message boxes. SW_HW: communication from SW to HW
	--									HW_SW: communication from HW to SW
	constant C_MBOX_HANDLE_SW_HW	: std_logic_vector(0 to 31) := X"00000000";
    constant C_MBOX_HANDLE_HW_SW 	: std_logic_vector(0 to 31) := X"00000001";

	-- State machines
 	type os_state is (	STATE_INIT, 
						STATE_SEND_BUS_COUNTER, 
						STATE_SEND_ETH_COUNTER, 
						STATE_GET_COMMAND, 
						STATE_DECODE);
    signal os_sync_state : os_state	:= STATE_INIT;

	type s_state is (	S_STATE_INIT, 
						S_STATE_WAIT, 
						S_STATE_LOCK, 
						S_STATE_SEND_FIRST, 
						S_STATE_INTERM);
	signal send_to_0_state 			: s_state;
	signal send_to_0_state_next 	: s_state;

	signal send_to_1_state 			: s_state;
	signal send_to_1_state_next 	: s_state;

	signal send_to_2_state 			: s_state;
	signal send_to_2_state_next 	: s_state;

	signal send_to_eth_state 		: s_state;
	signal send_to_eth_state_next 	: s_state;

	type r_state is (	R_STATE_INIT, 
						R_STATE_COUNT);
	signal receive_state			: r_state;
	signal receive_state_next 		: r_state;
	
	signal receive_eth_state		: r_state;
	signal receive_eth_state_next 	: r_state;
	
	-- Ethernet Signals
  	-- Synchronous reset registers in the LocalLink clock domain
    signal ll_pre_reset_i     		: std_logic_vector(5 downto 0);
    signal ll_reset_i         		: std_logic;

    attribute async_reg 			: string;
    attribute async_reg of ll_pre_reset_i	: signal is "true";

    -- Reset signal from the transceiver
    signal resetdone_i        		: std_logic;
    signal resetdone_r         		: std_logic;
    attribute async_reg of resetdone_r 		: signal is "true";

    -- Transceiver output clock (REFCLKOUT at 125MHz)
    signal clk125_o            		: std_logic;

    -- 125MHz clock input to wrappers
    signal clk125              		: std_logic;

    attribute keep 					: boolean;
    attribute keep of clk125   		: signal is true;

    -- Input 125MHz differential clock for transceiver
    signal clk_ds              		: std_logic;


	-- Global asynchronous reset
    signal reset_i             		: std_logic;

    -- LocalLink interface clocking signal
    signal ll_clk_i            		: std_logic;

    -- Signals between sending process and ll tx fifo
    signal tx_ll_data_i        		: std_logic_vector(31 downto 0);
    signal tx_ll_sof_n_i       		: std_logic;
    signal tx_ll_eof_n_i       		: std_logic;
    signal tx_ll_src_rdy_n_i   		: std_logic;
    signal tx_ll_dst_rdy_n_i   		: std_logic;

    --Signals between ll_tx fifo and eth_ll_fifo
    signal eth_tx_ll_data_i        : std_logic_vector(7 downto 0);
    signal eth_tx_ll_sof_n_i       : std_logic;
    signal eth_tx_ll_eof_n_i       : std_logic;
    signal eth_tx_ll_src_rdy_n_i   : std_logic;
    signal eth_tx_ll_dst_rdy_n_i   : std_logic;

	--Signals from eth ll fifo to rx_ll fifo
    signal rx_ll_data_i        		: std_logic_vector(7 downto 0);
    signal rx_ll_sof_n_i       		: std_logic;
    signal rx_ll_eof_n_i       		: std_logic;
    signal rx_ll_src_rdy_n_i   		: std_logic;
    signal rx_ll_dst_rdy_n_i   		: std_logic;

	--Signals from rx_ll fifo to process
	signal rx_data					: std_logic_vector(31 downto 0);
	signal rx_sof_out_n				: std_logic;
	signal rx_eof_out_n				: std_logic;
	signal rx_src_rdy_out_n			: std_logic;
	signal rx_dst_rdy_in_n			: std_logic;
	signal rx_rem					: std_logic_vector(1 downto 0);
  
    -- bus signals (for communication between hw threats)
    signal to_0_data 				: std_logic_vector(0 to 32 - 1);
    signal to_1_data 				: std_logic_vector(0 to 32 - 1);
    signal to_2_data 				: std_logic_vector(0 to 32 - 1);

    signal to_0_sof 				: std_logic;
    signal to_1_sof 				: std_logic;
    signal to_2_sof 				: std_logic;

    signal to_1_eof 				: std_logic;
    signal to_2_eof 				: std_logic;
    signal to_0_eof 				: std_logic;

	signal received_counter 		: natural;
	signal received_counter_next	: natural;

	signal received_eth_counter 	: natural;
	signal received_eth_counter_next: natural;

	signal start_to_0				: std_logic;	
	signal s_0_counter 				: natural;
	signal s_0_counter_next			: natural;

	signal start_to_1				: std_logic;	
	signal s_1_counter 				: natural;
	signal s_1_counter_next			: natural;

	signal start_to_2				: std_logic;	
	signal s_2_counter 				: natural;
	signal s_2_counter_next			: natural;

	signal start_to_eth				: std_logic;	
	signal s_eth_counter 			: natural;
	signal s_eth_counter_next		: natural;

	--end signal declaration

begin
	-- Ethernet setup
	reset_i <= PRE_PHY_RESET;
	PHY_RESET <= not reset_i;

 	-- Generate the clock input to the transceiver
    -- (clk_ds can be shared between multiple EMAC instances, including
    -- multiple instantiations of the EMAC wrappers)
	clkingen : IBUFDS_GTXE1 port map (
    	I     => MGTCLK_P,
      	IB    => MGTCLK_N,
      	CEB   => '0',
      	O     => clk_ds,
      	ODIV2 => open
    );

	-- The 125MHz clock from the transceiver is routed through a BUFG and
    -- input to the MAC wrappers
    -- (clk125 can be shared between multiple EMAC instances, including
    --  multiple instantiations of the EMAC wrappers)
    bufg_clk125 : BUFG port map (
      	I => clk125_o,
      	O => clk125
    );

    -- Clock the LocalLink interface with the globally-buffered 125MHz
    -- clock from the transceiver
    ll_clk_i <= clk125;

	-- Synchronize resetdone_i from the GT in the transmitter clock domain
    gen_resetdone_r : process(ll_clk_i, reset_i)
    begin
      	if (reset_i = '1') then
        	resetdone_r <= '0';
     	elsif ll_clk_i'event and ll_clk_i = '1' then
        	resetdone_r <= resetdone_i;
      	end if;
    end process gen_resetdone_r;

    -- Create synchronous reset in the transmitter clock domain
    gen_ll_reset : process (ll_clk_i, reset_i)
    begin
      	if reset_i = '1' then
       		ll_pre_reset_i <= (others => '1');
        	ll_reset_i     <= '1';
      	elsif ll_clk_i'event and ll_clk_i = '1' then
      		if resetdone_r = '1' then
        		ll_pre_reset_i(0)          <= '0';
        		ll_pre_reset_i(5 downto 1) <= ll_pre_reset_i(4 downto 0);
        		ll_reset_i                 <= ll_pre_reset_i(5);
      		end if;
      end if;
    end process gen_ll_reset;
	-- End Ethernet setup

	--Default assignements
	-- we don't need the memories in this example
  	o_RAMAddr <= (others => '0');
    o_RAMData <= (others => '0');
    o_RAMWE   <= '0';
    o_RAMClk  <= '0';

    o_RAMAddr_x <= (others => '0');
    o_RAMData_x <= (others => '0');
    o_RAMWE_x   <= '0';
    o_RAMClk_x  <= '0';
  
	data_2 <= to_0_data & to_1_data & to_2_data;
	ready_2 <= '0'; -- unused


-----------------start components------------------------------  
  	v6_emac_v1_4_locallink_inst : v6_emac_v1_4_locallink port map (
      	-- 125MHz clock output from transceiver
      	CLK125_OUT               => clk125_o,
      	-- 125MHz clock input from BUFG
      	CLK125                   => clk125,

      	-- LocalLink receiver interface
      	RX_LL_CLOCK              => ll_clk_i,
      	RX_LL_RESET              => ll_reset_i,
      	RX_LL_DATA               => rx_ll_data_i,
      	RX_LL_SOF_N              => rx_ll_sof_n_i,
      	RX_LL_EOF_N              => rx_ll_eof_n_i,
      	RX_LL_SRC_RDY_N          => rx_ll_src_rdy_n_i,
      	RX_LL_DST_RDY_N          => rx_ll_dst_rdy_n_i,
      	RX_LL_FIFO_STATUS        => open,

      	-- Client receiver signals
      	EMACCLIENTRXDVLD         => open, --EMACCLIENTRXDVLD,
      	EMACCLIENTRXFRAMEDROP    => open, --EMACCLIENTRXFRAMEDROP,
      	EMACCLIENTRXSTATS        => open, --EMACCLIENTRXSTATS,
      	EMACCLIENTRXSTATSVLD     => open, --EMACCLIENTRXSTATSVLD,
      	EMACCLIENTRXSTATSBYTEVLD => open, --EMACCLIENTRXSTATSBYTEVLD,

      	-- LocalLink transmitter interface
      	TX_LL_CLOCK              => ll_clk_i,
      	TX_LL_RESET              => ll_reset_i,
      	TX_LL_DATA               => eth_tx_ll_data_i,
     	TX_LL_SOF_N              => eth_tx_ll_sof_n_i,
      	TX_LL_EOF_N              => eth_tx_ll_eof_n_i,
      	TX_LL_SRC_RDY_N          => eth_tx_ll_src_rdy_n_i,
      	TX_LL_DST_RDY_N          => eth_tx_ll_dst_rdy_n_i,

      	-- Client transmitter signals
      	CLIENTEMACTXIFGDELAY     => (others => '0'), --CLIENTEMACTXIFGDELAY,
      	EMACCLIENTTXSTATS        => open, --EMACCLIENTTXSTATS,
      	EMACCLIENTTXSTATSVLD     => open, --EMACCLIENTTXSTATSVLD,
      	EMACCLIENTTXSTATSBYTEVLD => open, --EMACCLIENTTXSTATSBYTEVLD,

      	-- MAC control interface
      	CLIENTEMACPAUSEREQ       => '0', --CLIENTEMACPAUSEREQ,
      	CLIENTEMACPAUSEVAL       => (others => '0'), --CLIENTEMACPAUSEVAL,

      	-- EMAC-transceiver link status
      	EMACCLIENTSYNCACQSTATUS  => open, --EMACCLIENTSYNCACQSTATUS,
      	EMACANINTERRUPT          => open, --EMACANINTERRUPT,

      	-- SGMII interface
      	TXP                      => TXP,
      	TXN                      => TXN,
      	RXP                      => RXP,
      	RXN                      => RXN,
      	PHYAD                    => (others => '0'), --PHYAD,
      	RESETDONE                => resetdone_i,

      	-- SGMII transceiver reference clock buffer input
      	CLK_DS                   => clk_ds,

      	-- Asynchronous reset
     	 RESET                    => reset_i
    );

	TX_FIFO : ll_fifo
    port map (
        areset_in		=> reset,
        write_clock_in 	=> clk,
        read_clock_in	=> ll_clk_i,

        -- Interface to downstream user application
        data_out 		=> eth_tx_ll_data_i,
        rem_out 		=> open,
        sof_out_n 		=> eth_tx_ll_sof_n_i,
        eof_out_n 		=>  eth_tx_ll_eof_n_i,
        src_rdy_out_n 	=> eth_tx_ll_src_rdy_n_i,
        dst_rdy_in_n 	=> eth_tx_ll_dst_rdy_n_i,

        -- Interface to upstream user application        
        data_in 		=> tx_ll_data_i,
        rem_in 			=> (others => '0'),
        sof_in_n 		=> tx_ll_sof_n_i,
        eof_in_n 		=> tx_ll_eof_n_i,
        src_rdy_in_n 	=> tx_ll_src_rdy_n_i,
        dst_rdy_out_n 	=>  tx_ll_dst_rdy_n_i,

        -- FIFO status signals   
        fifostatus_out 	=> open
   	);
 
 	RX_FIFO_1 : ll_fifo
 	generic map(
		WR_DWIDTH 		=> 8,		-- FIFO write data width,
        RD_DWIDTH 		=> 32,      -- FIFO read data width,
        RD_REM_WIDTH 	=> 2,       -- Remainder width of read data
        WR_REM_WIDTH 	=> 1        -- Remainder width of write data
	)
    port map (
        areset_in 		=> reset,
        write_clock_in	=> ll_clk_i,
        read_clock_in 	=> clk,

        data_out 		=> rx_data, 
        rem_out 		=> rx_rem,
        sof_out_n 		=> rx_sof_out_n,
        eof_out_n 		=> rx_eof_out_n,
        src_rdy_out_n 	=> rx_src_rdy_out_n,
        dst_rdy_in_n 	=> rx_dst_rdy_in_n,

        data_in 		=> rx_ll_data_i,
        rem_in 			=> (others => '0'),
        sof_in_n 		=> rx_ll_sof_n_i,
        eof_in_n 		=> rx_ll_eof_n_i,
        src_rdy_in_n 	=> rx_ll_src_rdy_n_i,
        dst_rdy_out_n 	=> rx_ll_dst_rdy_n_i,

        -- FIFO status signals   
        fifostatus_out 	=> open
   	);

------------------------ State machines------------------------------------
	-- Counts the number of packets received on the Bus interface
	receiving : process(busdata_2, bussof_2, buseof_2, bus_src_rdy_2, 
						receive_state, received_counter)
	begin
		bus_dst_rdy_2 <= '1';
		receive_state_next <= receive_state;
		received_counter_next <= received_counter;
		case receive_state is
		when R_STATE_INIT =>
			received_counter_next <= 0;
			receive_state_next <= R_STATE_COUNT;
		
		when R_STATE_COUNT =>	
			if bussof_2 = '1' then
				received_counter_next <= received_counter + 1;
			end if;
		end case;
	end process;

	-- Counts the number of packets received on the Ethernet interface
	receiving_eth : process(rx_data, rx_sof_out_n, rx_eof_out_n, 
							rx_src_rdy_out_n, receive_eth_state, 
							received_eth_counter)
	begin
		rx_dst_rdy_in_n <= '0';
		receive_eth_state_next <= receive_eth_state;
		received_eth_counter_next <= received_eth_counter;
		case receive_state is
		when R_STATE_INIT =>
			received_eth_counter_next <= 0;
			receive_eth_state_next <= R_STATE_COUNT;
		
		when R_STATE_COUNT =>
			if rx_src_rdy_out_n	= '0' then
				if rx_sof_out_n = '0' then
					received_eth_counter_next <= received_eth_counter + 1;
				end if;
			end if;
		end case;
	end process;

	-- Sends packets to the thread in slot 0 as long as the "start_to_eth" is high.
	send_to_0 : process(start_to_0, send_to_0_state, s_0_counter, grant_2)
	begin
		src_rdy_2(0) <= '0';
		to_0_data <= (others => '0');
		sof_2(0) <= '0';
		eof_2(0) <= '0';
		req_2(0) <= '0';
		send_to_0_state_next <= send_to_0_state;
		s_0_counter_next <= s_0_counter;

 	case send_to_0_state is
    when S_STATE_INIT =>
		send_to_0_state_next <= S_STATE_WAIT;
		s_0_counter_next <= 0;

	when S_STATE_WAIT =>
		if start_to_0 = '1' then
			send_to_0_state_next <= S_STATE_LOCK;
		end if;

	when S_STATE_LOCK =>
		req_2(0) <= '1';			
		if grant_2(0) = '0' then
			send_to_0_state_next <= S_STATE_LOCK;
		else
			send_to_0_state_next <= S_STATE_SEND_FIRST;
		end if;

	when S_STATE_SEND_FIRST =>
		src_rdy_2(0) <= '1';
		sof_2(0) <= '1';
		to_0_data <= (others => '1');
		s_0_counter_next <= s_0_counter + 1;
		send_to_0_state_next <= S_STATE_INTERM;
		req_2(0) <= '1';
	
	when S_STATE_INTERM =>
		req_2(0) <= '1';
		src_rdy_2(0) <= '1';
		to_0_data <= (others => '0');
		if s_0_counter = 15 then 
			s_0_counter_next <= 0;
			send_to_0_state_next <= S_STATE_WAIT;
			eof_2(0) <= '1';
		else
			s_0_counter_next <= s_0_counter + 1;
		end if;
	end case;
	end process;

	-- Sends packets to the thread in slot 1 as long as the "start_to_eth" is high.
	send_to_1 : process(start_to_1, send_to_1_state, s_1_counter, grant_2)
	begin
		src_rdy_2(1) <= '0';
		to_1_data <= (others => '0');
		sof_2(1) <= '0';
		eof_2(1) <= '0';
		req_2(1) <= '0';
		send_to_1_state_next <= send_to_1_state;
		s_1_counter_next <= s_1_counter;

 	case send_to_1_state is
    when S_STATE_INIT =>
		send_to_1_state_next <= S_STATE_WAIT;
		s_1_counter_next <= 0;

	when S_STATE_WAIT =>
		if start_to_1 = '1' then
			send_to_1_state_next <= S_STATE_LOCK;
		end if;

	when S_STATE_LOCK =>
		req_2(1) <= '1';			
		if grant_2(1) = '0' then
			send_to_1_state_next <= S_STATE_LOCK;
		else
			send_to_1_state_next <= S_STATE_SEND_FIRST;
		end if;

	when S_STATE_SEND_FIRST =>
		src_rdy_2(1) <= '1';		
		sof_2(1) <= '1';
		to_1_data <= (others => '1');
		s_1_counter_next <= s_1_counter + 1;
		send_to_1_state_next <= S_STATE_INTERM;
		req_2(1) <= '1';
	
	when S_STATE_INTERM =>
		req_2(1) <= '1';
		src_rdy_2(1) <= '1';
		to_1_data <= (others => '0');
		if s_1_counter = 15 then 
			s_1_counter_next <= 0;
			send_to_1_state_next <= S_STATE_WAIT;
			eof_2(1) <= '1';
		else
			s_1_counter_next <= s_1_counter + 1;
		end if;
	end case;
	end process;

	-- Sends packets to the thread in slot 2 as long as the "start_to_eth" is high.
	send_to_2 : process(start_to_2, send_to_2_state, s_2_counter, grant_2)
	begin
		src_rdy_2(2) <= '0';
		to_2_data <= (others => '0');
		sof_2(2) <= '0';
		eof_2(2) <= '0';
		req_2(2) <= '0';
		send_to_2_state_next <= send_to_2_state;
		s_2_counter_next <= s_2_counter;

 	case send_to_2_state is
    when S_STATE_INIT =>
		send_to_2_state_next <= S_STATE_WAIT;
		s_2_counter_next <= 0;

	when S_STATE_WAIT =>
		if start_to_2 = '1' then
			send_to_2_state_next <= S_STATE_LOCK;
		end if;

	when S_STATE_LOCK =>
		req_2(2) <= '1';			
		if grant_2(2) = '0' then
			send_to_2_state_next <= S_STATE_LOCK;
		else
			send_to_2_state_next <= S_STATE_SEND_FIRST;
		end if;

	when S_STATE_SEND_FIRST =>
		src_rdy_2(2) <= '1';
		sof_2(2) <= '1';
		to_2_data <= (others => '1');
		s_2_counter_next <= s_2_counter + 1;
		send_to_2_state_next <= S_STATE_INTERM;
		req_2(2) <= '1';
	
	when S_STATE_INTERM =>
		req_2(2) <= '1';
		src_rdy_2(2) <= '1';
		to_2_data <= (others => '0');
		if s_2_counter = 15 then 
			s_2_counter_next <= 0;
			send_to_2_state_next <= S_STATE_WAIT;
			eof_2(2) <= '1';
		else
			s_2_counter_next <= s_2_counter + 1;
		end if;
	end case;
	end process;

	-- Sends packets to the Ethernet Interface as long as the "start_to_eth" is high.
	send_to_eth : process(start_to_eth, send_to_eth_state, s_eth_counter, tx_ll_dst_rdy_n_i)
	begin
		tx_ll_src_rdy_n_i <= '1';
		tx_ll_data_i <= (others => '0');
		tx_ll_sof_n_i <= '1';
		tx_ll_eof_n_i <= '1';
		send_to_eth_state_next <= send_to_eth_state;
		s_eth_counter_next <= s_eth_counter;

 	case send_to_eth_state is
    when S_STATE_INIT =>
		send_to_eth_state_next <= S_STATE_WAIT;
		s_eth_counter_next <= 0;

	when S_STATE_WAIT =>
		if start_to_eth = '1' then
			send_to_eth_state_next <= S_STATE_SEND_FIRST;
		end if;

	when S_STATE_SEND_FIRST =>
		tx_ll_src_rdy_n_i <= '0';
		tx_ll_sof_n_i <= '0';
		tx_ll_data_i <= (others => '1');
		if tx_ll_dst_rdy_n_i = '0' then
			s_eth_counter_next <= s_eth_counter + 1;
			send_to_eth_state_next <= S_STATE_INTERM;
		end if;
	
	when S_STATE_INTERM =>
		tx_ll_src_rdy_n_i <= '0';
		tx_ll_data_i <= (others => '1');
		if tx_ll_dst_rdy_n_i = '0' then
			if s_eth_counter = 15 then
				s_eth_counter_next <= 0;
				send_to_eth_state_next <= S_STATE_WAIT;
				tx_ll_eof_n_i <= '0';
			else
				s_eth_counter_next <= s_eth_counter + 1;
			end if;
		end if;
	when others => 
		send_to_eth_state_next <= S_STATE_INIT;
	end case;
	end process;


    -- memzing process
    -- updates all the registers
    proces_mem : process(clk, reset)
    begin
        if reset = '1' then
			send_to_0_state <= S_STATE_INIT;
			s_0_counter <= 0;
			send_to_1_state <= S_STATE_INIT;
			s_1_counter <= 0;
			send_to_2_state <= S_STATE_INIT;
			s_2_counter <= 0;
			send_to_eth_state <= S_STATE_INIT;
			s_eth_counter <= 0;

			receive_state <= R_STATE_INIT;
			received_counter <= 0;
			receive_eth_state <= R_STATE_INIT;
			received_eth_counter <= 0;


        elsif rising_edge(clk) then
			send_to_0_state <= send_to_0_state_next;
			s_0_counter <= s_0_counter_next;
			send_to_1_state <= send_to_1_state_next;
			s_1_counter <= s_1_counter_next;
			send_to_2_state <= send_to_2_state_next;
			s_2_counter <= s_2_counter_next;
			send_to_eth_state <= send_to_eth_state_next;
			s_eth_counter <= s_eth_counter_next;

			receive_state <= receive_state_next;
			received_counter <= received_counter_next;
			receive_eth_state <= receive_eth_state_next;
			received_eth_counter <= received_eth_counter_next;

        end if;
    end process;


    -- OS synchronization state machine (the reconOS state machine)
    -- this has to have this special format!
    state_proc : process(clk, reset)
    variable success		: boolean;
    variable done	        : boolean;
	variable sw_command 	: std_logic_vector(0 to C_OSIF_DATA_WIDTH - 1);

    begin
        if reset = '1' then
            reconos_reset_with_signature(o_osif, i_osif, X"ABCDEF01");
            os_sync_state <= STATE_INIT;
			start_to_0 <= '0';
			start_to_1 <= '0';
			start_to_2 <= '0';

        elsif rising_edge(clk) then
		reconos_begin(o_osif, i_osif);
        if reconos_ready(i_osif) then
        case os_sync_state is
        when STATE_INIT =>
			os_sync_state <= STATE_GET_COMMAND;
			start_to_0 <= '0';
			start_to_1 <= '0';
			start_to_2 <= '0';

        when STATE_SEND_BUS_COUNTER =>
			reconos_mbox_put(done, success, o_osif, i_osif, C_MBOX_HANDLE_HW_SW, 
					std_logic_vector(to_unsigned(received_counter,C_OSIF_DATA_WIDTH)));
	        if done then
    	    	os_sync_state <= STATE_GET_COMMAND;
        	end if;

		when STATE_SEND_ETH_COUNTER =>
			reconos_mbox_put(done, success, o_osif, i_osif, C_MBOX_HANDLE_HW_SW, 
					std_logic_vector(to_unsigned(received_eth_counter,C_OSIF_DATA_WIDTH)));
	        if done then
    	    	os_sync_state <= STATE_GET_COMMAND;
        	end if;

        when STATE_GET_COMMAND =>
			reconos_mbox_get(done, success, o_osif, i_osif, C_MBOX_HANDLE_SW_HW, sw_command);
            if done and success then
                os_sync_state <= STATE_DECODE;
            end if;

        when STATE_DECODE =>
            --default: command not known
            os_sync_state <= STATE_GET_COMMAND;
			-- element 0 indicates whether this thread should send to slot 0,
			-- element 1 indicates whether this thread should send to slot 1,
			-- element 6 indicates whether the receive counter from the bus interface 
			-- should be reported
			-- element 7 indicates whether the receive counter from the eth interface 
			-- should be reported. Note, 6 and 7 can only be specified exclusivly. E.g.
			-- only one counter value can be reported with one request.		

			if sw_command(6) = '1' then
				os_sync_state <= STATE_SEND_BUS_COUNTER;
			elsif sw_command(7) = '1' then
				os_sync_state <= STATE_SEND_ETH_COUNTER;
			else
				if sw_command(0) = '1' then
					start_to_0 <= '1';
				else
					start_to_0 <= '0';
				end if;

				if sw_command(1) = '1' then
					start_to_1 <= '1';
				else
					start_to_1 <= '0';
				end if;

				if sw_command(2) = '1' then
					start_to_2 <= '1';
				else
					start_to_2 <= '0';
				end if;

				if sw_command(3) = '1' then
					start_to_eth <= '1';
				else
					start_to_eth <= '0';
				end if;

			end if;

        when others =>
            os_sync_state <= STATE_INIT;
        end case;
        end if;
        end if;
    end process;



end Behavioral;


