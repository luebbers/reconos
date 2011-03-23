library IEEE;
use IEEE.std_logic_1164.all;
library synplify;
use synplify.attributes.all;
entity PULLUP is
 port (
   O : out std_logic
 );
 attribute syn_not_a_driver : boolean;
 attribute syn_not_a_driver of O : signal is true;
end entity PULLUP;

architecture bb of PULLUP is
attribute syn_black_box of bb : architecture is true;
attribute syn_noprune of bb : architecture is true;
begin
end architecture bb;

library ieee;
use ieee.std_logic_1164.all;
library synplify;
use synplify.attributes.all;
entity PULLDOWN is
 port (
   O : out std_logic
 );
 attribute syn_not_a_driver : boolean;
 attribute syn_not_a_driver of O : signal is true;
end entity PULLDOWN;

architecture bb of PULLDOWN is
attribute syn_black_box of bb : architecture is true;
attribute syn_noprune of bb : architecture is true;
begin
end architecture bb;

library ieee;
use ieee.std_logic_1164.all;
library synplify;
use synplify.attributes.all;
entity LUT1 is
 generic (INIT : bit_vector(1 downto 0));
 port (
   O : out std_logic;
   I0 : in std_logic
 );
end entity LUT1;

architecture lut of LUT1 is
attribute xc_map of lut : architecture is "lut";
begin
O <= To_StdULogic(INIT(1)) when I0 = '1' else To_StdULogic(INIT(0));
end architecture lut;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
library synplify;
use synplify.attributes.all;
entity LUT2 is
 generic (INIT : bit_vector(3 downto 0));
 port (
   O : out std_logic;
  I0 : in std_logic;
  I1 : in std_logic
 );
end entity LUT2;

architecture lut of LUT2 is
attribute xc_map of lut : architecture is "lut";
signal b : std_logic_vector(1 downto 0);
signal tmp : integer range 0 to 7;
begin
   b <= (I1, I0);
   tmp <= conv_integer(b);
   O <= To_StdULogic(INIT(tmp));
end architecture lut;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
library synplify;
use synplify.attributes.all;
entity LUT3 is
 generic (INIT : bit_vector(7 downto 0));
 port (
   O : out std_logic;
  I0 : in std_logic;
  I1 : in std_logic;
  I2 : in std_logic
 );
end entity LUT3;

architecture lut of LUT3 is
attribute xc_map of lut : architecture is "lut";
signal b : std_logic_vector(2 downto 0);
signal tmp : integer range 0 to 7;
begin
   b <= (I2, I1, I0);
   tmp <= conv_integer(b);
   O <= To_StdULogic(INIT(tmp));
end architecture lut;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
library synplify;
use synplify.attributes.all;
entity LUT4 is
 generic (INIT : bit_vector(15 downto 0));
 port (
   O : out std_logic;
  I0 : in std_logic;
  I1 : in std_logic;
  I2 : in std_logic;
  I3 : in std_logic
  );
end entity LUT4;

architecture lut of LUT4 is
attribute xc_map of lut : architecture is "lut";
signal b : std_logic_vector(3 downto 0);
signal tmp : integer range 0 to 15;
begin
  b <= (I3, I2, I1, I0);
  tmp <= conv_integer(b);
  O <= To_StdUlogic(INIT(tmp));
end architecture lut;

library ieee;
use ieee.std_logic_1164.all;
library synplify;
use synplify.attributes.all;
package components is
   attribute syn_black_box of components : package is true;
   attribute syn_noprune : boolean;
component BSCAN_VIRTEX2
 port (
   TDO1 : in std_logic;
   TDO2 : in std_logic;
   CAPTURE : out std_logic;
   DRCK1 : out std_logic;
   DRCK2 : out std_logic;
   RESET : out std_logic;
   SEL1 : out std_logic;
   SEL2 : out std_logic;
   SHIFT : out std_logic;
   TDI : out std_logic;
   UPDATE : out std_logic
 );
