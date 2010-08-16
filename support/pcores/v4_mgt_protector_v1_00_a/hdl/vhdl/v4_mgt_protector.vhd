library IEEE;
use IEEE.std_logic_1164.all;

entity v4_mgt_protector is
generic (
	G_NUM_MGTS : natural := 10	-- for v4fx100
);
port
(
  clk        : in std_logic;
  rx1n       : in std_logic_vector(2*G_NUM_MGTS-1 downto 0);
  rx1p       : in std_logic_vector(2*G_NUM_MGTS-1 downto 0);
  tx1n       : out std_logic_vector(2*G_NUM_MGTS-1 downto 0);
  tx1p       : out std_logic_vector(2*G_NUM_MGTS-1 downto 0)
 );


end v4_mgt_protector;

architecture structure of v4_mgt_protector is

   
  -------------------------------------------------------------------
  --
  --  NULL_PAIR core component declaration
  --
  -------------------------------------------------------------------
   COMPONENT NULL_PAIR
      PORT (
        GREFCLK_IN              : IN std_logic;   
        RX1N_IN                 : IN std_logic_vector(1 DOWNTO 0);   
        RX1P_IN                 : IN std_logic_vector(1 DOWNTO 0);   
        TX1N_OUT                : OUT std_logic_vector(1 DOWNTO 0);   
        TX1P_OUT                : OUT std_logic_vector(1 DOWNTO 0));   
   END COMPONENT;

attribute box_type: string;
attribute box_type of NULL_PAIR: component is "user_black_box";

   COMPONENT BUFG
     PORT (
        I                       : IN std_logic;
        O                       : OUT std_logic);
     END COMPONENT;

  -------------------------------------------------------------------
  --
  --  NULL_PAIR core signal declarations
  --
  -------------------------------------------------------------------

   signal global_sig : std_logic;


begin
           
  -------------------------------------------------------------------
  --
  --  GREFCLK_IN port needs to be driven with any global signal
  --  (any BUFG output, even a BUFG with ground for input will work).
  --
  -------------------------------------------------------------------
           global_bufg_inst : BUFG
           port map
           (
              I => clk,
              O => global_sig
           );
  
  -------------------------------------------------------------------
  --
  --  NULL_PAIR core instances
  --
  -------------------------------------------------------------------
	mgt: for i in 0 to G_NUM_MGTS-1 generate
            null_pair_inst: NULL_PAIR
            port map
            (  
               GREFCLK_IN => global_sig,
               RX1N_IN    => rx1n(2*i+1 downto 2*i),
               RX1P_IN    => rx1p(2*i+1 downto 2*i),
               TX1N_OUT   => tx1n(2*i+1 downto 2*i), 
               TX1P_OUT   => tx1p(2*i+1 downto 2*i)
            );
	end generate;

end structure;


