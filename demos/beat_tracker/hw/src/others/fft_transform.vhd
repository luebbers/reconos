library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                                                                            --
--                                                                            --
--        //////   /////////    ///////      ///////                          --
--       //           //       //     //     //    //                         --
--       //           //       //     //     //    //                         --
--        /////       //       //     //     ///////                          --
--            //      //       //     //     //                               --
--            //      //       //     //     //                               --
--       //////       //        ///////      //                               --
--                                                                            -- 
--                                                                            --
--------------------------------------------------------------------------------
-------------------------------------------------------------------------------- 
--                                                                            -- 
--                                                                            -- --                                                                            --
--  FFT TRANSFORMATION OF 2048 SAMPLES (16 bit wide, signed)                  --
--  OUTPUT: 2048 FFT VALUES                                                   --
--          - real component      (16 bit wide)                               --
--          - imaginary component (16 bit wide)                               --
--                                                                            --
--  Author: Markus Happe                                                      --
--                                                                            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


entity fft_transform is

	generic (
		C_BURST_AWIDTH : integer := 12;
		C_BURST_DWIDTH : integer := 32
	);

  	port (
		clk    : in  std_logic;
		reset  : in  std_logic;
		i_osif : in  osif_os2task_t;
		o_osif : out osif_task2os_t;

		-- burst ram interface
		o_RAMAddr : out std_logic_vector(0 to C_BURST_AWIDTH-1);
		o_RAMData : out std_logic_vector(0 to C_BURST_DWIDTH-1);
		i_RAMData : in  std_logic_vector(0 to C_BURST_DWIDTH-1);
		o_RAMWE   : out std_logic;
		o_RAMClk  : out std_logic
	);
end fft_transform;


