--!
--! \file bufg.vhd
--!
--! Simply inserts a BUFG into a clock path, e.g. behind a DCM.
--! This allows easier placement via LOC constraints, since
--! we know the instance name of the BUFG.
--!
--! \author     Enno Luebbers   <enno.luebbers@upb.de>
--! \date       03.02.2009
--
-----------------------------------------------------------------------------
-- %%%RECONOS_COPYRIGHT_BEGIN%%%
-- %%%RECONOS_COPYRIGHT_END%%%
-----------------------------------------------------------------------------
--
-- Major Changes:
--
-- 03.02.2009   Enno Luebbers   File created.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity bufg_logic is

	port (
		I : in std_logic;
		O : out std_logic
	);

end bufg_logic;


architecture structural of bufg_logic is

    component BUFG is
    port (
      I : in std_logic;
      O : out std_logic
    );
    end component;

begin

    bufg_inst : BUFG port map ( I => I, O => O );

end structural;


