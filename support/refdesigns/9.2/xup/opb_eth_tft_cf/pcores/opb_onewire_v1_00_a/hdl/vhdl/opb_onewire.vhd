library ieee;
use ieee.std_logic_1164.all;

library Common_v1_00_a;
use Common_v1_00_a.pselect;

library opb_onewire_v1_00_a; 
use opb_onewire_v1_00_a.all;

library unisim;
use unisim.vcomponents.all;

entity opb_onewire is  
  generic
  (
    -- opb_ipif_ssp1
    C_BASEADDR         : std_logic_vector(0 to 31) := X"FFFE_0400";
    C_HIGHADDR         : std_logic_vector(0 to 31) := X"FFFE_05FF";
    C_OPB_AWIDTH       : integer                   := 32;
    C_OPB_DWIDTH       : integer                   := 32;
    --
    CheckCRC           : boolean := true;
    ADD_PULLUP         : boolean := true;  
    CLK_DIV            : integer range 0 to 15 := 15
  );
  port
  (
    OPB_Clk      : in  std_logic;
    OPB_Rst      : in  std_logic;

    OPB_ABus     : in  std_logic_vector(0 to C_OPB_AWIDTH-1);
    OPB_BE       : in  std_logic_vector(0 to C_OPB_DWIDTH/8-1);
    OPB_RNW      : in  std_logic;
    OPB_select   : in  std_logic;
    OPB_seqAddr  : in  std_logic;
    OPB_DBus     : in  std_logic_vector(0 to C_OPB_DWIDTH-1);

    OW_Dbus     : out std_logic_vector(0 to C_OPB_DWIDTH-1);
    OW_errAck   : out std_logic;
    OW_retry    : out std_logic;
    OW_toutSup  : out std_logic;
    OW_xferAck  : out std_logic;

    -- onewire will use opb bus
    ONEWIRE_DQ  : inout std_logic      -- one wire bus
    
  );

end entity opb_onewire;

-------------------------------------------------------------------------------
-- Architecture Section
-------------------------------------------------------------------------------

architecture imp of opb_onewire is 

-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Signal and Type Declarations
-------------------------------------------------------------------------------

  signal onewire_CS_1 : std_logic;    -- Active as long as UART_CS is active
  signal onewire_CS_2 : std_logic;    -- Active only 1 clock cycle during an
  signal onewire_CS_3 : std_logic;    -- Active only 1 clock cycle during an
                                      -- access

  signal opb_RNW_1 : std_logic;
  signal onewire_CS : std_logic;

  signal xfer_Ack     : std_logic;

  -- onewire signals
  signal onewire_serial_data  : std_logic_vector(47 downto 0);
  signal onewire_crcok : std_logic;
  signal onewire_valid : std_logic;
  signal onewire_data : std_logic_vector(7 downto 0);

  signal low_reg : std_logic_vector(0 to 31);
  signal high_reg : std_logic_vector(0 to 31);
  signal output_data : std_logic_vector(0 to 31);
  
-------------------------------------------------------------------------------
-- Component Declarations
-------------------------------------------------------------------------------

  component onewire_iface
    generic (
      CheckCRC : boolean;
      ADD_PULLUP : boolean;
      CLK_DIV  : integer range 0 to 15);
    port (
      sys_clk     : in  std_logic;    -- system clock (50Mhz)
      sys_reset   : in  std_logic;    -- active high syn. reset 
      dq          : inout std_logic;  -- connect to the 1-wire bus
      data        : out std_logic_vector(7 downto 0); -- data output
      data_valid  : out std_logic;    -- data output valid (20us strobe)
      crc_ok      : out std_logic;    -- crc ok signal (active high)
      sn_data     : out std_logic_vector(47 downto 0));  -- parallel out
  end component;

  component pselect is
    generic (
      C_AB  : integer;
      C_AW  : integer;
      C_BAR : std_logic_vector);
    port (
      A      : in  std_logic_vector(0 to C_AW-1);
      AValid : in  std_logic;
      ps     : out std_logic);
  end component pselect;

  component FDRE is
    port (
      Q  : out std_logic;
      C  : in  std_logic;
      CE : in  std_logic;
      D  : in  std_logic;
      R  : in  std_logic);
  end component FDRE;

  component FDR is
    port (Q : out std_logic;
          C : in  std_logic;
          D : in  std_logic;
          R : in  std_logic);
  end component FDR;

  function Addr_Bits (x, y : std_logic_vector(0 to C_OPB_AWIDTH-1)) return integer is
    variable addr_nor : std_logic_vector(0 to C_OPB_AWIDTH-1);
  begin
    addr_nor := x xor y;
    for i in 0 to C_OPB_AWIDTH-1 loop
      if addr_nor(i) = '1' then return i;
      end if;
    end loop;
    return(C_OPB_AWIDTH);
  end function Addr_Bits;

  constant C_AB : integer := Addr_Bits(C_HIGHADDR, C_BASEADDR);
  