architecture Behavioral of fft_transform is

	-- fft component (uses radix-4 algorithm)
	component xfft_v5_0
	port (
		clk	: IN std_logic;
		ce	: IN std_logic;
		sclr	: IN std_logic;
		start	: IN std_logic;
		xn_re	: IN std_logic_vector(15 downto 0);
		xn_im	: IN std_logic_vector(15 downto 0);
		fwd_inv	: IN std_logic;
		fwd_inv_we	: IN std_logic;
		scale_sch	: IN std_logic_vector(13 downto 0);
		scale_sch_we	: IN std_logic;
		rfd	: OUT std_logic;
		xn_index	: OUT std_logic_vector(6 downto 0);
		busy	: OUT std_logic;
		edone	: OUT std_logic;
		done	: OUT std_logic;
		dv	: OUT std_logic;
		xk_index	: OUT std_logic_vector(6 downto 0);
		xk_re	: OUT std_logic_vector(15 downto 0);
		xk_im	: OUT std_logic_vector(15 downto 0));
	end component;


	attribute keep_hierarchy               : string;
	attribute keep_hierarchy of Behavioral : architecture is "true";

	-- ReconOS thread-local mailbox handles
	constant C_MB_START : std_logic_vector(0 to 31) := X"00000000";
	constant C_MB_DONE  : std_logic_vector(0 to 31) := X"00000001";

	-- signals for fft core
	-- incoming signals
	signal ce	: std_logic := '0';
	signal sclr	: std_logic := '0';
	signal start	: std_logic := '0';
	signal xn_re	: std_logic_vector(15 downto 0) := (others => '0');
	signal xn_im	: std_logic_vector(15 downto 0) := (others => '0');
	signal fwd_inv	: std_logic := '1';
	signal fwd_inv_we	: std_logic := '0';
	signal scale_sch	: std_logic_vector(13 downto 0) := "01101010101010";
	signal scale_sch_we	: std_logic := '0';
	--outgoing signals
	signal rfd	: std_logic;
	signal xn_index	: std_logic_vector(6 downto 0);
	signal busy	: std_logic;
	signal edone	: std_logic;
	signal done	: std_logic;
	signal dv	: std_logic;
	signal xk_index	: std_logic_vector(6 downto 0);
	signal xk_re	: std_logic_vector(15 downto 0);
	signal xk_im	: std_logic_vector(15 downto 0);
  
	-- states
	type t_state is
	(
		init,
		wait_for_message,
		wait_for_message_2,
		read_input,
		read_input_2,
		read_input_3,
		read_input_4,
		read_input_5,
		read_input_6,
		read_input_dec,
		make_fft,
		write_output,
		write_output_2,
		write_output_3,
		write_output_4,
		write_output_5,
		write_output_6,
		write_output_dec,
		write_output_get,
		write_output_wait,
		write_output_write,
		write_output_write_done,		
		send_message
	);

	-- current state
	signal state : t_state := init;
  
	signal ram_data : std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	signal information_struct	: std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0'); 
	signal input_address	: std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	signal output_address	: std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	signal current_input_address	: std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
	signal current_output_address	: std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0');
  	signal local_ram_address_in	: std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0'); 
 	signal local_ram_address_out	: std_logic_vector(0 to C_OSIF_DATA_WIDTH-1) := (others => '0'); 
 	signal local_ram_address_if	: std_logic_vector(0 to C_BURST_AWIDTH-1)		:= (others => '0'); 
 	signal counter	: std_logic_vector(0 to 6) := (others => '0');
	signal my_xn_index	: std_logic_vector(6 downto 0);
	signal address : std_logic_vector(0 to C_BURST_AWIDTH-1);
	
	signal local_ram_address_in_if : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');

	signal fft_en	: std_logic := '0'; -- handshake signals
 	signal fft_done	: std_logic := '0';
	
	signal o_RAMAddr_fft : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');
	signal o_RAMAddr_fsm : std_logic_vector(0 to C_BURST_AWIDTH-1) := (others => '0');

	signal o_RAMData_fft : std_logic_vector(0 to C_BURST_DWIDTH-1) := (others => '0');
	signal o_RAMData_fsm : std_logic_vector(0 to C_BURST_DWIDTH-1) := (others => '0');

	signal o_RAMWE_fft : std_logic := '0';
	signal o_RAMWE_fsm : std_logic := '0';	

	-- 1st 16 bits: real component, 2nd 16 bits: imaginary component
	--type t_ram is array (1023 downto 0) of std_logic_vector(31 downto 0);
	--signal fft_ram    : t_ram; -- samples memory
  