end component;
attribute syn_black_box of BSCAN_VIRTEX2 : component is true;
component BUF
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of BUF : component is true;
component BUFCF
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
component BUFE
 port (
   O : out std_logic;
   E : in std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of BUFE : component is true;
attribute black_box_tri_pins of BUFE : component is "O";
component BUFG
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of BUFG : component is true;
component BUFGDLL
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of BUFGDLL : component is true;
component BUFGMUX0
 port (
   O  : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   S  : in std_logic
 );
end component;
attribute syn_black_box of BUFGMUX0 : component is true;
component BUFGMUX1
 port (
   O  : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   S  : in std_logic
 );
end component;
attribute syn_black_box of BUFGMUX1 : component is true;
component BUFGP
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of BUFGP : component is true;
component BUFT
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of BUFT : component is true;
attribute black_box_tri_pins of BUFT : component is "O";
component CAPTURE_VIRTEX2
 port (
   CAP : in std_logic;
   CLK : in std_logic
 );
end component;
attribute syn_black_box of CAPTURE_VIRTEX2 : component is true;
attribute syn_noprune of CAPTURE_VIRTEX2 : component is true;
component CLKDLL
 port (
   CLK0 : out std_logic;
   CLK90 : out std_logic;
   CLK180 : out std_logic;
   CLK270 : out std_logic;
   CLK2X : out std_logic;
   CLKDV : out std_logic;
   LOCKED : out std_logic;
   CLKIN : in std_logic;
   CLKFB : in std_logic;
   RST : in std_logic
 );
end component;
attribute syn_black_box of CLKDLL : component is true;
component CLKDLLE
 port (
   CLK0 : out std_logic;
   CLK90 : out std_logic;
   CLK180 : out std_logic;
   CLK270 : out std_logic;
   CLK2X : out std_logic;
   CLK2X180 : out std_logic;
   CLKDV : out std_logic;
   LOCKED : out std_logic;
   CLKIN : in std_logic;
   CLKFB : in std_logic;
   RST : in std_logic
 );
end component;
attribute syn_black_box of CLKDLLE : component is true;
component CLKDLLHF
 port (
   CLK0 : out std_logic;
   CLK180 : out std_logic;
   CLKDV : out std_logic;
   LOCKED : out std_logic;
   CLKIN : in std_logic;
   CLKFB : in std_logic;
   RST : in std_logic
 );
end component;
attribute syn_black_box of CLKDLLHF : component is true;
component DCM
    generic (DFS_FREQUENCY_MODE : string := "LOW";
             DLL_FREQUENCY_MODE : string := "LOW";
             DUTY_CYCLE_CORRECTION : boolean := TRUE;
             CLKIN_DIVIDE_BY_2 : boolean := FALSE;
             CLK_FEEDBACK : string := "1X";
             CLKOUT_PHASE_SHIFT : string := "NONE";
             FACTORY_JF : bit_vector := X"C080";
             STARTUP_WAIT : boolean := FALSE;
	     DSS_MODE	  : string := "NONE";
             PHASE_SHIFT  : integer := 0 ;
             CLKFX_MULTIPLY : integer  := 4 ;
	     CLKFX_DIVIDE : integer  := 1;
             CLKDV_DIVIDE : real := 2.0;
             CLKIN_PERIOD : real := 0.0;    
             DESKEW_ADJUST : string := "SYSTEM_SYNCHRONOUS"
             ); 
 port ( CLKIN : in std_logic;
	    CLKFB : in std_logic;
	    DSSEN : in std_logic;
	    PSINCDEC : in std_logic;
	    PSEN : in std_logic;
	    PSCLK : in std_logic;
	    RST : in std_logic;
	    CLK0 : out std_logic;
        CLK90 : out std_logic;
        CLK180 : out std_logic;
	    CLK270 : out std_logic;
        CLK2X : out std_logic;
        CLK2X180 : out std_logic;
	    CLKDV : out std_logic;
	    CLKFX : out std_logic;
	    CLKFX180 : out std_logic;
	    LOCKED : out std_logic;
	    PSDONE : out std_logic;
	    STATUS : out std_logic_vector(7 downto 0)
 );
end component;
attribute syn_black_box of DCM : component is true;
component FD
 port (
   Q : out std_logic;
   C : in std_logic;
   D : in std_logic
 );
end component;
attribute syn_black_box of FD : component is true;
component FDC
 port (
   Q : out std_logic;
   C : in std_logic;
   CLR : in std_logic;
   D : in std_logic
 );
end component;
attribute syn_black_box of FDC : component is true;
component FDCE
 port (
   Q : out std_logic;
   C : in std_logic;
   CE : in std_logic;
   CLR : in std_logic;
   D : in std_logic
 );
end component;
attribute syn_black_box of FDCE : component is true;
component FDCE_1
 port (
   Q : out std_logic;
   C : in std_logic;
   CE : in std_logic;
   CLR : in std_logic;
   D : in std_logic
 );
end component;
attribute syn_black_box of FDCE_1 : component is true;
component FDCP
 port (
   Q : out std_logic;
   C : in std_logic;
   CLR : in std_logic;
   D : in std_logic;
   PRE : in std_logic
 );
end component;
attribute syn_black_box of FDCP : component is true;
component FDCPE
 port (
   Q : out std_logic;
   C : in std_logic;
   CE : in std_logic;
   CLR : in std_logic;
   D : in std_logic;
   PRE : in std_logic
 );
end component;
attribute syn_black_box of FDCPE : component is true;
component FDCPE_1
 port (
   Q : out std_logic;
   C : in std_logic;
   CE : in std_logic;
   CLR : in std_logic;
   D : in std_logic;
   PRE : in std_logic
 );
end component;
attribute syn_black_box of FDCPE_1 : component is true;
component FDCP_1
 port (
   Q : out std_logic;
   C : in std_logic;
   CLR : in std_logic;
   D : in std_logic;
   PRE : in std_logic
 );
end component;
attribute syn_black_box of FDCP_1 : component is true;
component FDC_1
 port (
   Q : out std_logic;
   C : in std_logic;
   CLR : in std_logic;
   D : in std_logic
 );
end component;
attribute syn_black_box of FDC_1 : component is true;
component FDDRCPE
 port (
   Q : out std_logic;
   C0 : in std_logic;
   C1 : in std_logic;
   CE : in std_logic;
   CLR : in std_logic;
   D0 : in std_logic;
   D1 : in std_logic;
   PRE : in std_logic
 );
end component;
attribute syn_black_box of FDDRCPE : component is true;
component FDDRRSE
 port (
   Q : out std_logic;
   C0 : in std_logic;
   C1 : in std_logic;
   CE : in std_logic;
   D0 : in std_logic;
   D1 : in std_logic;
   R : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of FDDRRSE : component is true;
component FDE
 port (
   Q : out std_logic;
   C : in std_logic;
   CE : in std_logic;
   D : in std_logic
 );
end component;
attribute syn_black_box of FDE : component is true;
component FDE_1
 port (
   Q : out std_logic;
   C : in std_logic;
   CE : in std_logic;
   D : in std_logic
 );
end component;
attribute syn_black_box of FDE_1 : component is true;
component FDP
 port (
   Q : out std_logic;
   C : in std_logic;
   D : in std_logic;
   PRE : in std_logic
 );
end component;
attribute syn_black_box of FDP : component is true;
component FDPE
 port (
   Q : out std_logic;
   C : in std_logic;
   CE : in std_logic;
   D : in std_logic;
   PRE : in std_logic
 );
end component;
attribute syn_black_box of FDPE : component is true;
component FDPE_1
 port (
   Q : out std_logic;
   C : in std_logic;
   CE : in std_logic;
   D : in std_logic;
   PRE : in std_logic
 );
end component;
attribute syn_black_box of FDPE_1 : component is true;
component FDP_1
 port (
   Q : out std_logic;
   C : in std_logic;
   D : in std_logic;
   PRE : in std_logic
 );
end component;
attribute syn_black_box of FDP_1 : component is true;
component FDR
 port (
   Q : out std_logic;
   C : in std_logic;
   D : in std_logic;
   R : in std_logic
 );
end component;
attribute syn_black_box of FDR : component is true;
component FDRE
 port (
   Q : out std_logic;
   C : in std_logic;
   CE : in std_logic;
   D : in std_logic;
   R : in std_logic
 );
end component;
attribute syn_black_box of FDRE : component is true;
component FDRE_1
 port (
   Q : out std_logic;
   C : in std_logic;
   CE : in std_logic;
   D : in std_logic;
   R : in std_logic
 );
end component;
attribute syn_black_box of FDRE_1 : component is true;
component FDRS
 port (
   Q : out std_logic;
   C : in std_logic;
   D : in std_logic;
   R : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of FDRS : component is true;
component FDRSE
 port (
   Q : out std_logic;
   C : in std_logic;
   CE : in std_logic;
   D : in std_logic;
   R : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of FDRSE : component is true;
component FDRSE_1
 port (
   Q : out std_logic;
   C : in std_logic;
   CE : in std_logic;
   D : in std_logic;
   R : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of FDRSE_1 : component is true;
component FDRS_1
 port (
   Q : out std_logic;
   C : in std_logic;
   D : in std_logic;
   R : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of FDRS_1 : component is true;
component FDR_1
 port (
   Q : out std_logic;
   C : in std_logic;
   D : in std_logic;
   R : in std_logic
 );
end component;
attribute syn_black_box of FDR_1 : component is true;
component FDS
 port (
   Q : out std_logic;
   C : in std_logic;
   D : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of FDS : component is true;
component FDSE
 port (
   Q : out std_logic;
   C : in std_logic;
   CE : in std_logic;
   D : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of FDSE : component is true;
component FDSE_1
 port (
   Q : out std_logic;
   C : in std_logic;
   CE : in std_logic;
   D : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of FDSE_1 : component is true;
component FDS_1
 port (
   Q : out std_logic;
   C : in std_logic;
   D : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of FDS_1 : component is true;
component FD_1
 port (
   Q : out std_logic;
   C : in std_logic;
   D : in std_logic
 );
end component;
attribute syn_black_box of FD_1 : component is true;
component GND
 port (
   G : out std_logic
 );
end component;
attribute syn_black_box of GND : component is true;
attribute syn_noprune of GND : component is true;
component IBUF
 generic (
   IOSTANDARD : string := "default"
 );
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF : component is true;
component IBUFDS
 generic (
   IOSTANDARD : string := "default"
 );
 port (
   O : out std_logic;
   I : in std_logic;
   IB : in std_logic
 );
end component;
attribute syn_black_box of IBUFDS : component is true;
component IBUFDS_BLVDS_25
 port (
   O : out std_logic;
   I : in std_logic;
   IB : in std_logic
 );
end component;
attribute syn_black_box of IBUFDS_BLVDS_25 : component is true;
component IBUFDS_LDT_25
 port (
   O : out std_logic;
   I : in std_logic;
   IB : in std_logic
 );
end component;
attribute syn_black_box of IBUFDS_LDT_25 : component is true;
component IBUFDS_LVDSEXT_25
 port (
   O : out std_logic;
   I : in std_logic;
   IB : in std_logic
 );
end component;
attribute syn_black_box of IBUFDS_LVDSEXT_25 : component is true;
component IBUFDS_LVDSEXT_33
 port (
   O : out std_logic;
   I : in std_logic;
   IB : in std_logic
 );
end component;
attribute syn_black_box of IBUFDS_LVDSEXT_33 : component is true;
component IBUFDS_LVDS_25
 port (
   O : out std_logic;
   I : in std_logic;
   IB : in std_logic
 );
end component;
attribute syn_black_box of IBUFDS_LVDS_25 : component is true;
component IBUFDS_LVDS_33
 port (
   O : out std_logic;
   I : in std_logic;
   IB : in std_logic
 );
end component;
attribute syn_black_box of IBUFDS_LVDS_33 : component is true;
component IBUFDS_LVPECL_33
 port (
   O : out std_logic;
   I : in std_logic;
   IB : in std_logic
 );
end component;
attribute syn_black_box of IBUFDS_LVPECL_33 : component is true;
component IBUFDS_ULVDS_25
 port (
   O : out std_logic;
   I : in std_logic;
   IB : in std_logic
 );
end component;
attribute syn_black_box of IBUFDS_ULVDS_25 : component is true;
component IBUFG
 generic (
   IOSTANDARD : string := "default"
 );
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG : component is true;
component IBUFGDS
 generic (
   IOSTANDARD : string := "default"
 );
 port (
   O : out std_logic;
   I : in std_logic;
   IB : in std_logic
 );
end component;
attribute syn_black_box of IBUFGDS : component is true;
component IBUFGDS_BLVDS_25
 port (
   O : out std_logic;
   I : in std_logic;
   IB : in std_logic
 );
end component;
attribute syn_black_box of IBUFGDS_BLVDS_25 : component is true;
component IBUFGDS_LDT_25
 port (
   O : out std_logic;
   I : in std_logic;
   IB : in std_logic
 );
end component;
attribute syn_black_box of IBUFGDS_LDT_25 : component is true;
component IBUFGDS_LVDSEXT_25
 port (
   O : out std_logic;
   I : in std_logic;
   IB : in std_logic
 );
end component;
attribute syn_black_box of IBUFGDS_LVDSEXT_25 : component is true;
component IBUFGDS_LVDSEXT_33
 port (
   O : out std_logic;
   I : in std_logic;
   IB : in std_logic
 );
end component;
attribute syn_black_box of IBUFGDS_LVDSEXT_33 : component is true;
component IBUFGDS_LVDS_25
 port (
   O : out std_logic;
   I : in std_logic;
   IB : in std_logic
 );
end component;
attribute syn_black_box of IBUFGDS_LVDS_25 : component is true;
component IBUFGDS_LVDS_33
 port (
   O : out std_logic;
   I : in std_logic;
   IB : in std_logic
 );
end component;
attribute syn_black_box of IBUFGDS_LVDS_33 : component is true;
component IBUFGDS_LVPECL_33
 port (
   O : out std_logic;
   I : in std_logic;
   IB : in std_logic
 );
end component;
attribute syn_black_box of IBUFGDS_LVPECL_33 : component is true;
component IBUFGDS_ULVDS_25
 port (
   O : out std_logic;
   I : in std_logic;
   IB : in std_logic
 );
end component;
attribute syn_black_box of IBUFGDS_ULVDS_25 : component is true;
component IBUFG_AGP
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_AGP : component is true;
component IBUFG_GTL
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_GTL : component is true;
component IBUFG_GTL_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_GTL_DCI : component is true;
component IBUFG_GTLP
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_GTLP : component is true;
component IBUFG_GTLP_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_GTLP_DCI : component is true;
component IBUFG_HSTL_I
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_HSTL_I : component is true;
component IBUFG_HSTL_I_18
  port (
    O : out std_logic;
    I : in std_logic
  );
end component;
attribute syn_black_box of IBUFG_HSTL_I_18 : component is true;
component IBUFG_HSTL_I_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_HSTL_I_DCI : component is true;
component IBUFG_HSTL_I_DCI_18
  port (
    O : out std_logic;
    I : in std_logic
  );
end component;
attribute syn_black_box of IBUFG_HSTL_I_DCI_18 : component is true;
component IBUFG_HSTL_II
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_HSTL_II : component is true;
component IBUFG_HSTL_II_18
  port (
    O : out std_logic;
    I : in std_logic
  );
end component;
attribute syn_black_box of IBUFG_HSTL_II_18 : component is true;
component IBUFG_HSTL_II_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_HSTL_II_DCI : component is true;
component IBUFG_HSTL_II_DCI_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_HSTL_II_DCI_18 : component is true;
component IBUFG_HSTL_III
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_HSTL_III : component is true;
component IBUFG_HSTL_III_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_HSTL_III_18 : component is true;
component IBUFG_HSTL_III_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_HSTL_III_DCI : component is true;
component IBUFG_HSTL_III_DCI_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_HSTL_III_DCI_18 : component is true;
component IBUFG_HSTL_IV
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_HSTL_IV : component is true;
component IBUFG_HSTL_IV_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_HSTL_IV_18 : component is true;
component IBUFG_HSTL_IV_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_HSTL_IV_DCI : component is true;
component IBUFG_HSTL_IV_DCI_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_HSTL_IV_DCI_18 : component is true;
component IBUFG_LVDCI_15
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_LVDCI_15 : component is true;
component IBUFG_LVDCI_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_LVDCI_18 : component is true;
component IBUFG_LVDCI_25
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_LVDCI_25 : component is true;
component IBUFG_LVDCI_33
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_LVDCI_33 : component is true;
component IBUFG_LVDCI_DV2_15
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_LVDCI_DV2_15 : component is true;
component IBUFG_LVDCI_DV2_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_LVDCI_DV2_18 : component is true;
component IBUFG_LVDCI_DV2_25
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_LVDCI_DV2_25 : component is true;
component IBUFG_LVCMOS15
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_LVCMOS15 : component is true;
component IBUFG_LVCMOS18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_LVCMOS18 : component is true;
component IBUFG_LVCMOS2
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_LVCMOS2 : component is true;
component IBUFG_LVCMOS25
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_LVCMOS25 : component is true;
component IBUFG_PCI33_3
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_PCI33_3 : component is true;
component IBUFG_PCI66_3
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_PCI66_3 : component is true;
component IBUFG_PCIX
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_PCIX : component is true;
component IBUFG_SSTL2_I
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_SSTL2_I : component is true;
component IBUFG_SSTL2_I_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_SSTL2_I_DCI : component is true;
component IBUFG_SSTL2_II
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_SSTL2_II : component is true;
component IBUFG_SSTL2_II_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUFG_SSTL2_II_DCI : component is true;
component IBUF_AGP
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_AGP : component is true;
component IBUF_GTL
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_GTL : component is true;
component IBUF_GTL_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_GTL_DCI : component is true;
component IBUF_GTLP
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_GTLP : component is true;
component IBUF_GTLP_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_GTLP_DCI : component is true;
component IBUF_HSTL_I
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_HSTL_I : component is true;
component IBUF_HSTL_I_18
  port (
    O : out std_logic;
    I : in std_logic
  );
end component;
attribute syn_black_box of IBUF_HSTL_I_18 : component is true;
component IBUF_HSTL_I_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_HSTL_I_DCI : component is true;
component IBUF_HSTL_I_DCI_18
  port (
    O : out std_logic;
    I : in std_logic
  );
end component;
attribute syn_black_box of IBUF_HSTL_I_DCI_18 : component is true;
component IBUF_HSTL_II
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_HSTL_II : component is true;
component IBUF_HSTL_II_18
  port (
    O : out std_logic;
    I : in std_logic
  );
end component;
attribute syn_black_box of IBUF_HSTL_II_18 : component is true;
component IBUF_HSTL_II_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_HSTL_II_DCI : component is true;
component IBUF_HSTL_II_DCI_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_HSTL_II_DCI_18 : component is true;
component IBUF_HSTL_III
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_HSTL_III : component is true;
component IBUF_HSTL_III_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_HSTL_III_18 : component is true;
component IBUF_HSTL_III_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_HSTL_III_DCI : component is true;
component IBUF_HSTL_III_DCI_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_HSTL_III_DCI_18 : component is true;
component IBUF_HSTL_IV
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_HSTL_IV : component is true;
component IBUF_HSTL_IV_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_HSTL_IV_18 : component is true;
component IBUF_HSTL_IV_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_HSTL_IV_DCI : component is true;
component IBUF_HSTL_IV_DCI_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_HSTL_IV_DCI_18 : component is true;
component IBUF_LVCMOS15
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_LVCMOS15 : component is true;
component IBUF_LVCMOS18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_LVCMOS18 : component is true;
component IBUF_LVCMOS2
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_LVCMOS2 : component is true;
component IBUF_LVCMOS25
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_LVCMOS25 : component is true;
component IBUF_LVDCI_15
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_LVDCI_15 : component is true;
component IBUF_LVDCI_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_LVDCI_18 : component is true;
component IBUF_LVDCI_25
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_LVDCI_25 : component is true;
component IBUF_LVDCI_33
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_LVDCI_33 : component is true;
component IBUF_LVDCI_DV2_15
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_LVDCI_DV2_15 : component is true;
component IBUF_LVDCI_DV2_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_LVDCI_DV2_18 : component is true;
component IBUF_LVDCI_DV2_25
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_LVDCI_DV2_25 : component is true;
component IBUF_LVDS
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_LVDS : component is true;
component IBUF_LVPECL
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_LVPECL : component is true;
component IBUF_PCI33_3
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_PCI33_3 : component is true;
component IBUF_PCI66_3
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_PCI66_3 : component is true;
component IBUF_PCIX
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_PCIX : component is true;
component IBUF_SSTL2_I
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_SSTL2_I : component is true;
component IBUF_SSTL2_I_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_SSTL2_I_DCI : component is true;
component IBUF_SSTL2_II
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_SSTL2_II : component is true;
component IBUF_SSTL2_II_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of IBUF_SSTL2_II_DCI : component is true;
component INV
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of INV : component is true;
component PIPEBUF
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of PIPEBUF : component is true;
component IOBUF
 generic (
   IOSTANDARD : string := "default";
   SLEW : string := "SLOW";
   DRIVE : integer := 12
 );
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF : component is true;
component IOBUFDS
 generic (
   IOSTANDARD : string := "default";
   SLEW : string := "SLOW";
   DRIVE : integer := 12
 );
 port (
   O : out std_logic;
   IO : inout std_logic;
   IOB : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUFDS : component is true;
component IOBUFDS_BLVDS_25
 port (
   O : out std_logic;
   IO : inout std_logic;
   IOB : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUFDS_BLVDS_25 : component is true;
component IOBUFDS_LVPECL_33
 port (
   O : out std_logic;
   IO : inout std_logic;
   IOB : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUFDS_LVPECL_33 : component is true;
component IOBUF_F_12
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_F_12 : component is true;
component IOBUF_F_16
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_F_16 : component is true;
component IOBUF_F_2
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_F_2 : component is true;
component IOBUF_F_24
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_F_24 : component is true;
component IOBUF_F_4
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_F_4 : component is true;
component IOBUF_F_6
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_F_6 : component is true;
component IOBUF_F_8
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_F_8 : component is true;
component IOBUF_GTL
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_GTL : component is true;
component IOBUF_GTL_DCI
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_GTL_DCI : component is true;
component IOBUF_GTLP
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_GTLP : component is true;
component IOBUF_GTLP_DCI
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_GTLP_DCI : component is true;
component IOBUF_HSTL_I
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_HSTL_I : component is true;
component IOBUF_HSTL_I_18
  port (
  O : out std_logic;
  IO : inout std_logic;
  I : in std_logic;
  T : in std_logic
  );
end component;
attribute syn_black_box of IOBUF_HSTL_I_18 : component is true;
component IOBUF_HSTL_I_DCI
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_HSTL_I_DCI : component is true;
component IOBUF_HSTL_II
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_HSTL_II : component is true;
component IOBUF_HSTL_II_18
  port (
    O : out std_logic;
    IO : inout std_logic;
    I : in std_logic;
    T : in std_logic
  );
end component;
attribute syn_black_box of IOBUF_HSTL_II_18 : component is true;
component IOBUF_HSTL_II_DCI
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_HSTL_II_DCI : component is true;
component IOBUF_HSTL_II_DCI_18
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_HSTL_II_DCI_18 : component is true;
component IOBUF_HSTL_III
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_HSTL_III : component is true;
component IOBUF_HSTL_III_18
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_HSTL_III_18 : component is true;
component IOBUF_HSTL_III_DCI
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_HSTL_III_DCI : component is true;
component IOBUF_HSTL_III_DCI_18
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_HSTL_III_DCI_18 : component is true;
component IOBUF_HSTL_IV
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_HSTL_IV : component is true;
component IOBUF_HSTL_IV_18
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_HSTL_IV_18 : component is true;
component IOBUF_HSTL_IV_DCI
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_HSTL_IV_DCI : component is true;
component IOBUF_HSTL_IV_DCI_18
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_HSTL_IV_DCI_18 : component is true;
component IOBUF_LVCMOS15
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS15 : component is true;
component IOBUF_LVCMOS15_F_12
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS15_F_12 : component is true;
component IOBUF_LVCMOS15_F_16
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS15_F_16 : component is true;
component IOBUF_LVCMOS15_F_2
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS15_F_2 : component is true;
component IOBUF_LVCMOS15_F_4
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS15_F_4 : component is true;
component IOBUF_LVCMOS15_F_6
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS15_F_6 : component is true;
component IOBUF_LVCMOS15_F_8
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS15_F_8 : component is true;
component IOBUF_LVCMOS15_S_12
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS15_S_12 : component is true;
component IOBUF_LVCMOS15_S_16
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS15_S_16 : component is true;
component IOBUF_LVCMOS15_S_2
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS15_S_2 : component is true;
component IOBUF_LVCMOS15_S_4
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS15_S_4 : component is true;
component IOBUF_LVCMOS15_S_6
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS15_S_6 : component is true;
component IOBUF_LVCMOS15_S_8
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS15_S_8 : component is true;
component IOBUF_LVCMOS18
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS18 : component is true;
component IOBUF_LVCMOS18_F_12
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS18_F_12 : component is true;
component IOBUF_LVCMOS18_F_16
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS18_F_16 : component is true;
component IOBUF_LVCMOS18_F_2
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS18_F_2 : component is true;
component IOBUF_LVCMOS18_F_4
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS18_F_4 : component is true;
component IOBUF_LVCMOS18_F_6
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS18_F_6 : component is true;
component IOBUF_LVCMOS18_F_8
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS18_F_8 : component is true;
component IOBUF_LVCMOS18_S_12
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS18_S_12 : component is true;
component IOBUF_LVCMOS18_S_16
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS18_S_16 : component is true;
component IOBUF_LVCMOS18_S_2
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS18_S_2 : component is true;
component IOBUF_LVCMOS18_S_4
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS18_S_4 : component is true;
component IOBUF_LVCMOS18_S_6
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS18_S_6 : component is true;
component IOBUF_LVCMOS18_S_8
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS18_S_8 : component is true;
component IOBUF_LVCMOS2
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS2 : component is true;
component IOBUF_LVCMOS25
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS25 : component is true;
component IOBUF_LVCMOS25_F_12
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS25_F_12 : component is true;
component IOBUF_LVCMOS25_F_16
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS25_F_16 : component is true;
component IOBUF_LVCMOS25_F_2
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS25_F_2 : component is true;
component IOBUF_LVCMOS25_F_24
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS25_F_24 : component is true;
component IOBUF_LVCMOS25_F_4
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS25_F_4 : component is true;
component IOBUF_LVCMOS25_F_6
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS25_F_6 : component is true;
component IOBUF_LVCMOS25_F_8
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS25_F_8 : component is true;
component IOBUF_LVCMOS25_S_12
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS25_S_12 : component is true;
component IOBUF_LVCMOS25_S_16
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS25_S_16 : component is true;
component IOBUF_LVCMOS25_S_2
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS25_S_2 : component is true;
component IOBUF_LVCMOS25_S_24
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS25_S_24 : component is true;
component IOBUF_LVCMOS25_S_4
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS25_S_4 : component is true;
component IOBUF_LVCMOS25_S_6
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS25_S_6 : component is true;
component IOBUF_LVCMOS25_S_8
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVCMOS25_S_8 : component is true;
component IOBUF_LVDCI_15
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVDCI_15 : component is true;
component IOBUF_LVDCI_18
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVDCI_18 : component is true;
component IOBUF_LVDCI_25
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVDCI_25 : component is true;
component IOBUF_LVDCI_33
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVDCI_33 : component is true;
component IOBUF_LVDCI_DV2_15
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVDCI_DV2_15 : component is true;
component IOBUF_LVDCI_DV2_18
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVDCI_DV2_18 : component is true;
component IOBUF_LVDCI_DV2_25
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVDCI_DV2_25 : component is true;
component IOBUF_LVDS
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVDS : component is true;
component IOBUF_LVPECL
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_LVPECL : component is true;
component IOBUF_PCI33_3
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_PCI33_3 : component is true;
component IOBUF_PCI66_3
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_PCI66_3 : component is true;
component IOBUF_PCIX
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_PCIX : component is true;
component IOBUF_SSTL2_I
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_SSTL2_I : component is true;
component IOBUF_SSTL2_I_DCI
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_SSTL2_I_DCI : component is true;
component IOBUF_SSTL2_II
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_SSTL2_II : component is true;
component IOBUF_SSTL2_II_DCI
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_SSTL2_II_DCI : component is true;
component IOBUF_S_12
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_S_12 : component is true;
component IOBUF_S_16
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_S_16 : component is true;
component IOBUF_S_2
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_S_2 : component is true;
component IOBUF_S_24
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_S_24 : component is true;
component IOBUF_S_4
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_S_4 : component is true;
component IOBUF_S_6
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_S_6 : component is true;
component IOBUF_S_8
 port (
   O : out std_logic;
   IO : inout std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of IOBUF_S_8 : component is true;
component KEEPER
 port (
   O : inout std_logic
 );
end component;
attribute syn_black_box of KEEPER : component is true;
attribute syn_noprune of KEEPER : component is true;
component LD
 port (
   Q : out std_logic;
   D : in std_logic;
   G : in std_logic
 );
end component;
attribute syn_black_box of LD : component is true;
component LDC
 port (
   Q : out std_logic;
   CLR : in std_logic;
   D : in std_logic;
   G : in std_logic
 );
end component;
attribute syn_black_box of LDC : component is true;
component LDCE
 port (
   Q : out std_logic;
   CLR : in std_logic;
   D : in std_logic;
   G : in std_logic;
   GE : in std_logic
 );
end component;
attribute syn_black_box of LDCE : component is true;
component LDCE_1
 port (
   Q : out std_logic;
   CLR : in std_logic;
   D : in std_logic;
   G : in std_logic;
   GE : in std_logic
 );
end component;
attribute syn_black_box of LDCE_1 : component is true;
component LDCP
 port (
   Q : out std_logic;
   CLR : in std_logic;
   D : in std_logic;
   G : in std_logic;
   PRE : in std_logic
 );
end component;
attribute syn_black_box of LDCP : component is true;
component LDCPE
 port (
   Q : out std_logic;
   CLR : in std_logic;
   D : in std_logic;
   G : in std_logic;
   GE : in std_logic;
   PRE : in std_logic
 );
end component;
attribute syn_black_box of LDCPE : component is true;
component LDCPE_1
 port (
   Q : out std_logic;
   CLR : in std_logic;
   D : in std_logic;
   G : in std_logic;
   GE : in std_logic;
   PRE : in std_logic
 );
end component;
attribute syn_black_box of LDCPE_1 : component is true;
component LDCP_1
 port (
   Q : out std_logic;
   CLR : in std_logic;
   D : in std_logic;
   G : in std_logic;
   PRE : in std_logic
 );
end component;
attribute syn_black_box of LDCP_1 : component is true;
component LDC_1
 port (
   Q : out std_logic;
   CLR : in std_logic;
   D : in std_logic;
   G : in std_logic
 );
end component;
attribute syn_black_box of LDC_1 : component is true;
component LDE
 port (
   Q : out std_logic;
   D : in std_logic;
   G : in std_logic;
   GE : in std_logic
 );
end component;
attribute syn_black_box of LDE : component is true;
component LDE_1
 port (
   Q : out std_logic;
   D : in std_logic;
   G : in std_logic;
   GE : in std_logic
 );
end component;
attribute syn_black_box of LDE_1 : component is true;
component LDP
 port (
   Q : out std_logic;
   D : in std_logic;
   G : in std_logic;
   PRE : in std_logic
 );
end component;
attribute syn_black_box of LDP : component is true;
component LDPE
 port (
   Q : out std_logic;
   D : in std_logic;
   G : in std_logic;
   GE : in std_logic;
   PRE : in std_logic
 );
end component;
attribute syn_black_box of LDPE : component is true;
component LDPE_1
 port (
   Q : out std_logic;
   D : in std_logic;
   G : in std_logic;
   GE : in std_logic;
   PRE : in std_logic
 );
end component;
attribute syn_black_box of LDPE_1 : component is true;
component LDP_1
 port (
   Q : out std_logic;
   D : in std_logic;
   G : in std_logic;
   PRE : in std_logic
 );
end component;
attribute syn_black_box of LDP_1 : component is true;
component LD_1
 port (
   Q : out std_logic;
   D : in std_logic;
   G : in std_logic
 );
end component;
attribute syn_black_box of LD_1 : component is true;
component LUT1
 generic(INIT : bit_vector := "00");
 port (
   O : out std_logic;
   I0 : in std_logic
 );
end component;
attribute syn_black_box of LUT1 : component is true;
attribute xc_map of LUT1 : component is "lut";
component LUT1_D
 generic(INIT : bit_vector := "00");
 port (
   LO : out std_logic;
   O : out std_logic;
   I0 : in std_logic
 );
end component;
attribute syn_black_box of LUT1_D : component is true;
attribute xc_map of LUT1_D : component is "lut";
component LUT1_L
 generic(INIT : bit_vector := "00");
 port (
   LO : out std_logic;
   I0 : in std_logic
 );
end component;
attribute syn_black_box of LUT1_L : component is true;
attribute xc_map of LUT1_L : component is "lut";
component LUT2
 generic(INIT : bit_vector := X"0");
 port (
   O : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic
 );
end component;
attribute syn_black_box of LUT2 : component is true;
attribute xc_map of LUT2 : component is "lut";
component LUT2_D
 generic(INIT : bit_vector := X"0");
 port (
   LO : out std_logic;
   O : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic
 );
end component;
attribute syn_black_box of LUT2_D : component is true;
attribute xc_map of LUT2_D : component is "lut";
component LUT2_L
 generic(INIT : bit_vector := X"0");
 port (
   LO : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic
 );
end component;
attribute syn_black_box of LUT2_L : component is true;
attribute xc_map of LUT2_L : component is "lut";
component LUT3
 generic(INIT : bit_vector := X"00");
 port (
   O : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   I2 : in std_logic
 );
end component;
attribute syn_black_box of LUT3 : component is true;
attribute xc_map of LUT3 : component is "lut";
component LUT3_D
 generic(INIT : bit_vector := X"00");
 port (
   LO : out std_logic;
   O : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   I2 : in std_logic
 );
end component;
attribute syn_black_box of LUT3_D : component is true;
attribute xc_map of LUT3_D : component is "lut";
component LUT3_L
 generic(INIT : bit_vector := X"00");
 port (
   LO : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   I2 : in std_logic
 );
end component;
attribute syn_black_box of LUT3_L : component is true;
attribute xc_map of LUT3_L : component is "lut";
component LUT4
 generic(INIT : bit_vector := X"0000");
 port (
   O : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   I2 : in std_logic;
   I3 : in std_logic
 );
end component;
attribute syn_black_box of LUT4 : component is true;
attribute xc_map of LUT4 : component is "lut";
component LUT4_D
 generic(INIT : bit_vector := X"0000");
 port (
   LO : out std_logic;
   O : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   I2 : in std_logic;
   I3 : in std_logic
 );
end component;
attribute syn_black_box of LUT4_D : component is true;
attribute xc_map of LUT4_D : component is "lut";
component LUT4_L
 generic(INIT : bit_vector := X"0000");
 port (
   LO : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   I2 : in std_logic;
   I3 : in std_logic
 );
end component;
attribute syn_black_box of LUT4_L : component is true;
attribute xc_map of LUT4_L : component is "lut";
component MULT18X18
 port (
   P : out std_logic_vector(35 downto 0);
   A : in std_logic_Vector(17 downto 0);
   B : in std_logic_vector(17 downto 0)
 );
end component;
attribute syn_black_box of MULT18X18 : component is true;
component MULT18X18S

    port (A	: in STD_LOGIC_VECTOR (17 downto 0);
          B	: in STD_LOGIC_VECTOR (17 downto 0);
          C	: in STD_ULOGIC ;
          CE	: in STD_ULOGIC ;
	  P	: out STD_LOGIC_VECTOR (35 downto 0);
          R 	: in STD_ULOGIC );

end component;
attribute syn_black_box of MULT18X18S : component is true;
component MULT_AND
 port (
   LO : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic
 );
end component;
attribute syn_black_box of MULT_AND : component is true;
component MUXCY
 port (
   O : out std_logic;
   CI : in std_logic;
   DI : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of MUXCY : component is true;
component MUXCY_D
 port (
   O : out std_logic;
   LO : out std_logic;
   CI : in std_logic;
   DI : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of MUXCY_D : component is true;
component MUXCY_L
 port (
   LO : out std_logic;
   CI : in std_logic;
   DI : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of MUXCY_L : component is true;
component MUXF5
 port (
   O : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of MUXF5 : component is true;
component MUXF5_D
 port (
   O : out std_logic;
   LO : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of MUXF5_D : component is true;
component MUXF5_L
 port (
   LO : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of MUXF5_L : component is true;
component MUXF6
 port (
   O : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of MUXF6 : component is true;
component MUXF6_D
 port (
   O : out std_logic;
   LO : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of MUXF6_D : component is true;
component MUXF6_L
 port (
   LO : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of MUXF6_L : component is true;
component MUXF7
 port (
   O : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of MUXF7 : component is true;
component MUXF7_D
 port (
   O : out std_logic;
   LO : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of MUXF7_D : component is true;
component MUXF7_L
 port (
   LO : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of MUXF7_L : component is true;
component MUXF8
 port (
   O : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of MUXF8 : component is true;
component MUXF8_D
 port (
   O : out std_logic;
   LO : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of MUXF8_D : component is true;
component MUXF8_L
 port (
   LO : out std_logic;
   I0 : in std_logic;
   I1 : in std_logic;
   S : in std_logic
 );
end component;
attribute syn_black_box of MUXF8_L : component is true;
component OBUF
 generic (
   IOSTANDARD : string := "default";
   SLEW : string := "SLOW";
   DRIVE : integer := 12
 );
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF : component is true;
component OBUFDS
 generic (
   IOSTANDARD : string := "default";
   SLEW : string := "SLOW";
   DRIVE : integer := 12
 );
 port (
   O : out std_logic;
   OB : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUFDS : component is true;
component OBUFDS_BLVDS_25
 port (
   O : out std_logic;
   OB : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUFDS_BLVDS_25 : component is true;
component OBUFDS_LDT_25
 port (
   O : out std_logic;
   OB : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUFDS_LDT_25 : component is true;
component OBUFDS_LVDSEXT_25
 port (
   O : out std_logic;
   OB : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUFDS_LVDSEXT_25 : component is true;
component OBUFDS_LVDSEXT_33
 port (
   O : out std_logic;
   OB : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUFDS_LVDSEXT_33 : component is true;
component OBUFDS_LVDS_25
 port (
   O : out std_logic;
   OB : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUFDS_LVDS_25 : component is true;
component OBUFDS_LVDS_33
 port (
   O : out std_logic;
   OB : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUFDS_LVDS_33 : component is true;
component OBUFDS_ULVDS_25
 port (
   O : out std_logic;
   OB : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUFDS_ULVDS_25 : component is true;
component OBUFDS_LVPECL_33
 port (
   O : out std_logic;
   OB : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUFDS_LVPECL_33 : component is true;
component OBUFT
 generic (
   IOSTANDARD : string := "default";
   SLEW : string := "SLOW";
   DRIVE : integer := 12
 );
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT : component is true;
attribute black_box_tri_pins of OBUFT : component is "O";
component OBUFTDS
 generic (
   IOSTANDARD : string := "default";
   SLEW : string := "SLOW";
   DRIVE : integer := 12
 );
 port (
   O : out std_logic;
   OB : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFTDS : component is true;
attribute black_box_tri_pins of OBUFTDS : component is "O,OB";
component OBUFTDS_BLVDS_25
 port (
   O : out std_logic;
   OB : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFTDS_BLVDS_25 : component is true;
attribute black_box_tri_pins of OBUFTDS_BLVDS_25 : component is "O,OB";
component OBUFTDS_LDT_25
 port (
   O : out std_logic;
   OB : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFTDS_LDT_25 : component is true;
attribute black_box_tri_pins of OBUFTDS_LDT_25 : component is "O,OB";
component OBUFTDS_LVDSEXT_25
 port (
   O : out std_logic;
   OB : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFTDS_LVDSEXT_25 : component is true;
attribute black_box_tri_pins of OBUFTDS_LVDSEXT_25 : component is "O,OB";
component OBUFTDS_LVDSEXT_33
 port (
   O : out std_logic;
   OB : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFTDS_LVDSEXT_33 : component is true;
attribute black_box_tri_pins of OBUFTDS_LVDSEXT_33 : component is "O,OB";
component OBUFTDS_LVDS_25
 port (
   O : out std_logic;
   OB : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFTDS_LVDS_25 : component is true;
attribute black_box_tri_pins of OBUFTDS_LVDS_25 : component is "O,OB";
component OBUFTDS_LVDS_33
 port (
   O : out std_logic;
   OB : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFTDS_LVDS_33 : component is true;
attribute black_box_tri_pins of OBUFTDS_LVDS_33 : component is "O,OB";
component OBUFTDS_ULVDS_25
 port (
   O : out std_logic;
   OB : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFTDS_ULVDS_25 : component is true;
attribute black_box_tri_pins of OBUFTDS_ULVDS_25 : component is "O,OB";
component OBUFTDS_LVPECL_33
 port (
   O : out std_logic;
   OB : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFTDS_LVPECL_33 : component is true;
attribute black_box_tri_pins of OBUFTDS_LVPECL_33 : component is "O,OB";
component OBUFT_AGP
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_AGP : component is true;
attribute black_box_tri_pins of OBUFT_AGP : component is "O";
component OBUFT_F_12
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_F_12 : component is true;
attribute black_box_tri_pins of OBUFT_F_12 : component is "O";
component OBUFT_F_16
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_F_16 : component is true;
attribute black_box_tri_pins of OBUFT_F_16 : component is "O";
component OBUFT_F_2
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_F_2 : component is true;
attribute black_box_tri_pins of OBUFT_F_2 : component is "O";
component OBUFT_F_24
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_F_24 : component is true;
attribute black_box_tri_pins of OBUFT_F_24 : component is "O";
component OBUFT_F_4
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_F_4 : component is true;
attribute black_box_tri_pins of OBUFT_F_4 : component is "O";
component OBUFT_F_6
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_F_6 : component is true;
attribute black_box_tri_pins of OBUFT_F_6 : component is "O";
component OBUFT_F_8
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_F_8 : component is true;
attribute black_box_tri_pins of OBUFT_F_8 : component is "O";
component OBUFT_GTL
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_GTL : component is true;
attribute black_box_tri_pins of OBUFT_GTL : component is "O";
component OBUFT_GTL_DCI
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_GTL_DCI : component is true;
attribute black_box_tri_pins of OBUFT_GTL_DCI : component is "O";
component OBUFT_GTLP
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_GTLP : component is true;
attribute black_box_tri_pins of OBUFT_GTLP : component is "O";
component OBUFT_GTLP_DCI
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_GTLP_DCI : component is true;
attribute black_box_tri_pins of OBUFT_GTLP_DCI : component is "O";
component OBUFT_HSTL_I
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_HSTL_I : component is true;
attribute black_box_tri_pins of OBUFT_HSTL_I : component is "O";
component OBUFT_HSTL_I_18
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_HSTL_I_18 : component is true;
attribute black_box_tri_pins of OBUFT_HSTL_I_18 : component is "O";
component OBUFT_HSTL_I_DCI
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_HSTL_I_DCI : component is true;
attribute black_box_tri_pins of OBUFT_HSTL_I_DCI : component is "O";
component OBUFT_HSTL_I_DCI_18
  port (
    O : out std_logic;
    I : in std_logic;
    T : in std_logic
  );
end component;
attribute syn_black_Box of OBUFT_HSTL_I_DCI_18 : component is true;
attribute black_box_tri_pins of OBUFT_HSTL_I_DCI_18 : component is "O";
component OBUFT_HSTL_II
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_HSTL_II : component is true;
attribute black_box_tri_pins of OBUFT_HSTL_II : component is "O";
component OBUFT_HSTL_II_18
  port (
    O : out std_logic;
    I : in std_logic;
    T : in std_logic
  );
end component;
attribute syn_black_box of OBUFT_HSTL_II_18 : component is true;
attribute black_box_tri_pins of OBUFT_HSTL_II_18 : component is "O";
component OBUFT_HSTL_II_DCI
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_HSTL_II_DCI : component is true;
attribute black_box_tri_pins of OBUFT_HSTL_II_DCI : component is "O";
component OBUFT_HSTL_II_DCI_18
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_HSTL_II_DCI_18 : component is true;
attribute black_box_tri_pins of OBUFT_HSTL_II_DCI_18 : component is "O";
component OBUFT_HSTL_III
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_HSTL_III : component is true;
attribute black_box_tri_pins of OBUFT_HSTL_III : component is "O";
component OBUFT_HSTL_III_18
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_HSTL_III_18 : component is true;
attribute black_box_tri_pins of OBUFT_HSTL_III_18 : component is "O";
component OBUFT_HSTL_III_DCI
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_HSTL_III_DCI : component is true;
attribute black_box_tri_pins of OBUFT_HSTL_III_DCI : component is "O";
component OBUFT_HSTL_III_DCI_18
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_HSTL_III_DCI_18 : component is true;
attribute black_box_tri_pins of OBUFT_HSTL_III_DCI_18 : component is "O";
component OBUFT_HSTL_IV
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_HSTL_IV : component is true;
attribute black_box_tri_pins of OBUFT_HSTL_IV : component is "O";
component OBUFT_HSTL_IV_DCI
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_HSTL_IV_DCI : component is true;
attribute black_box_tri_pins of OBUFT_HSTL_IV_DCI : component is "O";
component OBUFT_HSTL_IV_DCI_18
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_HSTL_IV_DCI_18 : component is true;
attribute black_box_tri_pins of OBUFT_HSTL_IV_DCI_18 : component is "O";
component OBUFT_LVCMOS15
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS15 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS15 : component is "O";
component OBUFT_LVCMOS15_F_12
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS15_F_12 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS15_F_12 : component is "O";
component OBUFT_LVCMOS15_F_16
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS15_F_16 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS15_F_16 : component is "O";
component OBUFT_LVCMOS15_F_2
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS15_F_2 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS15_F_2 : component is "O";
component OBUFT_LVCMOS15_F_4
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS15_F_4 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS15_F_4 : component is "O";
component OBUFT_LVCMOS15_F_6
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS15_F_6 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS15_F_6 : component is "O";
component OBUFT_LVCMOS15_F_8
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS15_F_8 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS15_F_8 : component is "O";
component OBUFT_LVCMOS15_S_12
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS15_S_12 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS15_S_12 : component is "O";
component OBUFT_LVCMOS15_S_16
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS15_S_16 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS15_S_16 : component is "O";
component OBUFT_LVCMOS15_S_2
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS15_S_2 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS15_S_2 : component is "O";
component OBUFT_LVCMOS15_S_4
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS15_S_4 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS15_S_4 : component is "O";
component OBUFT_LVCMOS15_S_6
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS15_S_6 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS15_S_6 : component is "O";
component OBUFT_LVCMOS15_S_8
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS15_S_8 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS15_S_8 : component is "O";
component OBUFT_LVCMOS18
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS18 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS18 : component is "O";
component OBUFT_LVCMOS18_F_12
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS18_F_12 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS18_F_12 : component is "O";
component OBUFT_LVCMOS18_F_16
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS18_F_16 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS18_F_16 : component is "O";
component OBUFT_LVCMOS18_F_2
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS18_F_2 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS18_F_2 : component is "O";
component OBUFT_LVCMOS18_F_4
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS18_F_4 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS18_F_4 : component is "O";
component OBUFT_LVCMOS18_F_6
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS18_F_6 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS18_F_6 : component is "O";
component OBUFT_LVCMOS18_F_8
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS18_F_8 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS18_F_8 : component is "O";
component OBUFT_LVCMOS18_S_12
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS18_S_12 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS18_S_12 : component is "O";
component OBUFT_LVCMOS18_S_16
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS18_S_16 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS18_S_16 : component is "O";
component OBUFT_LVCMOS18_S_2
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS18_S_2 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS18_S_2 : component is "O";
component OBUFT_LVCMOS18_S_4
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS18_S_4 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS18_S_4 : component is "O";
component OBUFT_LVCMOS18_S_6
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS18_S_6 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS18_S_6 : component is "O";
component OBUFT_LVCMOS18_S_8
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS18_S_8 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS18_S_8 : component is "O";
component OBUFT_LVCMOS2
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS2 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS2 : component is "O";
component OBUFT_LVCMOS25
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS25 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS25 : component is "O";
component OBUFT_LVCMOS25_F_12
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS25_F_12 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS25_F_12 : component is "O";
component OBUFT_LVCMOS25_F_16
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS25_F_16 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS25_F_16 : component is "O";
component OBUFT_LVCMOS25_F_2
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS25_F_2 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS25_F_2 : component is "O";
component OBUFT_LVCMOS25_F_24
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS25_F_24 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS25_F_24 : component is "O";
component OBUFT_LVCMOS25_F_4
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS25_F_4 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS25_F_4 : component is "O";
component OBUFT_LVCMOS25_F_6
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS25_F_6 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS25_F_6 : component is "O";
component OBUFT_LVCMOS25_F_8
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS25_F_8 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS25_F_8 : component is "O";
component OBUFT_LVCMOS25_S_12
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS25_S_12 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS25_S_12 : component is "O";
component OBUFT_LVCMOS25_S_16
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS25_S_16 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS25_S_16 : component is "O";
component OBUFT_LVCMOS25_S_2
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS25_S_2 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS25_S_2 : component is "O";
component OBUFT_LVCMOS25_S_24
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS25_S_24 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS25_S_24 : component is "O";
component OBUFT_LVCMOS25_S_4
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS25_S_4 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS25_S_4 : component is "O";
component OBUFT_LVCMOS25_S_6
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS25_S_6 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS25_S_6 : component is "O";
component OBUFT_LVCMOS25_S_8
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVCMOS25_S_8 : component is true;
attribute black_box_tri_pins of OBUFT_LVCMOS25_S_8 : component is "O";
component OBUFT_LVDCI_15
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVDCI_15 : component is true;
attribute black_box_tri_pins of OBUFT_LVDCI_15 : component is "O";
component OBUFT_LVDCI_18
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVDCI_18 : component is true;
attribute black_box_tri_pins of OBUFT_LVDCI_18 : component is "O";
component OBUFT_LVDCI_25
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVDCI_25 : component is true;
attribute black_box_tri_pins of OBUFT_LVDCI_25 : component is "O";
component OBUFT_LVDCI_33
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVDCI_33 : component is true;
attribute black_box_tri_pins of OBUFT_LVDCI_33 : component is "O";
component OBUFT_LVDCI_DV2_15
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVDCI_DV2_15 : component is true;
attribute black_box_tri_pins of OBUFT_LVDCI_DV2_15 : component is "O";
component OBUFT_LVDCI_DV2_18
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVDCI_DV2_18 : component is true;
attribute black_box_tri_pins of OBUFT_LVDCI_DV2_18 : component is "O";
component OBUFT_LVDCI_DV2_25
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVDCI_DV2_25 : component is true;
attribute black_box_tri_pins of OBUFT_LVDCI_DV2_25 : component is "O";
component OBUFT_LVDS
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVDS : component is true;
attribute black_box_tri_pins of OBUFT_LVDS : component is "O";
component OBUFT_LVPECL
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_LVPECL : component is true;
attribute black_box_tri_pins of OBUFT_LVPECL : component is "O";
component OBUFT_PCI33_3
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_PCI33_3 : component is true;
attribute black_box_tri_pins of OBUFT_PCI33_3 : component is "O";
component OBUFT_PCI66_3
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_PCI66_3 : component is true;
attribute black_box_tri_pins of OBUFT_PCI66_3 : component is "O";
component OBUFT_PCIX
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_PCIX : component is true;
attribute black_box_tri_pins of OBUFT_PCIX : component is "O";
component OBUFT_SSTL2_I
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_SSTL2_I : component is true;
attribute black_box_tri_pins of OBUFT_SSTL2_I : component is "O";
component OBUFT_SSTL2_I_DCI
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_SSTL2_I_DCI : component is true;
attribute black_box_tri_pins of OBUFT_SSTL2_I_DCI : component is "O";
component OBUFT_SSTL2_II
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_SSTL2_II : component is true;
attribute black_box_tri_pins of OBUFT_SSTL2_II : component is "O";
component OBUFT_SSTL2_II_DCI
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_SSTL2_II_DCI : component is true;
attribute black_box_tri_pins of OBUFT_SSTL2_II_DCI : component is "O";
component OBUFT_S_12
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_S_12 : component is true;
attribute black_box_tri_pins of OBUFT_S_12 : component is "O";
component OBUFT_S_16
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_S_16 : component is true;
attribute black_box_tri_pins of OBUFT_S_16 : component is "O";
component OBUFT_S_2
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_S_2 : component is true;
attribute black_box_tri_pins of OBUFT_S_2 : component is "O";
component OBUFT_S_24
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_S_24 : component is true;
attribute black_box_tri_pins of OBUFT_S_24 : component is "O";
component OBUFT_S_4
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_S_4 : component is true;
attribute black_box_tri_pins of OBUFT_S_4 : component is "O";
component OBUFT_S_6
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_S_6 : component is true;
attribute black_box_tri_pins of OBUFT_S_6 : component is "O";
component OBUFT_S_8
 port (
   O : out std_logic;
   I : in std_logic;
   T : in std_logic
 );
end component;
attribute syn_black_box of OBUFT_S_8 : component is true;
attribute black_box_tri_pins of OBUFT_S_8 : component is "O";
component OBUF_AGP
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_AGP : component is true;
component OBUF_F_12
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_F_12 : component is true;
component OBUF_F_16
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_F_16 : component is true;
component OBUF_F_2
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_F_2 : component is true;
component OBUF_F_24
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_F_24 : component is true;
component OBUF_F_4
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_F_4 : component is true;
component OBUF_F_6
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_F_6 : component is true;
component OBUF_F_8
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_F_8 : component is true;
component OBUF_GTL
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_GTL : component is true;
component OBUF_GTL_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_GTL_DCI : component is true;
component OBUF_GTLP
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_GTLP : component is true;
component OBUF_GTLP_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_GTLP_DCI : component is true;
component OBUF_HSTL_I
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_HSTL_I : component is true;
component OBUF_HSTL_I_18
  port (
    O : out std_logic;
    i : in std_logic
  );
end component;
attribute syn_black_box of OBUF_HSTL_I_18 : component is true;
component OBUF_HSTL_I_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_HSTL_I_DCI : component is true;
component OBUF_HSTL_I_DCI_18
 port (
    O : out std_logic;
    I : in std_logic
  );
end component;
attribute syn_black_Box of OBUF_HSTL_I_DCI_18 : component is true;
component OBUF_HSTL_II
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_HSTL_II : component is true;
component OBUF_HSTL_II_18
  port (
    O : out std_logic;
    I : in std_logic
  );
end component;
attribute syn_black_box of OBUF_HSTL_II_18 : component is true;
component OBUF_HSTL_II_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_HSTL_II_DCI : component is true;
component OBUF_HSTL_II_DCI_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_HSTL_II_DCI_18 : component is true;
component OBUF_HSTL_III
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_HSTL_III : component is true;
component OBUF_HSTL_III_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_HSTL_III_18 : component is true;
component OBUF_HSTL_III_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_HSTL_III_DCI : component is true;
component OBUF_HSTL_IV
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_HSTL_IV : component is true;
component OBUF_HSTL_IV_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_HSTL_IV_18 : component is true;
component OBUF_HSTL_IV_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_HSTL_IV_DCI : component is true;
component OBUF_HSTL_IV_DCI_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_HSTL_IV_DCI_18 : component is true;
component OBUF_LVCMOS15
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS15 : component is true;
component OBUF_LVCMOS15_F_12
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS15_F_12 : component is true;
component OBUF_LVCMOS15_F_16
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS15_F_16 : component is true;
component OBUF_LVCMOS15_F_2
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS15_F_2 : component is true;
component OBUF_LVCMOS15_F_4
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS15_F_4 : component is true;
component OBUF_LVCMOS15_F_6
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS15_F_6 : component is true;
component OBUF_LVCMOS15_F_8
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS15_F_8 : component is true;
component OBUF_LVCMOS15_S_12
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS15_S_12 : component is true;
component OBUF_LVCMOS15_S_16
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS15_S_16 : component is true;
component OBUF_LVCMOS15_S_2
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS15_S_2 : component is true;
component OBUF_LVCMOS15_S_4
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS15_S_4 : component is true;
component OBUF_LVCMOS15_S_6
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS15_S_6 : component is true;
component OBUF_LVCMOS15_S_8
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS15_S_8 : component is true;
component OBUF_LVCMOS18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS18 : component is true;
component OBUF_LVCMOS18_F_12
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS18_F_12 : component is true;
component OBUF_LVCMOS18_F_16
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS18_F_16 : component is true;
component OBUF_LVCMOS18_F_2
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS18_F_2 : component is true;
component OBUF_LVCMOS18_F_4
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS18_F_4 : component is true;
component OBUF_LVCMOS18_F_6
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS18_F_6 : component is true;
component OBUF_LVCMOS18_F_8
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS18_F_8 : component is true;
component OBUF_LVCMOS18_S_12
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS18_S_12 : component is true;
component OBUF_LVCMOS18_S_16
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS18_S_16 : component is true;
component OBUF_LVCMOS18_S_2
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS18_S_2 : component is true;
component OBUF_LVCMOS18_S_4
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS18_S_4 : component is true;
component OBUF_LVCMOS18_S_6
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS18_S_6 : component is true;
component OBUF_LVCMOS18_S_8
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS18_S_8 : component is true;
component OBUF_LVCMOS2
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS2 : component is true;
component OBUF_LVCMOS25
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS25 : component is true;
component OBUF_LVCMOS25_F_12
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS25_F_12 : component is true;
component OBUF_LVCMOS25_F_16
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS25_F_16 : component is true;
component OBUF_LVCMOS25_F_2
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS25_F_2 : component is true;
component OBUF_LVCMOS25_F_24
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS25_F_24 : component is true;
component OBUF_LVCMOS25_F_4
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS25_F_4 : component is true;
component OBUF_LVCMOS25_F_6
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS25_F_6 : component is true;
component OBUF_LVCMOS25_F_8
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS25_F_8 : component is true;
component OBUF_LVCMOS25_S_12
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS25_S_12 : component is true;
component OBUF_LVCMOS25_S_16
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS25_S_16 : component is true;
component OBUF_LVCMOS25_S_2
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS25_S_2 : component is true;
component OBUF_LVCMOS25_S_24
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS25_S_24 : component is true;
component OBUF_LVCMOS25_S_4
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS25_S_4 : component is true;
component OBUF_LVCMOS25_S_6
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS25_S_6 : component is true;
component OBUF_LVCMOS25_S_8
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVCMOS25_S_8 : component is true;
component OBUF_LVDS
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVDS : component is true;
component OBUF_LVDCI_15
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVDCI_15 : component is true;
component OBUF_LVDCI_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVDCI_18 : component is true;
component OBUF_LVDCI_25
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVDCI_25 : component is true;
component OBUF_LVDCI_33
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVDCI_33 : component is true;
component OBUF_LVDCI_DV2_15
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVDCI_DV2_15 : component is true;
component OBUF_LVDCI_DV2_18
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVDCI_DV2_18 : component is true;
component OBUF_LVDCI_DV2_25
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVDCI_DV2_25 : component is true;
component OBUF_LVPECL
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_LVPECL : component is true;
component OBUF_PCI33_3
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_PCI33_3 : component is true;
component OBUF_PCI66_3
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_PCI66_3 : component is true;
component OBUF_PCIX
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_PCIX : component is true;
component OBUF_SSTL2_I
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_SSTL2_I : component is true;
component OBUF_SSTL2_I_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_SSTL2_I_DCI : component is true;
component OBUF_SSTL2_II
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_SSTL2_II : component is true;
component OBUF_SSTL2_II_DCI
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_SSTL2_II_DCI : component is true;
component OBUF_S_12
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_S_12 : component is true;
component OBUF_S_16
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_S_16 : component is true;
component OBUF_S_2
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_S_2 : component is true;
component OBUF_S_24
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_S_24 : component is true;
component OBUF_S_4
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_S_4 : component is true;
component OBUF_S_6
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_S_6 : component is true;
component OBUF_S_8
 port (
   O : out std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of OBUF_S_8 : component is true;
component ORCY
 port (
   O : out std_logic;
   CI : in std_logic;
   I : in std_logic
 );
end component;
attribute syn_black_box of ORCY : component is true;
component PULLDOWN
 port (
   O : out std_logic
 );
end component;
attribute syn_black_box of PULLDOWN : component is true;
attribute syn_noprune of PULLDOWN : component is true;
component PULLUP
 port (
   O : out std_logic
 );
end component;
attribute syn_black_box of PULLUP : component is true;
attribute syn_noprune of PULLUP : component is true;
component RAM128X1S
 generic(INIT : bit_vector := X"00000000000000000000000000000000");
 port (
   O : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   A4 : in std_logic;
   A5 : in std_logic;
   A6 : in std_logic;
   D : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM128X1S : component is true;
component RAM128X1S_1
 generic(INIT : bit_vector := X"00000000000000000000000000000000");
 port (
   O : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   A4 : in std_logic;
   A5 : in std_logic;
   A6 : in std_logic;
   D : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM128X1S_1 : component is true;
component RAM16X1D
 generic(INIT : bit_vector := X"0000");
 port (
   DPO : out std_logic;
   SPO : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   D : in std_logic;
   DPRA0 : in std_logic;
   DPRA1 : in std_logic;
   DPRA2 : in std_logic;
   DPRA3 : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM16X1D : component is true;
component RAM16X1D_1
 generic(INIT : bit_vector := X"0000");
 port (
   DPO : out std_logic;
   SPO : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   D : in std_logic;
   DPRA0 : in std_logic;
   DPRA1 : in std_logic;
   DPRA2 : in std_logic;
   DPRA3 : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM16X1D_1 : component is true;
component RAM16X1S
 generic(INIT : bit_vector := X"0000");
 port (
   O : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   D : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM16X1S : component is true;
component RAM16X1S_1
 generic(INIT : bit_vector := X"0000");
 port (
   O : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   D : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM16X1S_1 : component is true;
component RAM16X2S
  generic (
       INIT_00 : bit_vector(15 downto 0) := X"0000";
       INIT_01 : bit_vector(15 downto 0) := X"0000"
  );
 port (
   O0 : out std_logic;
   O1 : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   D0 : in std_logic;
   D1 : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM16X2S : component is true;
component RAM16X4S
  generic (
       INIT_00 : bit_vector(15 downto 0) := X"0000";
       INIT_01 : bit_vector(15 downto 0) := X"0000";
       INIT_02 : bit_vector(15 downto 0) := X"0000";
       INIT_03 : bit_vector(15 downto 0) := X"0000"
  );
 port (
   O0 : out std_logic;
   O1 : out std_logic;
   O2 : out std_logic;
   O3 : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   D0 : in std_logic;
   D1 : in std_logic;
   D2 : in std_logic;
   D3 : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM16X4S : component is true;
component RAM16X8S
  generic (
       INIT_00 : bit_vector(15 downto 0) := X"0000";
       INIT_01 : bit_vector(15 downto 0) := X"0000";
       INIT_02 : bit_vector(15 downto 0) := X"0000";
       INIT_03 : bit_vector(15 downto 0) := X"0000";
       INIT_04 : bit_vector(15 downto 0) := X"0000";
       INIT_05 : bit_vector(15 downto 0) := X"0000";
       INIT_06 : bit_vector(15 downto 0) := X"0000";
       INIT_07 : bit_vector(15 downto 0) := X"0000"
  );
 port (
   O : out std_logic_vector(7 downto 0);
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   D : in std_logic_vector(7 downto 0);
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM16X8S : component is true;
component RAM32X1D
 generic(INIT : bit_vector := X"00000000");
 port (
   DPO : out std_logic;
   SPO : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   A4 : in std_logic;
   D : in std_logic;
   DPRA0 : in std_logic;
   DPRA1 : in std_logic;
   DPRA2 : in std_logic;
   DPRA3 : in std_logic;
   DPRA4 : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM32X1D : component is true;
component RAM32X1D_1
 generic(INIT : bit_vector := X"00000000");
 port (
   DPO : out std_logic;
   SPO : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   A4 : in std_logic;
   D : in std_logic;
   DPRA0 : in std_logic;
   DPRA1 : in std_logic;
   DPRA2 : in std_logic;
   DPRA3 : in std_logic;
   DPRA4 : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM32X1D_1 : component is true;
component RAM32X1S
 generic(INIT : bit_vector := X"00000000");
 port (
   O : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   A4 : in std_logic;
   D : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM32X1S : component is true;
component RAM32X1S_1
 generic(INIT : bit_vector := X"00000000");
 port (
   O : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   A4 : in std_logic;
   D : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM32X1S_1 : component is true;
component RAM32X2S
  generic (
       INIT_00 : bit_vector(31 downto 0) := X"00000000";
       INIT_01 : bit_vector(31 downto 0) := X"00000000"
  );
 port (
   O0 : out std_logic;
   O1 : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   A4 : in std_logic;
   D0 : in std_logic;
   D1 : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM32X2S : component is true;
component RAM32X4S
  generic (
       INIT_00 : bit_vector(31 downto 0) := X"00000000";
       INIT_01 : bit_vector(31 downto 0) := X"00000000";
       INIT_02 : bit_vector(31 downto 0) := X"00000000";
       INIT_03 : bit_vector(31 downto 0) := X"00000000"
  );
 port (
   O0 : out std_logic;
   O1 : out std_logic;
   O2 : out std_logic;
   O3 : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   A4 : in std_logic;
   D0 : in std_logic;
   D1 : in std_logic;
   D2 : in std_logic;
   D3 : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM32X4S : component is true;
component RAM32X8S
  generic (
       INIT_00 : bit_vector(31 downto 0) := X"00000000";
       INIT_01 : bit_vector(31 downto 0) := X"00000000";
       INIT_02 : bit_vector(31 downto 0) := X"00000000";
       INIT_03 : bit_vector(31 downto 0) := X"00000000";
       INIT_04 : bit_vector(31 downto 0) := X"00000000";
       INIT_05 : bit_vector(31 downto 0) := X"00000000";
       INIT_06 : bit_vector(31 downto 0) := X"00000000";
       INIT_07 : bit_vector(31 downto 0) := X"00000000"
  );
 port (
   O : out std_logic_vector(7 downto 0);
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   A4 : in std_logic;
   D : in std_logic_vector(7 downto 0);
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM32X8S : component is true;
component RAM64X1D
  generic (INIT : bit_vector := X"0000000000000000");
 port (
   DPO : out std_logic;
   SPO : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   A4 : in std_logic;
   A5 : in std_logic;
   D : in std_logic;
   DPRA0 : in std_logic;
   DPRA1 : in std_logic;
   DPRA2 : in std_logic;
   DPRA3 : in std_logic;
   DPRA4 : in std_logic;
   DPRA5 : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM64X1D : component is true;
component RAM64X1D_1
  generic (INIT : bit_vector := X"0000000000000000");
 port (
   DPO : out std_logic;
   SPO : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   A4 : in std_logic;
   A5 : in std_logic;
   D : in std_logic;
   DPRA0 : in std_logic;
   DPRA1 : in std_logic;
   DPRA2 : in std_logic;
   DPRA3 : in std_logic;
   DPRA4 : in std_logic;
   DPRA5 : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM64X1D_1 : component is true;
component RAM64X1S
  generic (INIT : bit_vector := X"0000000000000000");
 port (
   O : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   A4 : in std_logic;
   A5 : in std_logic;
   D : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM64X1S : component is true;
component RAM64X1S_1
  generic (INIT : bit_vector := X"0000000000000000");
 port (
   O : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   A4 : in std_logic;
   A5 : in std_logic;
   D : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM64X1S_1 : component is true;
component RAM64X2S
  generic (
       INIT_00 : bit_vector(63 downto 0) := X"0000000000000000";
       INIT_01 : bit_vector(63 downto 0) := X"0000000000000000"
  );
 port (
   O0 : out std_logic;
   O1 : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   A4 : in std_logic;
   A5 : in std_logic;
   D0 : in std_logic;
   D1 : in std_logic;
   WCLK : in std_logic;
   WE : in std_logic
 );
end component;
attribute syn_black_box of RAM64X2S : component is true;
component RAMB4_S1
 port (
    DO : out std_logic_vector (0 downto 0);
    ADDR : in std_logic_vector (11 downto 0);
	DI : in std_logic_vector (0 downto 0);
    EN : in std_logic;
    CLK : in std_logic;
    WE : in std_logic;
    RST : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S1 : component is true;
component RAMB4_S16
 port (
    DO : out std_logic_vector (15 downto 0);
    ADDR : in std_logic_vector (7 downto 0);
    DI : in std_logic_vector (15 downto 0);
    EN : in std_logic;
    CLK : in std_logic;
    WE : in std_logic;
    RST : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S16 : component is true;
component RAMB4_S16_S16
 port (
    DOA : out std_logic_vector (15 downto 0);
    DOB : out std_logic_vector (15 downto 0);
    ADDRA : in std_logic_vector (7 downto 0);
    DIA : in std_logic_vector (15 downto 0);
    ENA : in std_logic;
    CLKA : in std_logic;
    WEA : in std_logic;
    RSTA : in std_logic;
    ADDRB : in std_logic_vector (7 downto 0);
    DIB : in std_logic_vector (15 downto 0);
    ENB : in std_logic;
    CLKB : in std_logic;
    WEB : in std_logic;
    RSTB : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S16_S16 : component is true;
component RAMB4_S1_S1
 port (
    DOA : out std_logic_vector (0 downto 0);
    DOB : out std_logic_vector (0 downto 0);
    ADDRA : in std_logic_vector (11 downto 0);
    DIA : in std_logic_vector (0 downto 0);
    ENA : in std_logic;
    CLKA : in std_logic;
    WEA : in std_logic;
    RSTA : in std_logic;
    ADDRB : in std_logic_vector (11 downto 0);
    DIB : in std_logic_vector (0 downto 0);
    ENB : in std_logic;
    CLKB : in std_logic;
    WEB : in std_logic;
    RSTB : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S1_S1 : component is true;
component RAMB4_S1_S16
 port (
    DOA : out std_logic_vector (0 downto 0);
    DOB : out std_logic_vector (15 downto 0);
    ADDRA : in std_logic_vector (11 downto 0);
    DIA : in std_logic_vector (0 downto 0);
    ENA : in std_logic;
    CLKA : in std_logic;
    WEA : in std_logic;
    RSTA : in std_logic;
    ADDRB : in std_logic_vector (7 downto 0);
    DIB : in std_logic_vector (15 downto 0);
    ENB : in std_logic;
    CLKB : in std_logic;
    WEB : in std_logic;
    RSTB : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S1_S16 : component is true;
component RAMB4_S1_S2
 port (
    DOA : out std_logic_vector (0 downto 0);
    DOB : out std_logic_vector (1 downto 0);
    ADDRA : in std_logic_vector (11 downto 0);
    DIA : in std_logic_vector (0 downto 0);
    ENA : in std_logic;
    CLKA : in std_logic;
    WEA : in std_logic;
    RSTA : in std_logic;
    ADDRB : in std_logic_vector (10 downto 0);
    DIB : in std_logic_vector (1 downto 0);
    ENB : in std_logic;
    CLKB : in std_logic;
    WEB : in std_logic;
    RSTB : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S1_S2 : component is true;
component RAMB4_S1_S4
 port (
    DOA : out std_logic_vector (0 downto 0);
    DOB : out std_logic_vector (3 downto 0);
    ADDRA : in std_logic_vector (11 downto 0);
    DIA : in std_logic_vector (0 downto 0);
    ENA : in std_logic;
    CLKA : in std_logic;
    WEA : in std_logic;
    RSTA : in std_logic;
    ADDRB : in std_logic_vector (9 downto 0);
    DIB : in std_logic_vector (3 downto 0);
    ENB : in std_logic;
    CLKB : in std_logic;
    WEB : in std_logic;
    RSTB : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S1_S4 : component is true;
component RAMB4_S1_S8
 port (
    DOA : out std_logic_vector (0 downto 0);
    DOB : out std_logic_vector (7 downto 0);
    ADDRA : in std_logic_vector (11 downto 0);
    DIA : in std_logic_vector (0 downto 0);
    ENA : in std_logic;
    CLKA : in std_logic;
    WEA : in std_logic;
    RSTA : in std_logic;
    ADDRB : in std_logic_vector (8 downto 0);
    DIB : in std_logic_vector (7 downto 0);
    ENB : in std_logic;
    CLKB : in std_logic;
    WEB : in std_logic;
    RSTB : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S1_S8 : component is true;
component RAMB4_S2
 port (
    DO : out std_logic_vector (1 downto 0);
    ADDR : in std_logic_vector (10 downto 0);
    DI : in std_logic_vector (1 downto 0);
    EN : in std_logic;
    CLK : in std_logic;
    WE : in std_logic;
    RST : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S2 : component is true;
component RAMB4_S2_S16
 port (
    DOA : out std_logic_vector (1 downto 0);
    DOB : out std_logic_vector (15 downto 0);
    ADDRA : in std_logic_vector (10 downto 0);
    DIA : in std_logic_vector (1 downto 0);
    ENA : in std_logic;
    CLKA : in std_logic;
    WEA : in std_logic;
    RSTA : in std_logic;
    ADDRB : in std_logic_vector (7 downto 0);
    DIB : in std_logic_vector (15 downto 0);
    ENB : in std_logic;
    CLKB : in std_logic;
    WEB : in std_logic;
    RSTB : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S2_S16 : component is true;
component RAMB4_S2_S2
 port (
    DOA : out std_logic_vector (1 downto 0);
    DOB : out std_logic_vector (1 downto 0);
    ADDRA : in std_logic_vector (10 downto 0);
    DIA : in std_logic_vector (1 downto 0);
    ENA : in std_logic;
    CLKA : in std_logic;
    WEA : in std_logic;
    RSTA : in std_logic;
    ADDRB : in std_logic_vector (10 downto 0);
    DIB : in std_logic_vector (1 downto 0);
    ENB : in std_logic;
    CLKB : in std_logic;
    WEB : in std_logic;
    RSTB : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S2_S2 : component is true;
component RAMB4_S2_S4
 port (
    DOA : out std_logic_vector (1 downto 0);
    DOB : out std_logic_vector (3 downto 0);
    ADDRA : in std_logic_vector (10 downto 0);
    DIA : in std_logic_vector (1 downto 0);
    ENA : in std_logic;
    CLKA : in std_logic;
    WEA : in std_logic;
    RSTA : in std_logic;
    ADDRB : in std_logic_vector (9 downto 0);
    DIB : in std_logic_vector (3 downto 0);
    ENB : in std_logic;
    CLKB : in std_logic;
    WEB : in std_logic;
    RSTB : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S2_S4 : component is true;
component RAMB4_S2_S8
 port (
    DOA : out std_logic_vector (1 downto 0);
    DOB : out std_logic_vector (7 downto 0);
    ADDRA : in std_logic_vector (10 downto 0);
    DIA : in std_logic_vector (1 downto 0);
    ENA : in std_logic;
    CLKA : in std_logic;
    WEA : in std_logic;
    RSTA : in std_logic;
    ADDRB : in std_logic_vector (8 downto 0);
    DIB : in std_logic_vector (7 downto 0);
    ENB : in std_logic;
    CLKB : in std_logic;
    WEB : in std_logic;
    RSTB : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S2_S8 : component is true;
component RAMB4_S4
 port (
    DO : out std_logic_vector (3 downto 0);
    ADDR : in std_logic_vector (9 downto 0);
    DI : in std_logic_vector (3 downto 0);
    EN : in std_logic;
    CLK : in std_logic;
    WE : in std_logic;
    RST : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S4 : component is true;
component RAMB4_S4_S16
 port (
    DOA : out std_logic_vector (3 downto 0);
    DOB : out std_logic_vector (15 downto 0);
    ADDRA : in std_logic_vector (9 downto 0);
    DIA : in std_logic_vector (3 downto 0);
    ENA : in std_logic;
    CLKA : in std_logic;
    WEA : in std_logic;
    RSTA : in std_logic;
    ADDRB : in std_logic_vector (7 downto 0);
    DIB : in std_logic_vector (15 downto 0);
    ENB : in std_logic;
    CLKB : in std_logic;
    WEB : in std_logic;
    RSTB : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S4_S16 : component is true;
component RAMB4_S4_S4
 port (
    DOA : out std_logic_vector (3 downto 0);
    DOB : out std_logic_vector (3 downto 0);
    ADDRA : in std_logic_vector (9 downto 0);
    DIA : in std_logic_vector (3 downto 0);
    ENA : in std_logic;
    CLKA : in std_logic;
    WEA : in std_logic;
    RSTA : in std_logic;
    ADDRB : in std_logic_vector (9 downto 0);
    DIB : in std_logic_vector (3 downto 0);
    ENB : in std_logic;
    CLKB : in std_logic;
    WEB : in std_logic;
    RSTB : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S4_S4 : component is true;
component RAMB4_S4_S8
 port (
    DOA : out std_logic_vector (3 downto 0);
    DOB : out std_logic_vector (7 downto 0);
    ADDRA : in std_logic_vector (9 downto 0);
    DIA : in std_logic_vector (3 downto 0);
    ENA : in std_logic;
    CLKA : in std_logic;
    WEA : in std_logic;
    RSTA : in std_logic;
    ADDRB : in std_logic_vector (8 downto 0);
    DIB : in std_logic_vector (7 downto 0);
    ENB : in std_logic;
    CLKB : in std_logic;
    WEB : in std_logic;
    RSTB : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S4_S8 : component is true;
component RAMB4_S8
 port (
    DO : out std_logic_vector (7 downto 0);
    ADDR : in std_logic_vector (8 downto 0);
    DI : in std_logic_vector (7 downto 0);
    EN : in std_logic;
    CLK : in std_logic;
    WE : in std_logic;
    RST : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S8 : component is true;
component RAMB4_S8_S16
 port (
    DOA : out std_logic_vector (7 downto 0);
	DOB : out std_logic_vector (15 downto 0);
	ADDRA : in std_logic_vector (8 downto 0);
	DIA : in std_logic_vector (7 downto 0);
    ENA : in std_logic;
    CLKA : in std_logic;
    WEA : in std_logic;
    RSTA : in std_logic;
    ADDRB : in std_logic_vector (7 downto 0);
    DIB : in std_logic_vector (15 downto 0);
    ENB : in std_logic;
    CLKB : in std_logic;
    WEB : in std_logic;
    RSTB : in std_logic
 );
end component;
attribute syn_black_box of RAMB4_S8_S16 : component is true;
component RAMB4_S8_S8
 port (
    DOA : out std_logic_vector (7 downto 0);
    DOB : out std_logic_vector (7 downto 0);
    ADDRA : in std_logic_vector (8 downto 0);
    DIA : in std_logic_vector (7 downto 0);
    ENA : in std_logic;
    CLKA : in std_logic;
    WEA : in std_logic;
    RSTA : in std_logic;
    ADDRB : in std_logic_vector (8 downto 0);
    DIB : in std_logic_vector (7 downto 0);
    ENB : in std_logic;
    CLKB : in std_logic;
    WEB : in std_logic;
    RSTB : in std_logic
 );
end component;
component RAMB16_S1
 port (
   DO : out std_logic_vector (0 downto 0);
   ADDR : in std_logic_vector (13 downto 0);
   DI : in std_logic_vector (0 downto 0);
   EN : in std_logic;
   CLK : in std_logic;
   WE : in std_logic;
   SSR : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S1 : component is true;
component RAMB16_S18
 port (
   DO : out std_logic_vector (15 downto 0);
   DOP : out std_logic_vector (1 downto 0);
   ADDR : in std_logic_vector (9 downto 0);
   DI : in std_logic_vector (15 downto 0);
   DIP : in std_logic_vector (1 downto 0);
   EN : in std_logic;
   CLK : in std_logic;
   WE : in std_logic;
   SSR : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S18 : component is true;
component RAMB16_S18_S18
 port (
   DOA : out std_logic_vector (15 downto 0);
   DOPA : out std_logic_vector (1 downto 0);
   DOB : out std_logic_vector (15 downto 0);
   DOPB : out std_logic_vector (1 downto 0);
   ADDRA : in std_logic_vector (9 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (15 downto 0);
   DIPA : in std_logic_vector (1 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (9 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (15 downto 0);
   DIPB : in std_logic_vector (1 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S18_S18 : component is true;
component RAMB16_S18_S36
 port (
   DOA : out std_logic_vector (15 downto 0);
   DOPA : out std_logic_vector (1 downto 0);
   DOB : out std_logic_vector (31 downto 0);
   DOPB : out std_logic_vector (3 downto 0);
   ADDRA : in std_logic_vector (9 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (15 downto 0);
   DIPA : in std_logic_vector (1 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (8 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (31 downto 0);
   DIPB : in std_logic_vector (3 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S18_S36 : component is true;
component RAMB16_S1_S1
 port (
   DOA : out std_logic_vector (0 downto 0);
   DOB : out std_logic_vector (0 downto 0);
   ADDRA : in std_logic_vector (13 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (0 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (13 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (0 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S1_S1 : component is true;
component RAMB16_S1_S18
 port (
   DOA : out std_logic_vector (0 downto 0);
   DOB : out std_logic_vector (15 downto 0);
   DOPB : out std_logic_vector (1 downto 0);
   ADDRA : in std_logic_vector (13 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (0 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (9 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (15 downto 0);
   DIPB : in std_logic_vector (1 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S1_S18 : component is true;
component RAMB16_S1_S2
 port (
   DOA : out std_logic_vector (0 downto 0);
   DOB : out std_logic_vector (1 downto 0);
   ADDRA : in std_logic_vector (13 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (0 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (12 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (1 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S1_S2 : component is true;
component RAMB16_S1_S36
 port (
   DOA : out std_logic_vector (0 downto 0);
   DOB : out std_logic_vector (31 downto 0);
   DOPB : out std_logic_vector (3 downto 0);
   ADDRA : in std_logic_vector (13 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (0 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (8 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (31 downto 0);
   DIPB : in std_logic_vector (3 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S1_S36 : component is true;
component RAMB16_S1_S4
 port (
   DOA : out std_logic_vector (0 downto 0);
   DOB : out std_logic_vector (3 downto 0);
   ADDRA : in std_logic_vector (13 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (0 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (11 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (3 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S1_S4 : component is true;
component RAMB16_S1_S9
 port (
   DOA : out std_logic_vector (0 downto 0);
   DOB : out std_logic_vector (7 downto 0);
   DOPB : out std_logic_vector (0 downto 0);
   ADDRA : in std_logic_vector (13 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (0 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (10 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (7 downto 0);
   DIPB : in std_logic_vector (0 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S1_S9 : component is true;
component RAMB16_S2
 port (
   DO : out std_logic_vector (1 downto 0);
   ADDR : in std_logic_vector (12 downto 0);
   DI : in std_logic_vector (1 downto 0);
   EN : in std_logic;
   CLK : in std_logic;
   WE : in std_logic;
   SSR : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S2 : component is true;
component RAMB16_S2_S18
 port (
   DOA : out std_logic_vector (1 downto 0);
   DOB : out std_logic_vector (15 downto 0);
   DOPB : out std_logic_vector (1 downto 0);
   ADDRA : in std_logic_vector (12 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (1 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (9 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (15 downto 0);
   DIPB : in std_logic_vector (1 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S2_S18 : component is true;
component RAMB16_S2_S2
 port (
   DOA : out std_logic_vector (1 downto 0);
   DOB : out std_logic_vector (1 downto 0);
   ADDRA : in std_logic_vector (12 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (1 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (12 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (1 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S2_S2 : component is true;
component RAMB16_S2_S36
 port (
   DOA : out std_logic_vector (1 downto 0);
   DOB : out std_logic_vector (31 downto 0);
   DOPB : out std_logic_vector (3 downto 0);
   ADDRA : in std_logic_vector (12 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (1 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (8 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (31 downto 0);
   DIPB : in std_logic_vector (3 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S2_S36 : component is true;
component RAMB16_S2_S4
 port (
   DOA : out std_logic_vector (1 downto 0);
   DOB : out std_logic_vector (3 downto 0);
   ADDRA : in std_logic_vector (12 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (1 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (11 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (3 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S2_S4 : component is true;
component RAMB16_S2_S9
 port (
   DOA : out std_logic_vector (1 downto 0);
   DOB : out std_logic_vector (7 downto 0);
   DOPB : out std_logic_vector (0 downto 0);
   ADDRA : in std_logic_vector (12 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (1 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (10 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (7 downto 0);
   DIPB : in std_logic_vector (0 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S2_S9 : component is true;
component RAMB16_S36
 port (
   DO : out std_logic_vector (31 downto 0);
   DOP : out std_logic_vector (3 downto 0);
   ADDR : in std_logic_vector (8 downto 0);
   DI : in std_logic_vector (31 downto 0);
   DIP : in std_logic_vector (3 downto 0);
   EN : in std_logic;
   CLK : in std_logic;
   WE : in std_logic;
   SSR : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S36 : component is true;
component RAMB16_S36_S36
 port (
   DOA : out std_logic_vector (31 downto 0);
   DOPA : out std_logic_vector (3 downto 0);
   DOB : out std_logic_vector (31 downto 0);
   DOPB : out std_logic_vector (3 downto 0);
   ADDRA : in std_logic_vector (8 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (31 downto 0);
   DIPA : in std_logic_vector (3 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (8 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (31 downto 0);
   DIPB : in std_logic_vector (3 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S36_S36 : component is true;
component RAMB16_S4
 port (
   DO : out std_logic_vector (3 downto 0);
   ADDR : in std_logic_vector (11 downto 0);
   DI : in std_logic_vector (3 downto 0);
   EN : in std_logic;
   CLK : in std_logic;
   WE : in std_logic;
   SSR : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S4 : component is true;
component RAMB16_S4_S18
 port (
   DOA : out std_logic_vector (3 downto 0);
   DOB : out std_logic_vector (15 downto 0);
   DOPB : out std_logic_vector (1 downto 0);
   ADDRA : in std_logic_vector (11 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (3 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (9 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (15 downto 0);
   DIPB : in std_logic_vector (1 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S4_S18 : component is true;
component RAMB16_S4_S36
 port (
   DOA : out std_logic_vector (3 downto 0);
   DOB : out std_logic_vector (31 downto 0);
   DOPB : out std_logic_vector (3 downto 0);
   ADDRA : in std_logic_vector (11 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (3 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (8 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (31 downto 0);
   DIPB : in std_logic_vector (3 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S4_S36 : component is true;
component RAMB16_S4_S4
 port (
   DOA : out std_logic_vector (3 downto 0);
   DOB : out std_logic_vector (3 downto 0);
   ADDRA : in std_logic_vector (11 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (3 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (11 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (3 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S4_S4 : component is true;
component RAMB16_S4_S9
 port (
   DOA : out std_logic_vector (3 downto 0);
   DOB : out std_logic_vector (7 downto 0);
   DOPB : out std_logic_vector (0 downto 0);
   ADDRA : in std_logic_vector (11 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (3 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (10 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (7 downto 0);
   DIPB : in std_logic_vector (0 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S4_S9 : component is true;
component RAMB16_S9
 port (
   DO : out std_logic_vector (7 downto 0);
   DOP : out std_logic_vector (0 downto 0);
   ADDR : in std_logic_vector (10 downto 0);
   DI : in std_logic_vector (7 downto 0);
   DIP : in std_logic_vector (0 downto 0);
   EN : in std_logic;
   CLK : in std_logic;
   WE : in std_logic;
   SSR : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S9 : component is true;
component RAMB16_S9_S18
 port (
   DOA : out std_logic_vector (7 downto 0);
   DOPA : out std_logic_vector (0 downto 0);
   DOB : out std_logic_vector (15 downto 0);
   DOPB : out std_logic_vector (1 downto 0);
   ADDRA : in std_logic_vector (10 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (7 downto 0);
   DIPA : in std_logic_vector (0 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (9 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (15 downto 0);
   DIPB : in std_logic_vector (1 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S9_S18 : component is true;
component RAMB16_S9_S36
 port (
   DOA : out std_logic_vector (7 downto 0);
   DOPA : out std_logic_vector (0 downto 0);
   DOB : out std_logic_vector (31 downto 0);
   DOPB : out std_logic_vector (3 downto 0);
   ADDRA : in std_logic_vector (10 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (7 downto 0);
   DIPA : in std_logic_vector (0 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (8 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (31 downto 0);
   DIPB : in std_logic_vector (3 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S9_S36 : component is true;
component RAMB16_S9_S9
 port (
   DOA : out std_logic_vector (7 downto 0);
   DOPA : out std_logic_vector (0 downto 0);
   DOB : out std_logic_vector (7 downto 0);
   DOPB : out std_logic_vector (0 downto 0);
   ADDRA : in std_logic_vector (10 downto 0);
   CLKA : in std_logic;
   DIA : in std_logic_vector (7 downto 0);
   DIPA : in std_logic_vector (0 downto 0);
   ENA : in std_logic;
   SSRA : in std_logic;
   WEA : in std_logic;
   ADDRB : in std_logic_vector (10 downto 0);
   CLKB : in std_logic;
   DIB : in std_logic_vector (7 downto 0);
   DIPB : in std_logic_vector (0 downto 0);
   ENB : in std_logic;
   SSRB : in std_logic;
   WEB : in std_logic
 );
end component;
attribute syn_black_box of RAMB16_S9_S9 : component is true;
component ROM16X1
 generic(INIT : bit_vector := X"0000");
 port (
   O : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic
 );
end component;
attribute syn_black_box of ROM16X1 : component is true;
component ROM32X1
 generic(INIT : bit_vector := X"00000000");
 port (
   O : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   A4 : in std_logic
 );
end component;
attribute syn_black_box of ROM32X1 : component is true;
component ROM128X1
 generic(INIT : bit_vector := X"00000000000000000000000000000000");
  port (A0 : in std_ulogic;
        A1 : in std_ulogic;
        A2 : in std_ulogic;
        A3 : in std_ulogic;
        A4 : in std_ulogic;
        A5 : in std_ulogic;
        A6 : in std_ulogic;
        O : out std_ulogic
       );
end component;
attribute syn_black_box of ROM128X1 : component is true;

component ROM256X1
 generic(INIT : bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000");
  port (A0 : in std_ulogic;
        A1 : in std_ulogic;
        A2 : in std_ulogic;
        A3 : in std_ulogic;
        A4 : in std_ulogic;
        A5 : in std_ulogic;
        A6 : in std_ulogic;
        A7 : in std_ulogic;
        O : out std_ulogic
       );
end component;
attribute syn_black_box of ROM256X1 : component is true;

component ROM64X1
 generic(INIT : bit_vector := X"0000000000000000");
  port (A0 : in std_ulogic;
        A1 : in std_ulogic;
        A2 : in std_ulogic;
        A3 : in std_ulogic;
        A4 : in std_ulogic;
        A5 : in std_ulogic;
        O : out std_ulogic
       );
end component;
attribute syn_black_box of ROM64X1 : component is true;
component SRL16
 port (
   Q : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   CLK : in std_logic;
   D : in std_logic
 );
end component;
attribute syn_black_box of SRL16 : component is true;
component SRL16E
 port (
   Q : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   CE : in std_logic;
   CLK : in std_logic;
   D : in std_logic
 );
end component;
attribute syn_black_box of SRL16E : component is true;
component SRL16E_1
 port (
   Q : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   CE : in std_logic;
   CLK : in std_logic;
   D : in std_logic
 );
end component;
attribute syn_black_box of SRL16E_1 : component is true;
component SRL16_1
 port (
   Q : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   CLK : in std_logic;
   D : in std_logic
 );
end component;
attribute syn_black_box of SRL16_1 : component is true;
component SRLC16
 port (
   Q : out std_logic;
   Q15 : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   CLK : in std_logic;
   D : in std_logic
 );
end component;
attribute syn_black_box of SRLC16 : component is true;
component SRLC16E
 port (
   Q : out std_logic;
   Q15 : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   CE : in std_logic;
   CLK : in std_logic;
   D : in std_logic
 );
end component;
attribute syn_black_box of SRLC16E : component is true;
component SRLC16E_1
 port (
   Q : out std_logic;
   Q15 : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   CE : in std_logic;
   CLK : in std_logic;
   D : in std_logic
 );
end component;
attribute syn_black_box of SRLC16E_1 : component is true;
component SRLC16_1
 port (
   Q : out std_logic;
   Q15 : out std_logic;
   A0 : in std_logic;
   A1 : in std_logic;
   A2 : in std_logic;
   A3 : in std_logic;
   CLK : in std_logic;
   D : in std_logic
 );
end component;
attribute syn_black_box of SRLC16_1 : component is true;
component STARTUP_VIRTEX2_CLK
 port (
   CLK : in std_logic
 );
end component;
attribute syn_black_box of STARTUP_VIRTEX2_CLK : component is true;
attribute syn_noprune of STARTUP_VIRTEX2_CLK : component is true;
attribute xc_alias of STARTUP_VIRTEX2_CLK : component is "STARTUP_VIRTEX2";
component STARTUP_VIRTEX2_GSR
 port (
   GSR : in std_logic
 );
end component;
attribute syn_black_box of STARTUP_VIRTEX2_GSR : component is true;
attribute syn_noprune of STARTUP_VIRTEX2_GSR : component is true;
attribute xc_alias of STARTUP_VIRTEX2_GSR : component is "STARTUP_VIRTEX2";
component STARTUP_VIRTEX2_GTS
 port (
   GTS : in std_logic
 );
end component;
attribute syn_black_box of STARTUP_VIRTEX2_GTS : component is true;
attribute syn_noprune of STARTUP_VIRTEX2_GTS : component is true;
attribute xc_alias of STARTUP_VIRTEX2_GTS : component is "STARTUP_VIRTEX2";
component STARTUP_VIRTEX2_ALL
 port (
   CLK,GSR,GTS : in std_logic := '0'
 );
end component;
attribute syn_black_box of STARTUP_VIRTEX2_ALL : component is true;
attribute syn_noprune of STARTUP_VIRTEX2_ALL : component is true;
attribute xc_alias of STARTUP_VIRTEX2_ALL : component is "STARTUP_VIRTEX2";
component STARTUP_VIRTEX2
 port (
   CLK : in std_logic;
   GSR : in std_logic;
   GTS : in std_logic
 );
end component;
component VCC
 port (
   P : out std_logic
 );
end component;
attribute syn_black_box of VCC : component is true;
attribute syn_noprune of VCC : component is true;
component XORCY
 port (
   O : out std_logic;
   CI : in std_logic;
   LI : in std_logic
 );
end component;
attribute syn_black_box of XORCY : component is true;
component XORCY_D
 port (
   O : out std_logic;
   LO : out std_logic;
   CI : in std_logic;
   LI : in std_logic
 );
end component;
attribute syn_black_box of XORCY_D : component is true;
component XORCY_L
 port (
   LO : out std_logic;
   CI : in std_logic;
   LI : in std_logic
 );
end component;
attribute syn_black_box of XORCY_L : component is true;

component GT_SWIFT
    port (
	   TX_CRC_FORCE_VALUE : in std_logic_vector(7 downto 0);
           RXLOSSOFSYNC : out std_logic_vector(1 downto 0);
           RXCLKCORCNT : out std_logic_vector(2 downto 0);
		   BREFCLK : in std_logic;
		   BREFCLK2 : in std_logic;
           RXP : in std_logic;
           RXN : in std_logic;
           GSR : in std_logic;
           TXP : out std_logic;
           TXN : out std_logic;
	   CONFIGENABLE   : in std_logic;
           CONFIGIN       : in std_logic;
           CONFIGOUT      : out std_logic;
           CRC_END_OF_PKT  : in std_logic_vector(7 downto 0);
           CRC_FORMAT      : in std_logic_vector(1 downto 0);
           CRC_START_OF_PKT : in std_logic_vector(7 downto 0);
           CHAN_BOND_LIMIT  : in std_logic_vector(4 downto 0);
           REFCLK : in std_logic;
           REFCLK2 : in std_logic;   
           REFCLKSEL : in std_logic;
           RXUSRCLK : in std_logic;
           TXUSRCLK : in std_logic;
           RXUSRCLK2 : in std_logic;
           TXUSRCLK2 : in std_logic;
           RXRESET : in std_logic;
           TXRESET : in std_logic;
           POWERDOWN : in std_logic;
           LOOPBACK : in std_logic_vector(1 downto 0);
           TXDATA : in std_logic_vector(31 downto 0);
           RX_LOSS_OF_SYNC_FSM : in std_logic;
           RX_LOS_INVALID_INCR : in std_logic_vector(2 downto 0);
           RX_LOS_THRESHOLD : in std_logic_vector(2 downto 0);
           TXCHARDISPMODE : in std_logic_vector(3 downto 0);
           TXCHARDISPVAL : in std_logic_vector(3 downto 0);
           TXCHARISK : in std_logic_vector(3 downto 0);
           TXBYPASS8B10B : in std_logic_vector(3 downto 0);
           TXPOLARITY : in std_logic;
           TXINHIBIT  : in std_logic;
           ENCHANSYNC : in std_logic;
           RXPOLARITY : in std_logic;
           CHBONDI : in std_logic_vector(3 downto 0);
           RXRECCLK : out std_logic;
           TXBUFERR : out std_logic;
           TXFORCECRCERR : in std_logic;
           TXRUNDISP : out std_logic_vector(3 downto 0);
           TXKERR : out std_logic_vector(3 downto 0);
           RXREALIGN : out std_logic;
           RXCOMMADET : out std_logic;
	   RXCHECKINGCRC : out std_logic;
           RXCRCERR : out std_logic;
           RXDATA : out std_logic_vector(31 downto 0);
           RXCHARISCOMMA : out std_logic_vector(3 downto 0);
           RXCHARISK : out std_logic_vector(3 downto 0);
           RXNOTINTABLE : out std_logic_vector(3 downto 0);
           RXDISPERR : out std_logic_vector(3 downto 0);
           RXRUNDISP : out std_logic_vector(3 downto 0);
           RXBUFSTATUS : out std_logic_vector(1 downto 0);
           CHBONDO : out std_logic_vector(3 downto 0);
           CHBONDDONE : out std_logic;
	   TX_PREEMPHASIS : in std_logic_vector(1 downto 0);
	   TX_DIFF_CTRL : in std_logic_vector(2 downto 0);
	   RX_TERM_IMP : in std_logic;
           SERDES_10B : in std_logic;
           ALIGN_COMMA_MSB : in std_logic;
           PCOMMA_DETECT : in std_logic;
           PCOMMA_ALIGN : in std_logic;
           MCOMMA_DETECT : in std_logic;
           MCOMMA_ALIGN : in std_logic;
           PCOMMA_10B_VALUE : in std_logic_vector(0 to 9);
           MCOMMA_10B_VALUE : in std_logic_vector(0 to 9);
           COMMA_10B_MASK : in std_logic_vector(0 to 9);
           DEC_PCOMMA_DETECT : in std_logic;
           DEC_MCOMMA_DETECT : in std_logic;
           DEC_VALID_COMMA_ONLY : in std_logic;
           RX_DECODE_USE : in std_logic;
           RX_BUFFER_USE : in std_logic;
           TX_BUFFER_USE : in std_logic;
           CLK_CORRECT_USE : in std_logic;
           CLK_COR_SEQ_LEN : in std_logic_vector(1 downto 0);
           CLK_COR_INSERT_IDLE_FLAG : in std_logic;
           CLK_COR_KEEP_IDLE : in std_logic;
           CLK_COR_REPEAT_WAIT : in std_logic_vector(4 downto 0);
           CLK_COR_SEQ_1_1 : in std_logic_vector(10 downto 0);
           CLK_COR_SEQ_1_2 : in std_logic_vector(10 downto 0);
           CLK_COR_SEQ_1_3 : in std_logic_vector(10 downto 0);
           CLK_COR_SEQ_1_4 : in std_logic_vector(10 downto 0);
           CLK_COR_SEQ_2_USE : in std_logic;
           CLK_COR_SEQ_2_1 : in std_logic_vector(10 downto 0);
           CLK_COR_SEQ_2_2 : in std_logic_vector(10 downto 0);
           CLK_COR_SEQ_2_3 : in std_logic_vector(10 downto 0);
           CLK_COR_SEQ_2_4 : in std_logic_vector(10 downto 0);
           CHAN_BOND_MODE : in std_logic_vector(1 downto 0);
           CHAN_BOND_SEQ_LEN : in std_logic_vector(1 downto 0);
           CHAN_BOND_SEQ_1_1 : in std_logic_vector(10 downto 0);
           CHAN_BOND_SEQ_1_2 : in std_logic_vector(10 downto 0);
           CHAN_BOND_SEQ_1_3 : in std_logic_vector(10 downto 0);
           CHAN_BOND_SEQ_1_4 : in std_logic_vector(10 downto 0);
           CHAN_BOND_SEQ_2_USE : in std_logic;
           CHAN_BOND_SEQ_2_1 : in std_logic_vector(10 downto 0);
           CHAN_BOND_SEQ_2_2 : in std_logic_vector(10 downto 0);
           CHAN_BOND_SEQ_2_3 : in std_logic_vector(10 downto 0);
           CHAN_BOND_SEQ_2_4 : in std_logic_vector(10 downto 0);
           CHAN_BOND_WAIT : in std_logic_vector(3 downto 0);
           CHAN_BOND_OFFSET : in std_logic_vector(3 downto 0);
           TX_CRC_USE : in std_logic;
           RX_CRC_USE : in std_logic;
           CHAN_BOND_ONE_SHOT : in std_logic;
           RX_DATA_WIDTH : in std_logic_vector(1 downto 0);
           TX_DATA_WIDTH : in std_logic_vector(1 downto 0)
      
           );
 
end component;
attribute syn_black_box of GT_SWIFT : component is true;

component GT 
	port (
                CHBONDDONE : out  std_ulogic;
                CHBONDO    : out  std_logic_vector ( 3 downto 0 );
		CONFIGOUT  : out  std_ulogic;
		RXBUFSTATUS: out  std_logic_vector (1 downto 0);
		RXCHARISCOMMA : out  std_logic_vector ( 3 downto 0);
		RXCHARISK : out  std_logic_vector ( 3 downto 0 );
		RXCHECKINGCRC : out std_ulogic;
                RXCLKCORCNT : out std_logic_vector(2 downto 0);
		RXCOMMADET : out  std_ulogic ;                
                RXCRCERR : out std_ulogic;                
		RXDATA : out  std_logic_vector ( 31 downto 0);
		RXDISPERR : out std_logic_vector ( 3 downto 0) ;
                RXLOSSOFSYNC : out std_logic_vector(1 downto 0);
		RXNOTINTABLE : out  std_logic_vector ( 3 downto 0 );
		RXREALIGN : out std_ulogic;
		RXRECCLK : out std_ulogic ;
		RXRUNDISP : out std_logic_vector ( 3 downto 0 );
		TXBUFERR : out std_ulogic;
		TXKERR : out std_logic_vector ( 3 downto 0 );
		TXN : out std_ulogic;
		TXP : out std_ulogic ;
		TXRUNDISP : out std_logic_vector ( 3 downto 0 );
		BREFCLK : in std_logic;
		BREFCLK2 : in std_logic;
		CHBONDI : in std_logic_vector ( 3 downto 0 );
		CONFIGENABLE : in std_ulogic;
		CONFIGIN : in std_ulogic ;
		ENCHANSYNC : in std_ulogic ;
		ENMCOMMAALIGN : in std_ulogic ;
            ENPCOMMAALIGN : in std_ulogic ;  
		LOOPBACK : in std_logic_vector ( 1 downto 0 );
		POWERDOWN : in std_ulogic;
		REFCLK : in std_ulogic ;
                REFCLK2 : in std_ulogic;   
                REFCLKSEL : in std_ulogic;                
		RXN : in std_ulogic ;
		RXP : in std_ulogic ;
		RXPOLARITY : in std_ulogic;
		RXRESET : in std_ulogic;
		RXUSRCLK : in std_ulogic;
		RXUSRCLK2 : in std_ulogic;
		TXBYPASS8B10B : in std_logic_vector ( 3 downto 0 );
		TXCHARDISPMODE : in std_logic_vector ( 3 downto 0 );
		TXCHARDISPVAL : in std_logic_vector ( 3 downto 0 );
		TXCHARISK : in std_logic_vector ( 3 downto 0 );
		TXDATA : in std_logic_vector ( 31 downto 0 );
		TXFORCECRCERR : in std_ulogic;
		TXINHIBIT : in std_ulogic;
		TXPOLARITY : in std_ulogic;
		TXRESET : in std_ulogic;
		TXUSRCLK : in std_ulogic;
		TXUSRCLK2: in std_ulogic 

	);
end  Component;
attribute syn_black_box of GT : component is true;
 
component GT_AURORA_1
	port (
                CHBONDDONE : out  std_ulogic ;
                CHBONDO    : out  std_logic_vector ( 3 downto 0 );
		CONFIGOUT  : out  std_ulogic ;
		RXBUFSTATUS: out  std_logic_vector (1 downto 0);
		RXCHARISCOMMA : out  std_logic_vector ( 0 downto 0);
		RXCHARISK : out  std_logic_vector ( 0 downto 0 );
		RXCHECKINGCRC : out std_ulogic;
                RXCLKCORCNT : out std_logic_vector(2 downto 0); 
		RXCOMMADET : out  std_ulogic ;
           	RXCRCERR : out std_ulogic;                
		RXDATA : out  std_logic_vector ( 7 downto 0);
		RXDISPERR : out std_logic_vector ( 0 downto 0) ;
                RXLOSSOFSYNC : out std_logic_vector(1 downto 0);
		RXNOTINTABLE : out  std_logic_vector ( 0 downto 0 );
		RXREALIGN : out std_ulogic;
		RXRECCLK : out std_ulogic ;
		RXRUNDISP : out std_logic_vector ( 0 downto 0 );
		TXBUFERR : out std_ulogic;
		TXKERR : out std_logic_vector ( 0 downto 0 );
		TXN : out std_ulogic ;
		TXP : out std_ulogic;
		TXRUNDISP : out std_logic_vector ( 0 downto 0 );
		BREFCLK : in std_logic;
		BREFCLK2 : in std_logic;
		CHBONDI : in std_logic_vector ( 3 downto 0 );
		CONFIGENABLE : in std_ulogic;
		CONFIGIN : in std_ulogic ;
		ENCHANSYNC : in std_ulogic ;
		ENMCOMMAALIGN : in std_ulogic ;
            ENPCOMMAALIGN : in std_ulogic ;  
		LOOPBACK : in std_logic_vector ( 1 downto 0 );
		POWERDOWN : in std_ulogic;
		REFCLK : in std_ulogic ;
                REFCLK2 : in std_ulogic;   
                REFCLKSEL : in std_ulogic;                
		RXN : in std_ulogic ;
		RXP : in std_ulogic ;
		RXPOLARITY : in std_ulogic;
		RXRESET : in std_ulogic;
		RXUSRCLK : in std_ulogic;
		RXUSRCLK2 : in std_ulogic;
		TXBYPASS8B10B : in std_logic_vector ( 0 downto 0 );
		TXCHARDISPMODE : in std_logic_vector ( 0 downto 0 );
		TXCHARDISPVAL : in std_logic_vector ( 0 downto 0 );
		TXCHARISK : in std_logic_vector ( 0 downto 0 );
		TXDATA : in std_logic_vector ( 7 downto 0 );
		TXFORCECRCERR : in std_ulogic;
		TXINHIBIT : in std_ulogic ;
		TXPOLARITY : in std_ulogic;
		TXRESET : in std_ulogic;
		TXUSRCLK : in std_ulogic;
		TXUSRCLK2: in std_ulogic 

	);
end component;
attribute syn_black_box of GT_AURORA_1 : component is true;

component GT_AURORA_2
	port (
                CHBONDDONE : out  std_ulogic ;          
		CHBONDO    : out  std_logic_vector ( 3 downto 0 );
		CONFIGOUT  : out  std_ulogic ;
		RXBUFSTATUS: out  std_logic_vector (1 downto 0);
		RXCHARISCOMMA : out  std_logic_vector ( 1 downto 0);
		RXCHARISK : out  std_logic_vector ( 1 downto 0 );
		RXCHECKINGCRC : out std_ulogic;
                RXCLKCORCNT : out std_logic_vector(2 downto 0);                 
		RXCOMMADET : out  std_ulogic ;
           	RXCRCERR : out std_ulogic;                
		RXDATA : out  std_logic_vector ( 15 downto 0);
		RXDISPERR : out std_logic_vector ( 1 downto 0) ;
                RXLOSSOFSYNC : out std_logic_vector(1 downto 0);                
		RXNOTINTABLE : out  std_logic_vector ( 1 downto 0 );
		RXREALIGN : out std_ulogic;
		RXRECCLK : out std_ulogic ;
		RXRUNDISP : out std_logic_vector ( 1 downto 0 );
		TXBUFERR : out std_ulogic;
		TXKERR : out std_logic_vector ( 1 downto 0 );
		TXN : out std_ulogic ;
		TXP : out std_ulogic;
		TXRUNDISP : out std_logic_vector ( 1 downto 0 );
		BREFCLK : in std_logic;
		BREFCLK2 : in std_logic;
		CHBONDI : in std_logic_vector ( 3 downto 0 );
		CONFIGENABLE : in std_ulogic;
		CONFIGIN : in std_ulogic ;
		ENCHANSYNC : in std_ulogic ;
		ENMCOMMAALIGN : in std_ulogic ;
            ENPCOMMAALIGN : in std_ulogic ;  
		LOOPBACK : in std_logic_vector ( 1 downto 0 );
		POWERDOWN : in std_ulogic;
		REFCLK : in std_ulogic ;
                REFCLK2 : in std_ulogic;   
                REFCLKSEL : in std_ulogic;                
		RXN : in std_ulogic ;
		RXP : in std_ulogic ;
		RXPOLARITY : in std_ulogic;
		RXRESET : in std_ulogic;
		RXUSRCLK : in std_ulogic;
		RXUSRCLK2 : in std_ulogic;
		TXBYPASS8B10B : in std_logic_vector ( 1 downto 0 );
		TXCHARDISPMODE : in std_logic_vector ( 1 downto 0 );
		TXCHARDISPVAL : in std_logic_vector ( 1 downto 0 );
		TXCHARISK : in std_logic_vector ( 1 downto 0 );
		TXDATA : in std_logic_vector ( 15 downto 0 );
		TXFORCECRCERR : in std_ulogic;
		TXINHIBIT : in std_ulogic ;
		TXPOLARITY : in std_ulogic;
		TXRESET : in std_ulogic;
		TXUSRCLK : in std_ulogic;
		TXUSRCLK2: in std_ulogic 

	);
end component;
attribute syn_black_box of GT_AURORA_2 : component is true;

component GT_AURORA_4
	port (
                CHBONDDONE : out  std_ulogic ;
                CHBONDO    : out  std_logic_vector ( 3 downto 0 );
		CONFIGOUT  : out  std_ulogic ;
		RXBUFSTATUS: out  std_logic_vector (1 downto 0);
		RXCHARISCOMMA : out  std_logic_vector ( 3 downto 0);
		RXCHARISK : out  std_logic_vector ( 3 downto 0 );
		RXCHECKINGCRC : out std_ulogic;
                RXCLKCORCNT : out std_logic_vector(2 downto 0);                 
		RXCOMMADET : out  std_ulogic ;
                RXCRCERR : out std_ulogic;                
		RXDATA : out  std_logic_vector ( 31 downto 0);
		RXDISPERR : out std_logic_vector ( 3 downto 0) ;
                RXLOSSOFSYNC : out std_logic_vector(1 downto 0);                
		RXNOTINTABLE : out  std_logic_vector ( 3 downto 0 );
		RXREALIGN : out std_ulogic;
		RXRECCLK : out std_ulogic ;
		RXRUNDISP : out std_logic_vector ( 3 downto 0 );
		TXBUFERR : out std_ulogic;
		TXKERR : out std_logic_vector ( 3 downto 0 );
		TXN : out std_ulogic ;
		TXP : out std_ulogic;
		TXRUNDISP : out std_logic_vector ( 3 downto 0 );
		BREFCLK : in std_logic;
		BREFCLK2 : in std_logic;
		CHBONDI : in std_logic_vector ( 3 downto 0 );
		CONFIGENABLE : in std_ulogic;
		CONFIGIN : in std_ulogic ;
		ENCHANSYNC : in std_ulogic ;
		ENMCOMMAALIGN : in std_ulogic ;
            ENPCOMMAALIGN : in std_ulogic ;  
		LOOPBACK : in std_logic_vector ( 1 downto 0 );
		POWERDOWN : in std_ulogic;
		REFCLK : in std_ulogic ;
                REFCLK2 : in std_ulogic;   
                REFCLKSEL : in std_ulogic;                
		RXN : in std_ulogic ;
		RXP : in std_ulogic ;
		RXPOLARITY : in std_ulogic;
		RXRESET : in std_ulogic;
		RXUSRCLK : in std_ulogic;
		RXUSRCLK2 : in std_ulogic;
		TXBYPASS8B10B : in std_logic_vector ( 3 downto 0 );
		TXCHARDISPMODE : in std_logic_vector ( 3 downto 0 );
		TXCHARDISPVAL : in std_logic_vector ( 3 downto 0 );
		TXCHARISK : in std_logic_vector ( 3 downto 0 );
		TXDATA : in std_logic_vector ( 31 downto 0 );
		TXFORCECRCERR : in std_ulogic;
		TXINHIBIT : in std_ulogic ;
		TXPOLARITY : in std_ulogic;
		TXRESET : in std_ulogic;
		TXUSRCLK : in std_ulogic;
		TXUSRCLK2: in std_ulogic 

	);
end component;
attribute syn_black_box of GT_AURORA_4 : component is true;

component GT_CUSTOM
	port (
        CHBONDDONE : out std_ulogic;
        CHBONDO : out std_logic_vector(3 DOWNTO 0);
        CONFIGOUT : out std_ulogic;
        RXBUFSTATUS : out std_logic_vector(1 DOWNTO 0);
        RXCHARISCOMMA : out std_logic_vector(3 DOWNTO 0);
        RXCHARISK : out std_logic_vector(3 DOWNTO 0);
        RXCHECKINGCRC : out std_ulogic;
        RXCLKCORCNT : out std_logic_vector(2 DOWNTO 0);
        RXCOMMADET : out std_ulogic;
        RXCRCERR : out std_ulogic;
        RXDATA : out std_logic_vector(31 DOWNTO 0);
        RXDISPERR : out std_logic_vector(3 DOWNTO 0);
        RXLOSSOFSYNC : out std_logic_vector(1 DOWNTO 0);
        RXNOTINTABLE : out std_logic_vector(3 DOWNTO 0);
        RXREALIGN : out std_ulogic;
        RXRECCLK : out std_ulogic;
        RXRUNDISP : out std_logic_vector(3 DOWNTO 0);
        TXBUFERR : out std_ulogic;
        TXKERR : out std_logic_vector(3 DOWNTO 0);
        TXN : out std_ulogic;
        TXP : out std_ulogic;
        TXRUNDISP : out std_logic_vector(3 DOWNTO 0);
        BREFCLK : in std_logic;
		BREFCLK2 : in std_logic;	
        CHBONDI : in std_logic_vector(3 DOWNTO 0);
        CONFIGENABLE : in std_ulogic;
        CONFIGIN : in std_ulogic;
        ENCHANSYNC : in std_ulogic;
	  ENMCOMMAALIGN : in std_ulogic ;
        ENPCOMMAALIGN : in std_ulogic ;  	
        LOOPBACK : in std_logic_vector(1 DOWNTO 0);
        POWERDOWN : in std_ulogic;
        REFCLK : in std_ulogic;
        REFCLK2 : in std_ulogic;
        REFCLKSEL : in std_ulogic;
        RXN : in std_ulogic;
        RXP : in std_ulogic;
        RXPOLARITY : in std_ulogic;
        RXRESET : in std_ulogic;
        RXUSRCLK : in std_ulogic;
        RXUSRCLK2 : in std_ulogic;
        TXBYPASS8B10B : in std_logic_vector(3 DOWNTO 0);
        TXCHARDISPMODE : in std_logic_vector(3 DOWNTO 0);
        TXCHARDISPVAL : in std_logic_vector(3 DOWNTO 0);
        TXCHARISK : in std_logic_vector(3 DOWNTO 0);
        TXDATA : in std_logic_vector(31 DOWNTO 0);
        TXFORCECRCERR : in std_ulogic;
        TXINHIBIT : in std_ulogic;
        TXPOLARITY : in std_ulogic;
        TXRESET : in std_ulogic;
        TXUSRCLK : in std_ulogic;
        TXUSRCLK2 : in std_logic
        ) ;
end component;
attribute syn_black_box of GT_CUSTOM : component is true;

component GT_ETHERNET_4
	port (
                CONFIGOUT  : out  std_ulogic ;
                RXBUFSTATUS: out  std_logic_vector (1 downto 0);
		RXCHARISCOMMA : out  std_logic_vector ( 3 downto 0);
		RXCHARISK : out  std_logic_vector ( 3 downto 0 );
		RXCHECKINGCRC : out std_ulogic;
                RXCLKCORCNT : out std_logic_vector(2 downto 0);                 
		RXCOMMADET : out  std_ulogic ;
           	RXCRCERR : out std_ulogic;                
		RXDATA : out  std_logic_vector ( 31 downto 0);
		RXDISPERR : out std_logic_vector ( 3 downto 0) ;
                RXLOSSOFSYNC : out std_logic_vector(1 downto 0);                
		RXNOTINTABLE : out  std_logic_vector ( 3 downto 0 );
		RXREALIGN : out std_ulogic;
		RXRECCLK : out std_ulogic ;
		RXRUNDISP : out std_logic_vector ( 3 downto 0 );
		TXBUFERR : out std_ulogic;
		TXKERR : out std_logic_vector ( 3 downto 0 );
		TXN : out std_ulogic ;
		TXP : out std_ulogic;
		TXRUNDISP : out std_logic_vector ( 3 downto 0 );
		BREFCLK : in std_logic;
		BREFCLK2 : in std_logic;
		CONFIGENABLE : in std_ulogic;
		CONFIGIN : in std_ulogic ;
		ENMCOMMAALIGN : in std_ulogic ;
            ENPCOMMAALIGN : in std_ulogic ;  
		LOOPBACK : in std_logic_vector ( 1 downto 0 );
		POWERDOWN : in std_ulogic;
		REFCLK : in std_ulogic ;
                REFCLK2 : in std_ulogic;   
                REFCLKSEL : in std_ulogic;                
		RXN : in std_ulogic ;
		RXP : in std_ulogic ;
		RXPOLARITY : in std_ulogic;
		RXRESET : in std_ulogic;
		RXUSRCLK : in std_ulogic;
		RXUSRCLK2 : in std_ulogic;
		TXBYPASS8B10B : in std_logic_vector ( 3 downto 0 );
		TXCHARDISPMODE : in std_logic_vector ( 3 downto 0 );
		TXCHARDISPVAL : in std_logic_vector ( 3 downto 0 );
		TXCHARISK : in std_logic_vector ( 3 downto 0 );
		TXDATA : in std_logic_vector ( 31 downto 0 );
		TXFORCECRCERR : in std_ulogic;
		TXINHIBIT : in std_ulogic ;
		TXPOLARITY : in std_ulogic;
		TXRESET : in std_ulogic;
		TXUSRCLK : in std_ulogic;
		TXUSRCLK2: in std_ulogic 

	);
end component;
attribute syn_black_box of GT_ETHERNET_4 : component is true;

component GT_ETHERNET_1
	port (
                CONFIGOUT  : out  std_ulogic ;
                RXBUFSTATUS: out  std_logic_vector (1 downto 0);
		RXCHARISCOMMA : out  std_logic_vector ( 0 downto 0);
		RXCHARISK : out  std_logic_vector ( 0 downto 0 );
		RXCHECKINGCRC : out std_ulogic;
                RXCLKCORCNT : out std_logic_vector(2 downto 0);                 
		RXCOMMADET : out  std_ulogic ;
           	RXCRCERR : out std_ulogic;
                RXLOSSOFSYNC : out std_logic_vector(1 downto 0);                
		RXDATA : out  std_logic_vector ( 7 downto 0);
		RXDISPERR : out std_logic_vector ( 0 downto 0) ;
		RXNOTINTABLE : out  std_logic_vector ( 0 downto 0 );
		RXREALIGN : out std_ulogic;
		RXRECCLK : out std_ulogic ;
		RXRUNDISP : out std_logic_vector ( 0 downto 0 );
		TXBUFERR : out std_ulogic;
		TXKERR : out std_logic_vector ( 0 downto 0 );
		TXN : out std_ulogic ;
		TXP : out std_ulogic;
		TXRUNDISP : out std_logic_vector ( 0 downto 0 );
		BREFCLK : in std_logic;
		BREFCLK2 : in std_logic;
		CONFIGENABLE : in std_ulogic;
		CONFIGIN : in std_ulogic ;
		ENMCOMMAALIGN : in std_ulogic ;
            ENPCOMMAALIGN : in std_ulogic ;  
		LOOPBACK : in std_logic_vector ( 1 downto 0 );
		POWERDOWN : in std_ulogic;
		REFCLK : in std_ulogic ;
                REFCLK2 : in std_ulogic;   
                REFCLKSEL : in std_ulogic;                
		RXN : in std_ulogic ;
		RXP : in std_ulogic ;
		RXPOLARITY : in std_ulogic;
		RXRESET : in std_ulogic;
		RXUSRCLK : in std_ulogic;
		RXUSRCLK2 : in std_ulogic;
		TXBYPASS8B10B : in std_logic_vector ( 0 downto 0 );
		TXCHARDISPMODE : in std_logic_vector ( 0 downto 0 );
		TXCHARDISPVAL : in std_logic_vector ( 0 downto 0 );
		TXCHARISK : in std_logic_vector ( 0 downto 0 );
		TXDATA : in std_logic_vector ( 7 downto 0 );
		TXFORCECRCERR : in std_ulogic;
		TXINHIBIT : in std_ulogic ;
		TXPOLARITY : in std_ulogic;
		TXRESET : in std_ulogic;
		TXUSRCLK : in std_ulogic;
		TXUSRCLK2 : in std_ulogic

	);
end component;
attribute syn_black_box of GT_ETHERNET_1 : component is true;

component GT_ETHERNET_2
	port (
                CONFIGOUT  : out  std_ulogic ;          
		RXBUFSTATUS: out  std_logic_vector (1 downto 0);
		RXCHARISCOMMA : out  std_logic_vector ( 1 downto 0);
		RXCHARISK : out  std_logic_vector ( 1 downto 0 );
		RXCHECKINGCRC : out std_ulogic;
                RXCLKCORCNT : out std_logic_vector(2 downto 0);                 
		RXCOMMADET : out  std_ulogic ;
           	RXCRCERR : out std_ulogic;                
		RXDATA : out  std_logic_vector ( 15 downto 0);
		RXDISPERR : out std_logic_vector ( 1 downto 0) ;
                RXLOSSOFSYNC : out std_logic_vector(1 downto 0);                
		RXNOTINTABLE : out  std_logic_vector ( 1 downto 0 );
		RXREALIGN : out std_ulogic;
		RXRECCLK : out std_ulogic ;
		RXRUNDISP : out std_logic_vector ( 1 downto 0 );
		TXBUFERR : out std_ulogic;
		TXKERR : out std_logic_vector ( 1 downto 0 );
		TXN : out std_ulogic ;
		TXP : out std_ulogic;
		TXRUNDISP : out std_logic_vector ( 1 downto 0 );
		BREFCLK : in std_logic;
		BREFCLK2 : in std_logic;
		CONFIGENABLE : in std_ulogic;
		CONFIGIN : in std_ulogic ;
		ENMCOMMAALIGN : in std_ulogic ;
            ENPCOMMAALIGN : in std_ulogic ;  
		LOOPBACK : in std_logic_vector ( 1 downto 0 );
		POWERDOWN : in std_ulogic;
		REFCLK : in std_ulogic ;
                REFCLK2 : in std_ulogic;   
                REFCLKSEL : in std_ulogic;                
		RXN : in std_ulogic ;
		RXP : in std_ulogic ;
		RXPOLARITY : in std_ulogic;
		RXRESET : in std_ulogic;
		RXUSRCLK : in std_ulogic;
		RXUSRCLK2 : in std_ulogic;
		TXBYPASS8B10B : in std_logic_vector ( 1 downto 0 );
		TXCHARDISPMODE : in std_logic_vector ( 1 downto 0 );
		TXCHARDISPVAL : in std_logic_vector ( 1 downto 0 );
		TXCHARISK : in std_logic_vector ( 1 downto 0 );
		TXDATA : in std_logic_vector ( 15 downto 0 );
		TXFORCECRCERR : in std_ulogic;
		TXINHIBIT : in std_ulogic ;
		TXPOLARITY : in std_ulogic;
		TXRESET : in std_ulogic;
		TXUSRCLK : in std_ulogic;
		TXUSRCLK2 : in std_ulogic

	);
end component;
attribute syn_black_box of GT_ETHERNET_2 : component is true;

component GT_FIBRE_CHAN_1
	port (
                CONFIGOUT  : out  std_ulogic ;
                RXBUFSTATUS: out  std_logic_vector (1 downto 0);
		RXCHARISCOMMA : out  std_logic_vector ( 0 downto 0);
		RXCHARISK : out  std_logic_vector ( 0 downto 0 );
		RXCHECKINGCRC : out std_ulogic;
                RXCLKCORCNT : out std_logic_vector(2 downto 0);                 
		RXCOMMADET : out  std_ulogic ;
           	RXCRCERR : out std_ulogic;                
		RXDATA : out  std_logic_vector ( 7 downto 0);
		RXDISPERR : out std_logic_vector ( 0 downto 0) ;
                RXLOSSOFSYNC : out std_logic_vector(1 downto 0);                
		RXNOTINTABLE : out  std_logic_vector ( 0 downto 0 );
		RXREALIGN : out std_ulogic;
		RXRECCLK : out std_ulogic ;
		RXRUNDISP : out std_logic_vector ( 0 downto 0 );
		TXBUFERR : out std_ulogic;
		TXKERR : out std_logic_vector ( 0 downto 0 );
		TXN : out std_ulogic ;
		TXP : out std_ulogic;
		TXRUNDISP : out std_logic_vector ( 0 downto 0 );
		BREFCLK : in std_logic;
		BREFCLK2 : in std_logic;
		CONFIGENABLE : in std_ulogic;
		CONFIGIN : in std_ulogic ;
		ENMCOMMAALIGN : in std_ulogic ;
            ENPCOMMAALIGN : in std_ulogic ;  
		LOOPBACK : in std_logic_vector ( 1 downto 0 );
		POWERDOWN : in std_ulogic;
		REFCLK : in std_ulogic ;
                REFCLK2 : in std_ulogic;   
                REFCLKSEL : in std_ulogic;
		RXN : in std_ulogic ;
		RXP : in std_ulogic ;
		RXPOLARITY : in std_ulogic;
		RXRESET : in std_ulogic;
		RXUSRCLK : in std_ulogic;
		RXUSRCLK2 : in std_ulogic;
		TXFORCECRCERR : in std_ulogic;
		TXBYPASS8B10B : in std_logic_vector ( 0 downto 0 );
		TXCHARDISPMODE : in std_logic_vector ( 0 downto 0 );
		TXCHARDISPVAL : in std_logic_vector ( 0 downto 0 );
		TXCHARISK : in std_logic_vector ( 0 downto 0 );
		TXDATA : in std_logic_vector ( 7 downto 0 );
		TXINHIBIT : in std_ulogic ;
		TXPOLARITY : in std_ulogic;
		TXRESET : in std_ulogic;
		TXUSRCLK : in std_ulogic;
		TXUSRCLK2: in std_ulogic 
	);
end component;
attribute syn_black_box of GT_FIBRE_CHAN_1 : component is true;

component GT_FIBRE_CHAN_2
	port (
                CONFIGOUT  : out  std_ulogic ;          
		RXBUFSTATUS: out  std_logic_vector (1 downto 0);
		RXCHARISCOMMA : out  std_logic_vector ( 1 downto 0);
		RXCHARISK : out  std_logic_vector ( 1 downto 0 );
		RXCHECKINGCRC : out std_ulogic;
                RXCLKCORCNT : out std_logic_vector(2 downto 0);                 
		RXCOMMADET : out  std_ulogic ;
           	RXCRCERR : out std_ulogic;                
		RXDATA : out  std_logic_vector ( 15 downto 0);
		RXDISPERR : out std_logic_vector ( 1 downto 0) ;
                RXLOSSOFSYNC : out std_logic_vector(1 downto 0);                
		RXNOTINTABLE : out  std_logic_vector ( 1 downto 0 );
		RXREALIGN : out std_ulogic;
		RXRECCLK : out std_ulogic ;
		RXRUNDISP : out std_logic_vector ( 1 downto 0 );
		TXBUFERR : out std_ulogic;
		TXKERR : out std_logic_vector ( 1 downto 0 );
		TXN : out std_ulogic ;
		TXP : out std_ulogic;
		TXRUNDISP : out std_logic_vector ( 1 downto 0 );
		BREFCLK : in std_logic;
		BREFCLK2 : in std_logic;
		CONFIGENABLE : in std_ulogic;
		CONFIGIN : in std_ulogic ;
		ENMCOMMAALIGN : in std_ulogic ;
            ENPCOMMAALIGN : in std_ulogic ;  
		LOOPBACK : in std_logic_vector ( 1 downto 0 );
		POWERDOWN : in std_ulogic;
		REFCLK : in std_ulogic ;
                REFCLK2 : in std_ulogic;   
                REFCLKSEL : in std_ulogic;                
		RXN : in std_ulogic ;
		RXP : in std_ulogic ;
		RXPOLARITY : in std_ulogic;
		RXRESET : in std_ulogic;
		RXUSRCLK : in std_ulogic;
		RXUSRCLK2 : in std_ulogic;
		TXBYPASS8B10B : in std_logic_vector ( 1 downto 0 );
		TXCHARDISPMODE : in std_logic_vector ( 1 downto 0 );
		TXCHARDISPVAL : in std_logic_vector ( 1 downto 0 );
		TXCHARISK : in std_logic_vector ( 1 downto 0 );

		TXDATA : in std_logic_vector ( 15 downto 0 );
		TXFORCECRCERR : in std_ulogic;
		TXINHIBIT : in std_ulogic ;
		TXPOLARITY : in std_ulogic;
		TXRESET : in std_ulogic;
		TXUSRCLK : in std_ulogic;
		TXUSRCLK2: in std_ulogic 

	);
end component;
attribute syn_black_box of GT_FIBRE_CHAN_2 : component is true;

component GT_FIBRE_CHAN_4
	port (
                CONFIGOUT  : out  std_ulogic ;          
		RXBUFSTATUS: out  std_logic_vector (1 downto 0);
		RXCHARISCOMMA : out  std_logic_vector ( 3 downto 0);
		RXCHARISK : out  std_logic_vector ( 3 downto 0 );
		RXCHECKINGCRC : out std_ulogic;
                RXCLKCORCNT : out std_logic_vector(2 downto 0);                 
		RXCOMMADET : out  std_ulogic ;
           	RXCRCERR : out std_ulogic;                
		RXDATA : out  std_logic_vector ( 31 downto 0);
		RXDISPERR : out std_logic_vector ( 3 downto 0) ;
                RXLOSSOFSYNC : out std_logic_vector(1 downto 0);                
		RXNOTINTABLE : out  std_logic_vector ( 3 downto 0 );
		RXREALIGN : out std_ulogic;
		RXRECCLK : out std_ulogic ;
		RXRUNDISP : out std_logic_vector ( 3 downto 0 );
		TXBUFERR : out std_ulogic;
		TXKERR : out std_logic_vector ( 3 downto 0 );
		TXN : out std_ulogic ;
		TXP : out std_ulogic;
		TXRUNDISP : out std_logic_vector ( 3 downto 0 );
		BREFCLK : in std_logic;
		BREFCLK2 : in std_logic;
		CONFIGENABLE : in std_ulogic;
		CONFIGIN : in std_ulogic ;
		ENMCOMMAALIGN : in std_ulogic ;
            ENPCOMMAALIGN : in std_ulogic ;  
		LOOPBACK : in std_logic_vector ( 1 downto 0 );
		POWERDOWN : in std_ulogic;
		REFCLK : in std_ulogic ;
                REFCLK2 : in std_ulogic;   
                REFCLKSEL : in std_ulogic;                
		RXN : in std_ulogic ;
		RXP : in std_ulogic ;
		RXPOLARITY : in std_ulogic;
		RXRESET : in std_ulogic;
		RXUSRCLK : in std_ulogic;
		RXUSRCLK2 : in std_ulogic;
		TXBYPASS8B10B : in std_logic_vector ( 3 downto 0 );
		TXCHARDISPMODE : in std_logic_vector ( 3 downto 0 );
		TXCHARDISPVAL : in std_logic_vector ( 3 downto 0 );
		TXCHARISK : in std_logic_vector ( 3 downto 0 );
		TXDATA : in std_logic_vector ( 31 downto 0 );
		TXFORCECRCERR : in std_ulogic;
		TXINHIBIT : in std_ulogic ;
		TXPOLARITY : in std_ulogic;
		TXRESET : in std_ulogic;
		TXUSRCLK : in std_ulogic;
		TXUSRCLK2: in std_ulogic 

	);
end component;
attribute syn_black_box of GT_FIBRE_CHAN_4 : component is true;

component GT_INFINIBAND_1
	port (
		CHBONDO    : out  std_logic_vector ( 3 downto 0 );
                CHBONDDONE : out  std_ulogic ;                
		CONFIGOUT  : out  std_ulogic ;
		RXBUFSTATUS: out  std_logic_vector (1 downto 0);
		RXCHARISCOMMA : out  std_logic_vector ( 0 downto 0);
		RXCHARISK : out  std_logic_vector ( 0 downto 0 );
		RXCHECKINGCRC : out std_ulogic;
                RXCLKCORCNT : out std_logic_vector(2 downto 0);                 
		RXCOMMADET : out  std_ulogic ;
           	RXCRCERR : out std_ulogic;                
		RXDATA : out  std_logic_vector ( 7 downto 0);
		RXDISPERR : out std_logic_vector ( 0 downto 0) ;
                RXLOSSOFSYNC : out std_logic_vector(1 downto 0);                
		RXNOTINTABLE : out  std_logic_vector ( 0 downto 0 );
		RXREALIGN : out std_ulogic;
		RXRECCLK : out std_ulogic ;
		RXRUNDISP : out std_logic_vector ( 0 downto 0 );
		TXBUFERR : out std_ulogic;
		TXKERR : out std_logic_vector ( 0 downto 0 );
		TXN : out std_ulogic ;
		TXP : out std_ulogic;
		TXRUNDISP : out std_logic_vector ( 0 downto 0 );
		BREFCLK : in std_logic;
		BREFCLK2 : in std_logic;
		CHBONDI : in std_logic_vector ( 3 downto 0 );
		CONFIGENABLE : in std_ulogic;
		CONFIGIN : in std_ulogic ;
		ENCHANSYNC : in std_ulogic ;
		ENMCOMMAALIGN : in std_ulogic ;
            ENPCOMMAALIGN : in std_ulogic ;  
		LOOPBACK : in std_logic_vector ( 1 downto 0 );
		POWERDOWN : in std_ulogic;
		REFCLK : in std_ulogic ;
                REFCLK2 : in std_ulogic;   
                REFCLKSEL : in std_ulogic;                
		RXN : in std_ulogic ;
		RXP : in std_ulogic ;
		RXPOLARITY : in std_ulogic;
		RXRESET : in std_ulogic;
		RXUSRCLK : in std_ulogic;
		RXUSRCLK2 : in std_ulogic;
		TXBYPASS8B10B : in std_logic_vector ( 0 downto 0 );
		TXCHARDISPMODE : in std_logic_vector ( 0 downto 0 );
		TXCHARDISPVAL : in std_logic_vector ( 0 downto 0 );
		TXCHARISK : in std_logic_vector ( 0 downto 0 );
		TXDATA : in std_logic_vector ( 7 downto 0 );
		TXFORCECRCERR : in std_ulogic;
		TXINHIBIT : in std_ulogic ;
		TXPOLARITY : in std_ulogic;
		TXRESET : in std_ulogic;
		TXUSRCLK : in std_ulogic;
		TXUSRCLK2 : in std_ulogic

	);
end component;
attribute syn_black_box of GT_INFINIBAND_1 : component is true;

component GT_INFINIBAND_2
	port (
                CHBONDDONE : out  std_ulogic ;          
		CHBONDO    : out  std_logic_vector ( 3 downto 0 );
		CONFIGOUT  : out  std_ulogic ;
		RXBUFSTATUS: out  std_logic_vector (1 downto 0);
		RXCHARISCOMMA : out  std_logic_vector ( 1 downto 0);
		RXCHARISK : out  std_logic_vector ( 1 downto 0 );
		RXCHECKINGCRC : out std_ulogic;
                RXCLKCORCNT : out std_logic_vector(2 downto 0);                 
		RXCOMMADET : out  std_ulogic ;
           	RXCRCERR : out std_ulogic;                
		RXDATA : out  std_logic_vector ( 15 downto 0);
		RXDISPERR : out std_logic_vector ( 1 downto 0) ;
                RXLOSSOFSYNC : out std_logic_vector(1 downto 0);                
		RXNOTINTABLE : out  std_logic_vector ( 1 downto 0 );
		RXREALIGN : out std_ulogic;
		RXRECCLK : out std_ulogic ;
		RXRUNDISP : out std_logic_vector ( 1 downto 0 );
		TXBUFERR : out std_ulogic;
		TXKERR : out std_logic_vector ( 1 downto 0 );
		TXN : out std_ulogic ;
		TXP : out std_ulogic;
		TXRUNDISP : out std_logic_vector ( 1 downto 0 );
		BREFCLK : in std_logic;
		BREFCLK2 : in std_logic;
		CHBONDI : in std_logic_vector ( 3 downto 0 );
		CONFIGENABLE : in std_ulogic;
		CONFIGIN : in std_ulogic ;
		ENCHANSYNC : in std_ulogic ;
		ENMCOMMAALIGN : in std_ulogic ;
            ENPCOMMAALIGN : in std_ulogic ;  
		LOOPBACK : in std_logic_vector ( 1 downto 0 );
		POWERDOWN : in std_ulogic;
		REFCLK : in std_ulogic ;
                REFCLK2 : in std_ulogic ;
                REFCLKSEL : in std_ulogic ;                
		RXN : in std_ulogic ;
		RXP : in std_ulogic ;
		RXPOLARITY : in std_ulogic;
		RXRESET : in std_ulogic;
		RXUSRCLK : in std_ulogic;
		RXUSRCLK2 : in std_ulogic;
		TXBYPASS8B10B : in std_logic_vector ( 1 downto 0 );
		TXCHARDISPMODE : in std_logic_vector ( 1 downto 0 );
		TXCHARDISPVAL : in std_logic_vector ( 1 downto 0 );
		TXCHARISK : in std_logic_vector ( 1 downto 0 );
		TXDATA : in std_logic_vector ( 15 downto 0 );
		TXFORCECRCERR : in std_ulogic;
		TXINHIBIT : in std_ulogic ;
		TXPOLARITY : in std_ulogic;
		TXRESET : in std_ulogic;
		TXUSRCLK : in std_ulogic;
		TXUSRCLK2 : in std_ulogic

	);
end component;
attribute syn_black_box of GT_INFINIBAND_2 : component is true;

component GT_INFINIBAND_4
	port (
		CHBONDO    : out  std_logic_vector ( 3 downto 0 );
                CHBONDDONE : out  std_ulogic ;                
		CONFIGOUT  : out  std_ulogic ;
		RXBUFSTATUS: out  std_logic_vector (1 downto 0);
		RXCHARISCOMMA : out  std_logic_vector ( 3 downto 0);
		RXCHARISK : out  std_logic_vector ( 3 downto 0 );
		RXCHECKINGCRC : out std_ulogic;
                RXCLKCORCNT : out std_logic_vector(2 downto 0);                 
		RXCOMMADET : out  std_ulogic ;
           	RXCRCERR : out std_ulogic;                
		RXDATA : out  std_logic_vector ( 31 downto 0);
		RXDISPERR : out std_logic_vector ( 3 downto 0) ;
                RXLOSSOFSYNC : out std_logic_vector(1 downto 0);                
		RXNOTINTABLE : out  std_logic_vector ( 3 downto 0 );
		RXREALIGN : out std_ulogic;
		RXRECCLK : out std_ulogic ;
		RXRUNDISP : out std_logic_vector ( 3 downto 0 );
		TXBUFERR : out std_ulogic;
		TXKERR : out std_logic_vector ( 3 downto 0 );
		TXN : out std_ulogic ;
		TXP : out std_ulogic;
		TXRUNDISP : out std_logic_vector ( 3 downto 0 );
		BREFCLK : in std_logic;
		BREFCLK2 : in std_logic;
		CHBONDI : in std_logic_vector ( 3 downto 0 );
		CONFIGENABLE : in std_ulogic;
		CONFIGIN : in std_ulogic ;
		ENCHANSYNC : in std_ulogic ;
		ENMCOMMAALIGN : in std_ulogic ;
            ENPCOMMAALIGN : in std_ulogic ;  
		LOOPBACK : in std_logic_vector ( 1 downto 0 );
		POWERDOWN : in std_ulogic;
		REFCLK : in std_ulogic ;
                REFCLK2 : in std_ulogic;   
                REFCLKSEL : in std_ulogic;                
		RXN : in std_ulogic ;
		RXP : in std_ulogic ;
		RXPOLARITY : in std_ulogic;
		RXRESET : in std_ulogic;
		RXUSRCLK : in std_ulogic;
		RXUSRCLK2 : in std_ulogic;
		TXBYPASS8B10B : in std_logic_vector ( 3 downto 0 );
		TXCHARDISPMODE : in std_logic_vector ( 3 downto 0 );
		TXCHARDISPVAL : in std_logic_vector ( 3 downto 0 );
		TXCHARISK : in std_logic_vector ( 3 downto 0 );
		TXDATA : in std_logic_vector ( 31 downto 0 );
		TXFORCECRCERR : in std_ulogic;
		TXINHIBIT : in std_ulogic ;
		TXPOLARITY : in std_ulogic;
		TXRESET : in std_ulogic;
		TXUSRCLK : in std_ulogic;
		TXUSRCLK2: in std_ulogic 

	);
end component;
attribute syn_black_box of GT_INFINIBAND_4 : component is true;

component GT_XAUI_1
	port (
                CHBONDDONE : out  std_ulogic ;          
		CHBONDO    : out  std_logic_vector ( 3 downto 0 );
		CONFIGOUT  : out  std_ulogic ;
		RXBUFSTATUS: out  std_logic_vector (1 downto 0);
		RXCHARISCOMMA : out  std_logic_vector ( 0 downto 0);
		RXCHARISK : out  std_logic_vector ( 0 downto 0 );
		RXCHECKINGCRC : out std_ulogic;
                RXCLKCORCNT : out std_logic_vector(2 downto 0);                 
		RXCOMMADET : out  std_ulogic ;
           	RXCRCERR : out std_ulogic;                
		RXDATA : out  std_logic_vector ( 7 downto 0);
		RXDISPERR : out std_logic_vector ( 0 downto 0) ;
                RXLOSSOFSYNC : out std_logic_vector(1 downto 0);                
		RXNOTINTABLE : out  std_logic_vector ( 0 downto 0 );
		RXREALIGN : out std_ulogic;
		RXRECCLK : out std_ulogic ;
		RXRUNDISP : out std_logic_vector ( 0 downto 0 );
		TXBUFERR : out std_ulogic;
		TXKERR : out std_logic_vector ( 0 downto 0 );
		TXN : out std_ulogic ;
		TXP : out std_ulogic;
		TXRUNDISP : out std_logic_vector ( 0 downto 0 );
		BREFCLK : in std_logic;
		BREFCLK2 : in std_logic;
		CHBONDI : in std_logic_vector ( 3 downto 0 );
		CONFIGENABLE : in std_ulogic;
		CONFIGIN : in std_ulogic ;
		ENCHANSYNC : in std_ulogic ;
		ENMCOMMAALIGN : in std_ulogic ;
            ENPCOMMAALIGN : in std_ulogic ;  
		LOOPBACK : in std_logic_vector ( 1 downto 0 );
		POWERDOWN : in std_ulogic;
		REFCLK : in std_ulogic ;
                REFCLK2 : in std_ulogic;   
                REFCLKSEL : in std_ulogic;                
		RXN : in std_ulogic ;
		RXP : in std_ulogic ;
		RXPOLARITY : in std_ulogic;
		RXRESET : in std_ulogic;
		RXUSRCLK : in std_ulogic;
		RXUSRCLK2 : in std_ulogic;
		TXBYPASS8B10B : in std_logic_vector ( 0 downto 0 );
		TXCHARDISPMODE : in std_logic_vector ( 0 downto 0 );
		TXCHARDISPVAL : in std_logic_vector ( 0 downto 0 );
		TXCHARISK : in std_logic_vector ( 0 downto 0 );
		TXDATA : in std_logic_vector ( 7 downto 0 );
		TXFORCECRCERR : in std_ulogic;
		TXINHIBIT : in std_ulogic ;
		TXPOLARITY : in std_ulogic;
		TXRESET : in std_ulogic;
		TXUSRCLK : in std_ulogic;
		TXUSRCLK2: in std_ulogic 

	);
end component;
attribute syn_black_box of GT_XAUI_1 : component is true;

component GT_XAUI_2
	port (
                CHBONDDONE : out  std_ulogic ;          
		CHBONDO    : out  std_logic_vector ( 3 downto 0 );
		CONFIGOUT  : out  std_ulogic ;
		RXBUFSTATUS: out  std_logic_vector (1 downto 0);
		RXCHARISCOMMA : out  std_logic_vector ( 1 downto 0);
		RXCHARISK : out  std_logic_vector ( 1 downto 0 );
		RXCHECKINGCRC : out std_ulogic;
                RXCLKCORCNT : out std_logic_vector(2 downto 0);                 
		RXCOMMADET : out  std_ulogic ;
           	RXCRCERR : out std_ulogic;                
		RXDATA : out  std_logic_vector ( 15 downto 0);
		RXDISPERR : out std_logic_vector ( 1 downto 0) ;
                RXLOSSOFSYNC : out std_logic_vector(1 downto 0);                
		RXNOTINTABLE : out  std_logic_vector ( 1 downto 0 );
		RXREALIGN : out std_ulogic;
		RXRECCLK : out std_ulogic ;
		RXRUNDISP : out std_logic_vector ( 1 downto 0 );
		TXBUFERR : out std_ulogic;
		TXKERR : out std_logic_vector ( 1 downto 0 );
		TXN : out std_ulogic ;
		TXP : out std_ulogic;
		TXRUNDISP : out std_logic_vector ( 1 downto 0 );
		BREFCLK : in std_logic;
		BREFCLK2 : in std_logic;
		CHBONDI : in std_logic_vector ( 3 downto 0 );
		CONFIGENABLE : in std_ulogic;
		CONFIGIN : in std_ulogic ;
		ENCHANSYNC : in std_ulogic ;
		ENMCOMMAALIGN : in std_ulogic ;
            ENPCOMMAALIGN : in std_ulogic ;  
		LOOPBACK : in std_logic_vector ( 1 downto 0 );
		POWERDOWN : in std_ulogic;
		REFCLK : in std_ulogic ;
                REFCLK2 : in std_ulogic;   
                REFCLKSEL : in std_ulogic;                
		RXN : in std_ulogic ;
		RXP : in std_ulogic ;
		RXPOLARITY : in std_ulogic;
		RXRESET : in std_ulogic;
		RXUSRCLK : in std_ulogic;
		RXUSRCLK2 : in std_ulogic;
		TXBYPASS8B10B : in std_logic_vector ( 1 downto 0 );
		TXCHARDISPMODE : in std_logic_vector ( 1 downto 0 );
		TXCHARDISPVAL : in std_logic_vector ( 1 downto 0 );
		TXCHARISK : in std_logic_vector ( 1 downto 0 );
		TXDATA : in std_logic_vector ( 15 downto 0 );
		TXFORCECRCERR : in std_ulogic;
		TXINHIBIT : in std_ulogic ;
		TXPOLARITY : in std_ulogic;
		TXRESET : in std_ulogic;
		TXUSRCLK : in std_ulogic;
		TXUSRCLK2: in std_ulogic 

	);
end component;
attribute syn_black_box of GT_XAUI_2 : component is true;

component GT_XAUI_4
	port (
                CHBONDDONE : out  std_ulogic ;          
		CHBONDO    : out  std_logic_vector ( 3 downto 0 );
		CONFIGOUT  : out  std_ulogic ;
		RXBUFSTATUS: out  std_logic_vector (1 downto 0);
		RXCHARISCOMMA : out  std_logic_vector ( 3 downto 0);
		RXCHARISK : out  std_logic_vector ( 3 downto 0 );
		RXCHECKINGCRC : out std_ulogic;
                RXCLKCORCNT : out std_logic_vector(2 downto 0);                 
		RXCOMMADET : out  std_ulogic ;
           	RXCRCERR : out std_ulogic;                
		RXDATA : out  std_logic_vector ( 31 downto 0);
		RXDISPERR : out std_logic_vector ( 3 downto 0) ;
                RXLOSSOFSYNC : out std_logic_vector(1 downto 0);                
		RXNOTINTABLE : out  std_logic_vector ( 3 downto 0 );
		RXREALIGN : out std_ulogic;
		RXRECCLK : out std_ulogic ;
		RXRUNDISP : out std_logic_vector ( 3 downto 0 );
		TXBUFERR : out std_ulogic;
		TXKERR : out std_logic_vector ( 3 downto 0 );
		TXN : out std_ulogic ;
		TXP : out std_ulogic;
		TXRUNDISP : out std_logic_vector ( 3 downto 0 );
		BREFCLK : in std_logic;
		BREFCLK2 : in std_logic;
		CHBONDI : in std_logic_vector ( 3 downto 0 );
		CONFIGENABLE : in std_ulogic;
		CONFIGIN : in std_ulogic ;
		ENCHANSYNC : in std_ulogic ;
		ENMCOMMAALIGN : in std_ulogic ;
            ENPCOMMAALIGN : in std_ulogic ;  
		LOOPBACK : in std_logic_vector ( 1 downto 0 );
		POWERDOWN : in std_ulogic;
		REFCLK : in std_ulogic ;
                REFCLK2 : in std_ulogic;   
                REFCLKSEL : in std_ulogic;
		RXN : in std_ulogic ;
		RXP : in std_ulogic ;
		RXPOLARITY : in std_ulogic;
		RXRESET : in std_ulogic;
		RXUSRCLK : in std_ulogic;
		RXUSRCLK2 : in std_ulogic;
		TXFORCECRCERR : in std_ulogic;
		TXBYPASS8B10B : in std_logic_vector ( 3 downto 0 );
		TXCHARDISPMODE : in std_logic_vector ( 3 downto 0 );
		TXCHARDISPVAL : in std_logic_vector ( 3 downto 0 );
		TXCHARISK : in std_logic_vector ( 3 downto 0 );
		TXDATA : in std_logic_vector ( 31 downto 0 );
		TXINHIBIT : in std_ulogic ;
		TXPOLARITY : in std_ulogic;
		TXRESET : in std_ulogic;
		TXUSRCLK : in std_ulogic;
		TXUSRCLK2: in std_ulogic 
	);
end component;
attribute syn_black_box of GT_XAUI_4 : component is true;

component JTAGPPC 
  port (
        TCK : out std_logic;
        TDIPPC : out std_logic;
        TMS : out std_logic;

        TDOPPC : in std_logic;
        TDOTSPPC : in std_logic
        );
end component;
attribute syn_black_box of JTAGPPC : component is true;

component PPC405 
  port (
	C405CPMCORESLEEPREQ : out std_ulogic;
	C405CPMMSRCE : out std_ulogic;
	C405CPMMSREE : out std_ulogic;
	C405CPMTIMERIRQ : out std_ulogic;
	C405CPMTIMERRESETREQ : out std_ulogic;
	C405DBGMSRWE : out std_ulogic;
	C405DBGSTOPACK : out std_ulogic;
	C405DBGWBCOMPLETE : out std_ulogic;
	C405DBGWBFULL : out std_ulogic;
	C405DBGWBIAR : out std_logic_vector(0 TO 29);
	C405DCRABUS : out std_logic_vector(0 TO 9);
	C405DCRDBUSOUT : out std_logic_vector(0 TO 31);
	C405DCRREAD : out std_ulogic;
	C405DCRWRITE : out std_ulogic;
	C405JTGCAPTUREDR : out std_ulogic;
	C405JTGEXTEST : out std_ulogic;
	C405JTGPGMOUT : out std_ulogic;
	C405JTGSHIFTDR : out std_ulogic;
	C405JTGTDO : out std_ulogic;
	C405JTGTDOEN : out std_ulogic;
	C405JTGUPDATEDR : out std_ulogic;
	C405PLBDCUABORT : out std_ulogic;
	C405PLBDCUABUS : out std_logic_vector(0 TO 31);
	C405PLBDCUBE : out std_logic_vector(0 TO 7);
	C405PLBDCUCACHEABLE : out std_ulogic;
	C405PLBDCUGUARDED : out std_ulogic;
	C405PLBDCUPRIORITY : out std_logic_vector(0 TO 1);
	C405PLBDCUREQUEST : out std_ulogic;
	C405PLBDCURNW : out std_ulogic;
	C405PLBDCUSIZE2 : out std_ulogic;
	C405PLBDCUU0ATTR : out std_ulogic;
	C405PLBDCUWRDBUS : out std_logic_vector(0 TO 63);
	C405PLBDCUWRITETHRU : out std_ulogic;
	C405PLBICUABORT : out std_ulogic;
	C405PLBICUABUS : out std_logic_vector(0 TO 29);
	C405PLBICUCACHEABLE : out std_ulogic;
	C405PLBICUPRIORITY : out std_logic_vector(0 TO 1);
	C405PLBICUREQUEST : out std_ulogic;
	C405PLBICUSIZE : out std_logic_vector(2 TO 3);
	C405PLBICUU0ATTR : out std_ulogic;
	C405RSTCHIPRESETREQ : out std_ulogic;
	C405RSTCORERESETREQ : out std_ulogic;
	C405RSTSYSRESETREQ : out std_ulogic;
	C405TRCCYCLE : out std_ulogic;
	C405TRCEVENEXECUTIONSTATUS : out std_logic_vector(0 TO 1);
	C405TRCODDEXECUTIONSTATUS : out std_logic_vector(0 TO 1);
	C405TRCTRACESTATUS : out std_logic_vector(0 TO 3);
	C405TRCTRIGGEREVENTOUT : out std_ulogic;
	C405TRCTRIGGEREVENTTYPE : out std_logic_vector(0 TO 10);
	C405XXXMACHINECHECK : out std_ulogic;
	DSOCMBRAMABUS : out std_logic_vector(8 TO 29);
	DSOCMBRAMBYTEWRITE : out std_logic_vector(0 TO 3);
	DSOCMBRAMEN : out std_ulogic;
	DSOCMBRAMWRDBUS : out std_logic_vector(0 TO 31);
	DSOCMBUSY : out std_ulogic;
	ISOCMBRAMEN : out std_ulogic;
	ISOCMBRAMEVENWRITEEN : out std_ulogic;
	ISOCMBRAMODDWRITEEN : out std_ulogic;
	ISOCMBRAMRDABUS : out std_logic_vector(8 TO 28);
	ISOCMBRAMWRABUS : out std_logic_vector(8 TO 28);
	ISOCMBRAMWRDBUS : out std_logic_vector(0 TO 31);
	BRAMDSOCMCLK : in std_ulogic;
	BRAMDSOCMRDDBUS : in std_logic_vector(0 TO 31);
	BRAMISOCMCLK : in std_ulogic;
	BRAMISOCMRDDBUS : in std_logic_vector(0 TO 63);
	CPMC405CLOCK : in std_ulogic;
	CPMC405CORECLKINACTIVE : in std_ulogic;
	CPMC405CPUCLKEN : in std_ulogic;
	CPMC405JTAGCLKEN : in std_ulogic;
	CPMC405TIMERCLKEN : in std_ulogic;
	CPMC405TIMERTICK : in std_ulogic;
	DBGC405DEBUGHALT : in std_ulogic;
	DBGC405EXTBUSHOLDACK : in std_ulogic;
	DBGC405UNCONDDEBUGEVENT : in std_ulogic;
	DCRC405ACK : in std_ulogic;
	DCRC405DBUSIN : in std_logic_vector(0 TO 31);
	DSARCVALUE : in std_logic_vector(0 TO 7);
	DSCNTLVALUE : in std_logic_vector(0 TO 7);
	EICC405CRITINPUTIRQ : in std_ulogic;
	EICC405EXTINPUTIRQ : in std_ulogic;
	ISARCVALUE : in std_logic_vector(0 TO 7);
	ISCNTLVALUE : in std_logic_vector(0 TO 7);
	JTGC405BNDSCANTDO : in std_ulogic;
	JTGC405TCK : in std_ulogic;
	JTGC405TDI : in std_ulogic;
	JTGC405TMS : in std_ulogic;
	JTGC405TRSTNEG : in std_ulogic;
	MCBCPUCLKEN : in std_ulogic;
	MCBJTAGEN : in std_ulogic;
	MCBTIMEREN : in std_ulogic;
	MCPPCRST : in std_ulogic;
	PLBC405DCUADDRACK : in std_ulogic;
	PLBC405DCUBUSY : in std_ulogic;
	PLBC405DCUERR : in std_ulogic;
	PLBC405DCURDDACK : in std_ulogic;
	PLBC405DCURDDBUS : in std_logic_vector(0 TO 63);
	PLBC405DCURDWDADDR : in std_logic_vector(1 TO 3);
	PLBC405DCUSSIZE1 : in std_ulogic;
	PLBC405DCUWRDACK : in std_ulogic;
	PLBC405ICUADDRACK : in std_ulogic;
	PLBC405ICUBUSY : in std_ulogic;
	PLBC405ICUERR : in std_ulogic;
	PLBC405ICURDDACK : in std_ulogic;
	PLBC405ICURDDBUS : in std_logic_vector(0 TO 63);
	PLBC405ICURDWDADDR : in std_logic_vector(1 TO 3);
	PLBC405ICUSSIZE1 : in std_ulogic;
	PLBCLK : in std_ulogic;
	RSTC405RESETCHIP : in std_ulogic;
	RSTC405RESETCORE : in std_ulogic;
	RSTC405RESETSYS : in std_ulogic;
	TIEC405DETERMINISTICMULT : in std_ulogic;
	TIEC405DISOPERANDFWD : in std_ulogic;
	TIEC405MMUEN : in std_ulogic;
	TIEDSOCMDCRADDR : in std_logic_vector(0 TO 7);
	TIEISOCMDCRADDR : in std_logic_vector(0 TO 7);
	TRCC405TRACEDISABLE : in std_ulogic;
	TRCC405TRIGGEREVENTIN : in std_ulogic
);
end component ;
attribute syn_black_box of PPC405 : component is true;

component BUFGCE 
     port(
	 O : out STD_ULOGIC;
	 CE: in STD_ULOGIC;
	 I : in STD_ULOGIC);
end component;
attribute syn_black_box of BUFGCE : component is true;

component BUFGCE_1
	port(
	O : out STD_ULOGIC;
	CE: in STD_ULOGIC;
	I : in STD_ULOGIC);
end component;
attribute syn_black_box of BUFGCE_1 : component is true;

component IFDDRCPE
   port(
      Q0                             :	out   STD_ULOGIC;
      Q1                             :	out   STD_ULOGIC;
      D                              :	in    STD_ULOGIC;
      C0                             :	in    STD_ULOGIC;
      C1                             :	in    STD_ULOGIC;
      CE                             :	in    STD_ULOGIC;
      PRE                             :	in    STD_ULOGIC;
      CLR                             :	in    STD_ULOGIC);
end component;
attribute syn_black_box of IFDDRCPE : component is true;

component IFDDRRSE 
   port(
      Q0                            :	out   STD_ULOGIC;
      Q1                            :	out   STD_ULOGIC;
      C0                             :	in    STD_ULOGIC;
      C1                             :	in    STD_ULOGIC;
      CE                             :	in    STD_ULOGIC;
      D                              :	in    STD_ULOGIC;
      R                              :	in    STD_ULOGIC;
      S                              :	in    STD_ULOGIC);
end component;
attribute syn_black_box of IFDDRRSE : component is true;

component OFDDRCPE 
   port(
      Q                             :	out   STD_ULOGIC;
      D0                             :	in    STD_ULOGIC;
      D1                             :	in    STD_ULOGIC;
      C0                             :	in    STD_ULOGIC;
      C1                             :	in    STD_ULOGIC;
      CE                             :	in    STD_ULOGIC;
      PRE                             :	in    STD_ULOGIC;
      CLR                             :	in    STD_ULOGIC);
end component;
attribute syn_black_box of OFDDRCPE : component is true;

component OFDDRRSE
   port(
      Q                            :	out   STD_ULOGIC;
      C0                             :	in    STD_ULOGIC;
      C1                             :	in    STD_ULOGIC;
      CE                             :	in    STD_ULOGIC;
      D0                             :	in    STD_ULOGIC;
      D1                             :	in    STD_ULOGIC;
      R                              :	in    STD_ULOGIC;
      S                              :	in    STD_ULOGIC);
end component;
attribute syn_black_box of OFDDRRSE : component is true;

component OFDDRTCPE
   port(
      O                             :	out   STD_ULOGIC;
      C0                             :	in    STD_ULOGIC;
      C1                             :	in    STD_ULOGIC;
      CE                             :	in    STD_ULOGIC;
      CLR                             :	in    STD_ULOGIC;
      D0                             :	in    STD_ULOGIC;
      D1                             :	in    STD_ULOGIC;
      PRE                             :	in    STD_ULOGIC;
      T                               :	in    STD_ULOGIC);
end component;
attribute syn_black_box of OFDDRTCPE : component is true;

component OFDDRTRSE
   port(
      O                            :	out   STD_ULOGIC;
      C0                             :	in    STD_ULOGIC;
      C1                             :	in    STD_ULOGIC;
      CE                             :	in    STD_ULOGIC;
      D0                             :	in    STD_ULOGIC;
      D1                             :	in    STD_ULOGIC;
      R                              :	in    STD_ULOGIC;
      S                              :	in    STD_ULOGIC;
      T                              :	in    STD_ULOGIC);
end component;
attribute syn_black_box of OFDDRTRSE : component is true;

component STARTBUF_VIRTEX2

  port( GSRIN     : in std_ulogic := 'X';
        GTSIN     : in std_ulogic := 'X';
        CLKIN     : in std_ulogic := 'X';
        GTSOUT    : out std_ulogic
  );
end component;
attribute syn_black_box of STARTBUF_VIRTEX2 : component is true;

end package components;

library IEEE;
use IEEE.std_logic_1164.all;
library virtex2;
use virtex2.components.all;
entity STARTUP_VIRTEX2 is
   port(CLK, GSR, GTS: in std_logic := '0');
end STARTUP_VIRTEX2;

architecture struct of STARTUP_VIRTEX2 is
attribute syn_noprune of struct : architecture is true;
begin
  gsr0 : STARTUP_VIRTEX2_GSR port map ( GSR => GSR );
  gts0 : STARTUP_VIRTEX2_GTS port map ( GTS => GTS );
  clk0 : STARTUP_VIRTEX2_CLK port map ( CLK => CLK);
end struct;


