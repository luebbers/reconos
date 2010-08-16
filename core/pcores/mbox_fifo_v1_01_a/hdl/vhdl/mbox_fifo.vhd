--
-- \file mbox_fifo.vhd
--
-- Mailbox FIFO to establish point-to-point connections between HW threads
--
-- adapted for ReconOS by Enno Luebbers <luebbers@reconos.de>
--
-- \author     Jason Agron <jagron@ittc.ku.edu>
-- \date       21.11.2007
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library proc_common_v2_00_a;
--use proc_common_v2_00_a.proc_common_pkg.all;
--use proc_common_v2_00_a.ipif_pkg.all;
--library opb_ipif_v3_01_c;
--use opb_ipif_v3_01_c.all;

library mbox_fifo_v1_01_a;
use mbox_fifo_v1_01_a.all;

entity mbox_fifo is
  generic (
	ADDRESS_WIDTH	: integer := 9;
	DATA_WIDTH	: integer := 32
	);
  port (
	readClk		: in std_logic;
	readRst		: in std_logic;
	writeClk		: in std_logic;
	writeRst		: in std_logic;
	write		: in std_logic;
	read		: in std_logic;
	dataIn		: in std_logic_vector(0 to DATA_WIDTH-1);
	dataOut		: out std_logic_vector(0 to DATA_WIDTH-1);
	clearToWrite	: out std_logic;
	clearToRead	: out std_logic	
	);

  attribute SIGIS : string;
  attribute SIGIS of readClk       : signal is "Clk";
  attribute SIGIS of writeClk       : signal is "Clk";
  attribute SIGIS of readRst       : signal is "Rst";
  attribute SIGIS of writeRst       : signal is "Rst";
end entity mbox_fifo;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of mbox_fifo is

	-- Component Declaration for the "guts" of the fifo core
component fifo_async

	port (
        din: IN std_logic_VECTOR(31 downto 0);
        rd_clk: IN std_logic;
        rd_en: IN std_logic;
        rst: IN std_logic;
        wr_clk: IN std_logic;
        wr_en: IN std_logic;
        dout: OUT std_logic_VECTOR(31 downto 0);
        empty: OUT std_logic;
        full: OUT std_logic;
        valid: OUT std_logic
	);

end component;

	signal empty : std_logic;
	signal full : std_logic;
	signal valid : std_logic;
	signal reset : std_logic;

begin


  -- instantiate FIFOs
  fifo_inst : fifo_async
                port map (
                        rd_clk => readClk,
                        wr_clk => writeClk,
                        din => dataIn,
                        rd_en => read,
                        rst => reset,
                        wr_en => write,
                        dout => dataOut,
                        empty => empty,
                        full => full,
			               valid => valid);

  reset <= readRst or writeRst;
	clearToRead <= (not empty) or valid;
	clearToWrite <= not full;


end IMP;
