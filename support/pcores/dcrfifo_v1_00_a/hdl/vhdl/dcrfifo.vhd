--!
--! \file dcrfifo.vhd
--!
--! Implementation of a FIFO with DCR bus attachment.
--!
--! control register : BASE_ADDR
--!     when read: 
--!                bit 31 = underrun indicator (initial: 0)
--!                bit 30 = overflow indicator (initial: 0)
--!                bit 28 = write only indicator (initial: 1)
--!                bits 0 to 27 = number of words in FIFO (initial: 0)
--!
--!     Writing 0xAFFEBEAF to the control register clears the write only bit.
--!     Reading from the FIFO then becomes possible. Writing 0xAFFEDEAD to
--!     the control register resets the FIFO. This is at the moment the only
--!     way to clear the underrun and overflow bits. Writing any other value
--!     to the control register sets the write only bit. This is a precaution
--!     to protect the FIFO from crazy operating systems.
--!                 
--! fifo resgister   : BASE_ADDR + 1
--!     Reading from the fifo register returns the first word in the FIFO.
--!     If the FIFO is empty the result is undefined and the underrun bit is
--!     set.
--!     When the write only bit is cleared, reading from the fifo register
--!     also advances to the next word in the fifo. IF the write only bit is
--!     set, reads from the fifo register do not alter the contents of the
--!     FIFO.
--!     Writing a word to the fifo register puts that word into the FIFO
--!     unless no more space is left. In that case the value written is
--!     discarded and the overflow bit is set.   
--!
--!
--! \author     Andreas Agne   <agne@upb.de>
--! \date       18.02.2009
--
-----------------------------------------------------------------------------
-- %%%RECONOS_COPYRIGHT_BEGIN%%%
-- 
-- This file is part of ReconOS (http://www.reconos.de).
-- Copyright (c) 2006-2010 The ReconOS Project and contributors (see AUTHORS).
-- All rights reserved.
-- 
-- ReconOS is free software: you can redistribute it and/or modify it under
-- the terms of the GNU General Public License as published by the Free
-- Software Foundation, either version 3 of the License, or (at your option)
-- any later version.
-- 
-- ReconOS is distributed in the hope that it will be useful, but WITHOUT ANY
-- WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
-- FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
-- details.
-- 
-- You should have received a copy of the GNU General Public License along
-- with ReconOS.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- %%%RECONOS_COPYRIGHT_END%%%
-----------------------------------------------------------------------------
--
-- Major changes
-- 18.02.2009  Andreas Agne        Initial implementation
---


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dcrfifo is
	generic (
		C_DCR_BASEADDR :     std_logic_vector := "1111111111";
		C_DCR_HIGHADDR :     std_logic_vector := "0000000000";
		C_DCR_AWIDTH   :     integer          := 10;
		C_DCR_DWIDTH   :     integer          := 32;
		C_NUM_REGS     :     integer          := 2;
		C_FIFO_AWIDTH  :     integer          := 15
	);
	port ( -- the DCR bus interface
		clk            : in  std_logic;
		reset          : in  std_logic;             -- high active synchronous
		o_dcrAck       : out std_logic;
		o_dcrDBus      : out std_logic_vector(C_DCR_DWIDTH-1 downto 0);
		i_dcrABus      : in  std_logic_vector(C_DCR_AWIDTH-1 downto 0);
		i_dcrDBus      : in  std_logic_vector(C_DCR_DWIDTH-1 downto 0);
		i_dcrRead      : in  std_logic;
		i_dcrWrite     : in  std_logic
	);

end dcrfifo;

architecture Behavioral of dcrfifo is

	-- address of status register (read only)
	constant ADDR_COUNT : std_logic_vector := C_DCR_BASEADDR;
	-- address of fifo register (read/write)
	constant ADDR_FIFO  : std_logic_vector := C_DCR_BASEADDR + 1;
	-- fifo count width
	constant FIFO_DEPTH : integer := 2**C_FIFO_AWIDTH;	
	
	-- fifo memory type
	type t_ram is array (FIFO_DEPTH-1 downto 0) of std_logic_vector(C_DCR_DWIDTH-1 downto 0);
		
	-- fifo memory
	signal fifo_mem : t_ram;
	-- fifo output
	signal fifo_out : std_logic_vector(C_DCR_DWIDTH-1 downto 0);
	-- fifo input
	signal fifo_in : std_logic_vector(C_DCR_DWIDTH-1 downto 0);
	-- fifo output address register
	signal fifo_outaddr : std_logic_vector(C_FIFO_AWIDTH-1 downto 0);
	-- fifo input address register
	signal fifo_inaddr : std_logic_vector(C_FIFO_AWIDTH-1 downto 0);
	-- fifo count register
	signal fifo_count : std_logic_vector(C_FIFO_AWIDTH-1 downto 0);
	-- fifo write_enable signal
	signal fifo_we : std_logic;
	-- advance to next output word
	signal fifo_next : std_logic;
	-- fifo full indicator
	signal fifo_full : std_logic;
	-- fifo empty indicator
	signal fifo_empty : std_logic;
	-- fifo overflow
	signal fifo_overflow : std_logic;
	-- fifo underrun
	signal fifo_underrun : std_logic;
	-- fifo contol
	signal fifo_ctrl : std_logic;
	-- fifo write only
	signal fifo_wronly_set : std_logic;
	signal fifo_wronly : std_logic;
	-- fifo reset
	signal fifo_reset : std_logic;
	
	-- registers indicating type of request
	signal readStateReg  : std_logic;
	signal writeStateReg : std_logic; 
	signal readFifoReg   : std_logic;
	signal writeFifoReg  : std_logic;

	-- asynchronous signals indicating type of request (input to the registers above)
	signal readState  : std_logic;
	signal writeState : std_logic;
	signal readFifo   : std_logic;
	signal writeFifo  : std_logic;
begin
	-- asynchronously determine the type of request
	readState  <= '1' when i_dcrRead  = '1' and i_dcrABus = ADDR_COUNT else '0';
	writeState <= '1' when i_dcrWrite = '1' and i_dcrABus = ADDR_COUNT else '0';
	readFifo   <= '1' when i_dcrRead  = '1' and i_dcrABus = ADDR_FIFO  else '0';
	writeFifo  <= '1' when i_dcrWrite = '1' and i_dcrABus = ADDR_FIFO  else '0';
	-- DCR ack
	o_dcrAck <= readStateReg or readFifoReg or writeFifoReg or writeStateReg;
	
	-- fifo advance to next word
	fifo_next <= readFifoReg and (not readFifo);
	-- fifo write enable
	fifo_we   <= (not writeFifoReg) and writeFifo;
	-- control register access
	fifo_ctrl <= (not writeStateReg) and writeState;
	
	-- connect fifo input to DCR
	fifo_in <= i_dcrDBus;
	-- fifo full and empty signals
	fifo_empty <= '1' when CONV_INTEGER(fifo_count) = 0 else '0';
	fifo_full  <= '1' when CONV_INTEGER(fifo_count) = FIFO_DEPTH - 1 else '0';
	-- fifo control signals
	fifo_wronly_set <= '0' when i_dcrDBus = X"AFFEBEEF" else '1';
	fifo_reset  <= '1' when i_dcrDBus = X"AFFEDEAD" else '0';
	
	-- bypass mux as in UG018 page 105 (data output for read requests)
	bypass_mux : process (readFifo, readState, i_dcrDBus, fifo_count, fifo_out,
			fifo_underrun, fifo_overflow, fifo_wronly)
	begin
		o_dcrDBus <= i_dcrDBus;
		if    readFifo  = '1' then o_dcrDBus <= fifo_out;
		elsif readState = '1' then
			o_dcrDBus(C_FIFO_AWIDTH-1 downto 0) <= fifo_count;
			o_dcrDBus(C_DCR_DWIDTH-1) <= fifo_underrun;
			o_dcrDBus(C_DCR_DWIDTH-2) <= fifo_overflow;
			o_dcrDBus(C_DCR_DWIDTH-7) <= fifo_wronly;
		end if;
	end process;
	
	-- process registers that indicate the type of request
	syn_req : process (clk, reset, readFifo, readState, writeFifo)
	begin
		if reset = '1' then
			readStateReg  <= '0';
			readFifoReg   <= '0';
			writeFifoReg  <= '0';
			writeStateReg <= '0';
		elsif rising_edge(clk) then
			readStateReg  <= '0';
			readFifoReg   <= '0';
			writeFifoReg  <= '0';
			writeStateReg <= '0';
			if readFifo   = '1' then readFifoReg   <= '1'; end if;
			if readState  = '1' then readStateReg  <= '1'; end if;
			if writeFifo  = '1' then writeFifoReg  <= '1'; end if;
			if writeState = '1' then writeStateReg <= '1'; end if;
		end if;
	end process;
	
	-- FIFO implementation: this inferres a two port block ram and some additional
	-- control logic and registers
	fifo : process (clk, reset, fifo_we, fifo_next, fifo_full, fifo_empty, fifo_reset,
			fifo_ctrl, fifo_wronly, fifo_wronly_set) 
	begin
		if reset = '1' then
			fifo_inaddr <= (others => '0');
			fifo_outaddr <= (others => '0');
			fifo_count <= (others => '0');
			fifo_overflow <= '0';
			fifo_underrun <= '0';
			fifo_wronly <= '1';
		elsif rising_edge(clk) then
			fifo_out <= fifo_mem(CONV_INTEGER(fifo_outaddr));
			if fifo_ctrl = '1' then
				if fifo_reset = '1' then
					fifo_inaddr  <= (others => '0');
					fifo_outaddr <= (others => '0');
					fifo_count   <= (others => '0');
					fifo_overflow <= '0';
					fifo_underrun <= '0';
					fifo_wronly <= '1';
				end if;
				fifo_wronly <= fifo_wronly_set;
			elsif fifo_we = '1' then
				if fifo_full = '1' then
					fifo_overflow <= '1';
				else
					fifo_mem(CONV_INTEGER(fifo_inaddr)) <= fifo_in;
					fifo_inaddr <= fifo_inaddr + 1;
					fifo_count <= fifo_count + 1;
				end if;
			elsif fifo_next = '1' and fifo_wronly = '0' then
				if fifo_empty = '1' then
					fifo_underrun <= '1';
				else
					fifo_outaddr <= fifo_outaddr + 1;
					fifo_count <= fifo_count - 1;
				end if;
			end if;
		end if;
	end process;
	
end Behavioral;