begin

	-- fft core
	my_fft_core : xfft_v5_0
		port map (
			clk	=> clk,
			ce	=> ce,
			sclr	=> sclr,
			start	=> start,
			xn_re	=> xn_re,
			xn_im	=> xn_im,
			fwd_inv	=> fwd_inv,
			fwd_inv_we	=> fwd_inv_we,
			scale_sch	=> scale_sch,
			scale_sch_we	=> scale_sch_we,
			rfd	=> rfd,
			xn_index	=> xn_index,
			busy	=> busy,
			edone	=> edone,
			done	=> done,
			dv	=> dv,
			xk_index	=> xk_index,
			xk_re	=> xk_re,
			xk_im	=> xk_im
		);

	-- clock for burst ram
	o_RAMClk <= clk;
	
	-- switch for o_RAMAddr
	o_RAMAddr <= o_RAMAddr_fft(0 to C_BURST_AWIDTH-2) & not o_RAMAddr_fft(C_BURST_AWIDTH-1) 
			when (fft_en = '1') else o_RAMAddr_fsm(0 to C_BURST_AWIDTH-2) & not o_RAMAddr_fsm(C_BURST_AWIDTH-1);
			
	o_RAMData <= o_RAMData_fft  when (fft_en = '1') else o_RAMData_fsm;
	o_RAMWE   <= o_RAMWE_fft    when (fft_en = '1') else o_RAMWE_fsm;

	fft_proc : process(clk, reset, fft_en)
		variable step : natural range 0 to 9;
	begin

		if (reset='1' or fft_en='0') then

			fft_done <= '0';
			start	<= '0';
			o_RAMWE_fft	<= '0';
			xn_im	<= (others=>'0');
			xn_re	<= (others=>'0');
			ce 	<= '0';
			fwd_inv	<= '1';
			sclr	<= '1';
			step	:= 0;

		elsif (rising_edge(clk)) then

			case step is	
				
				-- fill fft core with data
				when 0 => -- set start signal
					sclr	<= '0';	
					ce	<= '1';					
					fwd_inv	<= '1';
					fwd_inv_we <= '1';
					o_RAMWE_fft <= '0';
					o_RAMAddr_fft <= (others => '0');
					address <= (others => '0');
					xn_im    <= (others=>'0');
					step := step + 1;

				when 1 => -- set start signal				
					start	<= '1';
					fwd_inv_we <= '0';
					o_RAMWE_fft <= '0';
					--if (rfd = '1') then
					my_xn_index <= xn_index;					
					step := step + 1;
					--end if;


				when 2 => -- start filling the incoming data pipeline 
					-- (read left sample (16 of 32 bits));	
					xn_re(15 downto 0) <= i_RAMData(16)&i_RAMData(17)&i_RAMData(18)&i_RAMData(19)&i_RAMData(20)&i_RAMData(21)&i_RAMData(22)&i_RAMData(23)&i_RAMData(24)&i_RAMData(25)&i_RAMData(26)&i_RAMData(27)&i_RAMData(28)&i_RAMData(29)&i_RAMData(30)&i_RAMData(31);
					o_RAMAddr_fft <= address + 1;
					address <= address + 1;
					step := step + 1;

				when 3 => -- start filling the incoming data pipeline
					-- (read right sample (16 of 32 bits));
					xn_re(15 downto 0) <= i_RAMData(0)&i_RAMData(1)&i_RAMData(2)&i_RAMData(3)&i_RAMData(4)&i_RAMData(5)&i_RAMData(6)&i_RAMData(7)&i_RAMData(8)&i_RAMData(9)&i_RAMData(10)&i_RAMData(11)&i_RAMData(12)&i_RAMData(13)&i_RAMData(14)&i_RAMData(15);
					my_xn_index <= xn_index + 1;
					step := step + 1;

				when 4 => -- samples are arriving (read left sample (16 of 32 bits))	
					start <= '0';	
					xn_re(15 downto 0) <= i_RAMData(16)&i_RAMData(17)&i_RAMData(18)&i_RAMData(19)&i_RAMData(20)&i_RAMData(21)&i_RAMData(22)&i_RAMData(23)&i_RAMData(24)&i_RAMData(25)&i_RAMData(26)&i_RAMData(27)&i_RAMData(28)&i_RAMData(29)&i_RAMData(30)&i_RAMData(31);
					my_xn_index <= xn_index + 1;
					o_RAMAddr_fft <= address + 1; 
					address <= address + 1;
					step := step + 1;

				when 5 => -- samples are arriving (read right sample (16 of 32 bits));
					xn_re(15 downto 0) <= i_RAMData(0)&i_RAMData(1)&i_RAMData(2)&i_RAMData(3)&i_RAMData(4)&i_RAMData(5)&i_RAMData(6)&i_RAMData(7)&i_RAMData(8)&i_RAMData(9)&i_RAMData(10)&i_RAMData(11)&i_RAMData(12)&i_RAMData(13)&i_RAMData(14)&i_RAMData(15);
					if (busy='0') then
						my_xn_index <= xn_index + 1;
						step := step - 1;
					else					
						step := step + 1;
					end if;

				-- wait for results
				when 6 =>
					if (edone = '1') then
						o_RAMAddr_fft <= address - 1;
						address <= address - 1;
						start <= '1';
						o_RAMWE_fft <= '0';
						step := step + 1;
					end if;				

				-- get data and write them back
				when 7 =>
					--o_RAMData_fft(0 to 31) <= xk_re(15 downto 0) & xk_im(15 downto 0);
					o_RAMData_fft(0 to 31) <= xk_re(15)&xk_re(14)&xk_re(13)&xk_re(12)&xk_re(11)&xk_re(10)&xk_re(9)&xk_re(8)&xk_re(7)&xk_re(6)&xk_re(5)&xk_re(4)&xk_re(3)&xk_re(2)&xk_re(1)&xk_re(0)&xk_im(15)&xk_im(14)&xk_im(13)&xk_im(12)&xk_im(11)&xk_im(10)&xk_im(9)&xk_im(8)&xk_im(7)&xk_im(6)&xk_im(5)&xk_im(4)&xk_im(3)&xk_im(2)&xk_im(1)&xk_im(0);
					--o_RAMAddr_fft(0 to 11) <= "0" & xk_index(10 downto 0);
					o_RAMAddr_fft(0 to 11) <= "00000"&xk_index(6)&xk_index(5)&xk_index(4)&xk_index(3)&xk_index(2)&xk_index(1)&xk_index(0);
					o_RAMWE_fft <= '1';	
					if (busy='1') then				
						step := step + 1;
					end if;

				when 8 =>
					--o_RAMData_fft(0 to 31) <= xk_re(15 downto 0) & xk_im(15 downto 0);
					o_RAMData_fft(0 to 31) <= xk_re(15)&xk_re(14)&xk_re(13)&xk_re(12)&xk_re(11)&xk_re(10)&xk_re(9)&xk_re(8)&xk_re(7)&xk_re(6)&xk_re(5)&xk_re(4)&xk_re(3)&xk_re(2)&xk_re(1)&xk_re(0)&xk_im(15)&xk_im(14)&xk_im(13)&xk_im(12)&xk_im(11)&xk_im(10)&xk_im(9)&xk_im(8)&xk_im(7)&xk_im(6)&xk_im(5)&xk_im(4)&xk_im(3)&xk_im(2)&xk_im(1)&xk_im(0);
					--o_RAMAddr_fft(0 to 11) <= "0" & xk_index(10 downto 0);
					o_RAMAddr_fft(0 to 11) <= "00000"&xk_index(6)&xk_index(5)&xk_index(4)&xk_index(3)&xk_index(2)&xk_index(1)&xk_index(0);
					--o_RAMWE_fft <= '1';
					if (dv='0') then
						o_RAMWE_fft <= '0';			
						step := step + 1;
					else
						o_RAMWE_fft <= '1';
					end if;


				-- finish fft process
				when 9 =>
					o_RAMWE_fft	<= '0';	
					start		<= '0';	
					sclr		<= '1';			
					fft_done	<= '1';
				end case;				

		end if;

	end process;


	-----------------------------------------------------------------------------
	--
	--  ReconOS State Machine for Observation: 
	--  
	-----------------------------------------------------------------------------

	fsm_proc : process(clk, reset)	
		-- done signal for Reconos methods
		variable done : boolean;
		variable success : boolean; 
		variable next_state : t_state := wait_for_message;
	begin

	if (reset = '1') then

		reconos_reset( o_osif, i_osif );
		state <= init;
		o_RAMAddr_fsm <= (others=>'0');
		o_RAMWE_fsm <= '0';
		next_state := wait_for_message;
		done := false;
	elsif (rising_edge(clk)) then


		reconos_begin( o_osif, i_osif );
		if (reconos_ready( i_osif )) then
			-- Transition to next state
			case (state) is

        			-- 1. read information struct
				when init =>
					reconos_get_init_data_s (done, o_osif, i_osif, information_struct);
					next_state := wait_for_message;

				-- 2. wait for messages (input/output addresses) (do a fft)
				when wait_for_message =>
					reconos_mbox_get_s(done,success,o_osif,i_osif,C_MB_START,input_address);
					counter	<= (others => '0');
					local_ram_address_in	<= (others=>'0');
					local_ram_address_out	<= (others=>'0');	
					local_ram_address_in_if <= (others=>'0');
					next_state := wait_for_message_2;

				when wait_for_message_2 =>
					reconos_mbox_get_s(done,success,o_osif,i_osif,C_MB_START,output_address);
					current_input_address <= input_address;
					next_state := read_input;

				-- 3. read input samples from input_address (only real components expected)
				when read_input =>
					--reconos_read_burst(done,o_osif,i_osif,local_ram_address_in,current_input_address);
					--next_state := read_input_dec;
					next_state := read_input_2;
					
				when read_input_2 =>
					reconos_read_s(done,o_osif,i_osif,current_input_address,ram_data);
					next_state := read_input_3;

				when read_input_3 =>
					-- wait
					next_state := read_input_4;

				when read_input_4 =>
					-- wait	
					next_state := read_input_5;

				when read_input_5 =>
					-- write value to local ram
					o_RAMWE_fsm <= '1';
					o_RAMData_fsm <= ram_data;
					o_RAMAddr_fsm <= local_ram_address_in_if;
					next_state := read_input_6;
					
				when read_input_6 =>
					-- wait		
					o_RAMWE_fsm <= '0';
					--local_ram_address_in <= local_ram_address_in 	+ 4;
					current_input_address <= current_input_address 	+ 4;
					local_ram_address_in_if <= local_ram_address_in_if + 1;
					if (counter < 63) then
						counter <= counter + 1;
						next_state := read_input_2;
					else
						fft_en <= '1';
						next_state := make_fft;
						-- TODO: CHANGE CHANGE CHANGE: Remove again
						--counter	<= (others => '0');
						--current_output_address <= output_address;
						--next_state := write_output;
					end if;					

				when read_input_dec =>
					if (counter < 3) then
						counter <= counter + 1;
						local_ram_address_in	<= local_ram_address_in		+ 128;
						current_input_address	<= current_input_address	+ 128;
						next_state := read_input;
					else
						next_state := make_fft;
						fft_en <= '1';
						-- CHANGE CHANGE CHANGE - DEBUG
						--counter	<= (others => '0');
						--current_output_address <= output_address;
						--next_state := write_output;
					end if;
					--next_state := read_input_2;

				-- 4. make fft for samples
				when make_fft =>
					if (fft_done = '1') then -- TODO CHANGE CHANGE CHANGE
						current_output_address <= output_address;
						local_ram_address_if <= (others => '0');
						fft_en	<= '0';
						counter	<= (others => '0');
						next_state := write_output;
					end if;

				-- 5. write fft results to output_address
				when write_output =>
					--reconos_write_burst(done,o_osif,i_osif,local_ram_address_out,current_output_address);
					--next_state := write_output_dec;
					next_state := write_output_2;

				when write_output_dec =>
					if (counter < 3) then
						counter <= counter + 1;
						current_output_address	<= current_output_address	+ 128;
						local_ram_address_out	<= local_ram_address_out	+ 128;
						next_state := write_output;
					else
						next_state := send_message;
					end if;
					--next_state := write_output_2;
					
					
				when write_output_2 =>
					o_RAMAddr_fsm <= (others=>'0');
					next_state := write_output_3;

				when write_output_3 =>
					-- wait
					next_state := write_output_4;
					
				when write_output_4 =>				
					reconos_write(done,o_osif,i_osif,current_output_address, i_RAMData);
					next_state := write_output_5;
					
				when write_output_5 =>
					-- wait
					next_state := write_output_6;	

				when write_output_6 =>
					if (counter < 127) then
						o_RAMAddr_fsm <= o_RAMAddr_fsm + 1;
						counter <= counter + 1;
						current_output_address <= current_output_address + 4;
						next_state := write_output_3;				
					else
						next_state := send_message;
					end if;					
					

				-- 6. send message (work done)
				when send_message =>
					reconos_mbox_put(done,success,o_osif,i_osif,C_MB_DONE,input_address);
					next_state := wait_for_message;

				when others => 
					next_state := wait_for_message;

				end case;
				if done then
					state <= next_state;
				end if;
			end if;
		end if;
   end process;
end Behavioral;