------------------------------------------------------------------------------
begin
------------------------------------------------------------------------------

  -- Do the OPB address decoding
  pselect_I : pselect
    generic map (
      C_AB  => C_AB,                 
      C_AW  => C_OPB_AWIDTH,         
      C_BAR => C_BASEADDR)           
    port map (
      A      => OPB_ABus,            
      AValid => OPB_select,          
      ps     => onewire_CS);         

  onewire_CS_1_DFF : FDR
    port map (
      Q => onewire_CS_1,                   -- [out std_logic]
      C => OPB_Clk,                         -- [in  std_logic]
      D => onewire_CS,                     -- [in  std_logic]
      R => xfer_Ack);                   -- [in std_logica]

  onewire_CS_2_DFF: process (OPB_Clk, OPB_Rst) is
  begin
    if OPB_Rst = '1' then                 -- asynchronous reset (active high)
      onewire_CS_2 <= '0';
      onewire_CS_3 <= '0';
      opb_RNW_1 <= '0';
    elsif OPB_Clk'event and OPB_Clk = '1' then  -- rising clock edge
      onewire_CS_2 <= onewire_CS_1 and not onewire_CS_2 and not onewire_CS_3;
      onewire_CS_3 <= onewire_CS_2;
      opb_RNW_1 <= OPB_RNW;
    end if;
  end process onewire_CS_2_DFF;

  -- xfer signal
  XFER_Control : process (OPB_Clk, OPB_Rst) is
  begin  -- process XFER_Control
    if OPB_Rst = '1' then                 -- asynchronous reset (active high)
      xfer_Ack    <= '0';
    elsif OPB_Clk'event and OPB_Clk = '1' then  -- rising clock edge
      xfer_Ack <= onewire_CS_2;
    end if;
  end process XFER_Control;
  
  OW_xferAck <= xfer_Ack;
  
  uut: onewire_iface 
    generic map (
      CheckCRC   => CheckCRC,
      ADD_PULLUP => ADD_PULLUP,
      CLK_DIV    => CLK_DIV)
    port map(
      sys_clk      => OPB_Clk,
      sys_reset    => OPB_Rst,
      crc_ok       => onewire_crcok,
      data         => onewire_data, 
      data_valid   => onewire_valid,
      sn_data      => onewire_serial_data,
      dq           => ONEWIRE_DQ);
  

  -- interface code
  -- Register 0: lower 32 bits of 48-bit one wire value
  -- Register 1:
  --    lower 16 bits are the upper 16 bits of 48-bit one wire value
  --    next 8 bits are the 8 data bits
  --    next bit is data valid
  --    next bit is crc ok
  low_reg <= onewire_serial_data(31 downto 0);
  high_reg <=  "000000" & onewire_crcok & onewire_valid & onewire_data &
               onewire_serial_data(47 downto 32);

  Read_Mux : process (OPB_ABus) is
  begin  -- process Read_Mux
    output_data <= (others => '0');
    if (OPB_ABus(29) = '1') then
      output_data <= high_reg;
    else
      output_data <= low_reg;
    end if;
  end process Read_Mux;

  OPB_rdDBus_DFF : for I in output_data'range generate
    OPB_rdBus_FDRE : FDRE
      port map (
        Q  => OW_Dbus(I),              -- [out std_logic]
        C  => OPB_Clk,                      -- [in  std_logic]
        CE => onewire_CS_2,                -- [in  std_logic]
        D  => output_data(I),            -- [in  std_logic]
        R  => xfer_Ack);                -- [in std_logic]
  end generate OPB_rdDBus_DFF;

  OW_Retry       <= '0';
  OW_errAck      <= '0'; -- no error
  OW_toutSup     <= '0';
  
end architecture imp;

