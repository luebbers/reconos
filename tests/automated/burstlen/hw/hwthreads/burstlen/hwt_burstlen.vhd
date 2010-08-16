--!
--! \file hwt_burstlen.vhd
--!
--! Automated test for variable burstlengths (reconos_burst_read_/write_l)
--!
--! \author     Enno Luebbers   <enno.luebbers@upb.de>
--! \date       27.06.2008
--
-- Adapted from hwt_memcopy.vhd (Andreas Agne).
--
-- This file is part of the ReconOS project <http://www.reconos.de>.
-- University of Paderborn, Computer Engineering Group.
--
-- (C) Copyright University of Paderborn 2008. Permission to copy,
-- use, modify, sell and distribute this software is granted provided
-- this copyright notice appears in all copies. This software is
-- provided "as is" without express or implied warranty, and with no
-- claim as to its suitability for any purpose.
--
-----------------------------------------------------------------------------
--
-- Major Changes:
--
-- 27.06.2008   Enno Luebbers   File created.


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

entity hwt_burstlen is

	generic (
		C_BURST_AWIDTH : integer := 12;
		C_BURST_DWIDTH : integer := 32
	);
	
	port (
		clk : in std_logic;
		reset : in std_logic;
		i_osif : in osif_os2task_t;
		o_osif : out osif_task2os_t;

		-- burst ram interface
		o_RAMAddr : out std_logic_vector( 0 to C_BURST_AWIDTH-1 );
		o_RAMData : out std_logic_vector( 0 to C_BURST_DWIDTH-1 );
		i_RAMData : in std_logic_vector( 0 to C_BURST_DWIDTH-1 );
		o_RAMWE   : out std_logic;
		o_RAMClk  : out std_logic
	);
	
end entity;

architecture Behavioral of hwt_burstlen is

	attribute keep_hierarchy : string;
	attribute keep_hierarchy of Behavioral: architecture is "true";

	type t_state is ( STATE_INIT,
							STATE_READ_SRC,
							STATE_READ_DST,
							STATE_READ_SIZE,
                                                        STATE_READ_BURSTLEN,
							STATE_READ_STEP,
							STATE_READ_BURST,
							STATE_WRITE_BURST,
							STATE_DONE,
							STATE_FINAL);
	
	signal state : t_state;
begin

	state_proc: process( clk, reset )
		variable args : std_logic_vector(31 downto 0);
		variable src : std_logic_vector(31 downto 0);
		variable dst : std_logic_vector(31 downto 0);
		variable size : std_logic_vector(31 downto 0);
                variable burstlen_slv : std_logic_vector(31 downto 0);
                variable burstlen : natural range 0 to 16;
                variable step : std_logic_vector(31 downto 0);
		variable tmp : std_logic_vector(31 downto 0);
		variable done : boolean;
		variable success : boolean;
	begin
		if reset = '1' then
			reconos_reset( o_osif, i_osif );
			state <= STATE_INIT;
			args := (others => '0');
			src := (others => '0');
			dst := (others => '0');
			size := (others => '0');
                        burstlen_slv := (others => '0');
                        burstlen := 0;
                        step := (others => '0');
			tmp := (others => '0');
			done := false;
			success := false;
		elsif rising_edge( clk ) then
			reconos_begin( o_osif, i_osif );
			if reconos_ready( i_osif ) then
				case state is
					when STATE_INIT =>
						reconos_get_init_data(done, o_osif, i_osif, args);
						if done then state <= STATE_READ_SRC; end if;
				
					when STATE_READ_SRC =>
						reconos_read(done, o_osif, i_osif, args, src);
						if done then state <= STATE_READ_DST; end if;
						
					when STATE_READ_DST =>
						reconos_read(done, o_osif, i_osif, args + 4, dst);
						if done then state <= STATE_READ_SIZE; end if;
						
					when STATE_READ_SIZE =>
						reconos_read(done, o_osif, i_osif, args + 8, size);
						if done then state <= STATE_READ_BURSTLEN; end if;

					when STATE_READ_BURSTLEN =>
						reconos_read(done, o_osif, i_osif, args + 12, burstlen_slv);
                                                burstlen := CONV_INTEGER(UNSIGNED(burstlen_slv));
						if done then state <= STATE_READ_STEP; end if;
					
                                        when STATE_READ_STEP =>
						reconos_read(done, o_osif, i_osif, args + 16, step);
						if done then state <= STATE_READ_BURST; end if;
						
                                    -------------------------------------------------------------------------

					when STATE_READ_BURST =>
                                                if (size > 0) then
							reconos_read_burst_l (done, o_osif, i_osif, X"00000000", src, burstlen);
                                                        if done then
								state <= STATE_WRITE_BURST;
								src := src + step;
							end if;
						else
							state <= STATE_DONE;
						end if;
						
					when STATE_WRITE_BURST =>
						reconos_write_burst_l (done, o_osif, i_osif, X"00000000", dst, burstlen);
						if done then
							state <= STATE_READ_BURST;
							dst := dst + step;
							size := size - step;
						end if;
					
					when STATE_DONE =>
						reconos_write(done, o_osif, i_osif, args + 8, X"00000000");
						state <= STATE_FINAL;
				
					when STATE_FINAL =>
						state <= STATE_FINAL;
								
						
						
				end case;
			end if;
		end if;
	end process;
end architecture;
