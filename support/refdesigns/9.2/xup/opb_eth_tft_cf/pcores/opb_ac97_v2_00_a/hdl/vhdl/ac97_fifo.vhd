-------------------------------------------------------------------------------
-- Filename:        ac97_fifo.vhd
--
-- Description:     This module provides a FIFO interface for the AC97
--                  module and provides an asyncrhonous interface for a
--                  higher level module that is not synchronous with the AC97
--                  clock (Bit_Clk).
--
--                  This module provides a FIFO interface for both the incoming
--                  data (playback data) and outgoing data (record data).
--
--                  This module provides a bus independent interface so the
--                  module can be used for more than one bus interface.
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              ac97_core
--                 ac97_timing
--              srl_fifo
--
-------------------------------------------------------------------------------
-- Author:          Mike Wirthlin
--
--
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------
-- 
-------------------------------------------------------------------------------
entity ac97_fifo is
  generic (
    C_AWIDTH	: integer	:= 32;
    C_DWIDTH	: integer	:= 32;
    C_PLAYBACK  : integer       := 1;
    C_RECORD    : integer       := 1;
    -- Interrupt strategy
    -- 0 = No interrupts
    -- 1 = when fifos are half empty (in half empty, out is half full)
    -- 2 = when fifos are empty (in is empty, out is full)
    -- 3 = when fifos are equal to interrupt fifo depth
    C_INTR_LEVEL      : integer                   := 0;
    -- Use block ram FIFOs if 1, otherwise use a shallow
    -- SRL fifo.
    C_USE_BRAM   : integer  := 1
    );
  port (
    -- IP Interface
    Bus2IP_Clk      : in  std_logic;
    Bus2IP_Reset    : in  std_logic;
    Bus2IP_Addr     : in  std_logic_vector(0 to C_AWIDTH-1);
    Bus2IP_Data     : in  std_logic_vector(0 to C_AWIDTH-1);
    Bus2IP_BE	    : in  std_logic_vector(0 to C_DWIDTH/8-1);
    Bus2IP_RdCE	    : in  std_logic;
    Bus2IP_WrCE	    : in  std_logic;
    IP2Bus_Data     : out std_logic_vector(0 to C_DWIDTH-1);

    Interrupt: out std_logic;
    
    -- CODEC signals
    Bit_Clk   : in  std_logic;
    Sync      : out std_logic;
    SData_Out : out std_logic;
    SData_In  : in  std_logic;
    AC97Reset_n : out std_logic

    );

end entity ac97_fifo;

library opb_ac97_v2_00_a;
use opb_ac97_v2_00_a.all;

library unisim;
use unisim.all;

architecture IMP of ac97_fifo is

component ac97_core is
  generic (
    C_PCM_DATA_WIDTH : integer := 16
    );
  port (

    Reset : in std_logic;

    -- signals attaching directly to AC97 codec
    AC97_Bit_Clk   : in  std_logic;
    AC97_Sync      : out std_logic;
    AC97_SData_Out : out std_logic;
    AC97_SData_In  : in  std_logic;

    -- AC97 register interface
    AC97_Reg_Addr            : in  std_logic_vector(0 to 6);
    AC97_Reg_Write_Data      : in  std_logic_vector(0 to 15);
    AC97_Reg_Read_Data       : out std_logic_vector(0 to 15);
    AC97_Reg_Read_Strobe     : in  std_logic;  -- initiates a "read" command
    AC97_Reg_Write_Strobe    : in  std_logic;  -- initiates a "write" command
    AC97_Reg_Busy            : out std_logic;
    AC97_Reg_Error           : out std_logic;
    AC97_Reg_Read_Data_Valid : out std_logic;
    
    -- Playback signal interface
    PCM_Playback_Left: in std_logic_vector(0 to C_PCM_DATA_WIDTH-1);
    PCM_Playback_Right: in std_logic_vector(0 to C_PCM_DATA_WIDTH-1);
    PCM_Playback_Left_Valid: in std_logic;
    PCM_Playback_Right_Valid: in std_logic;
    PCM_Playback_Left_Accept: out std_logic;
    PCM_Playback_Right_Accept: out std_logic;

    -- Record signal interface
    PCM_Record_Left: out std_logic_vector(0 to C_PCM_DATA_WIDTH-1);
    PCM_Record_Right: out std_logic_vector(0 to C_PCM_DATA_WIDTH-1);
    PCM_Record_Left_Valid: out std_logic;
    PCM_Record_Right_Valid: out std_logic;

    DEBUG : out std_logic_vector(0 to 15);
    CODEC_RDY : out std_logic

    );

end component ac97_core;

  component FDCPE
    port(
      Q   : out std_ulogic;
      C   : in  std_ulogic;
      CE  : in  std_ulogic;
      CLR : in  std_ulogic;
      D   : in  std_ulogic;
      PRE : in  std_ulogic
      );
  end component;

  component SRL_FIFO is
    generic (
      C_DATA_BITS : integer;
      C_DEPTH     : integer);
    port (
      Clk         : in  std_logic;
      Reset       : in  std_logic;
      Clear_FIFO  : in  std_logic;
      FIFO_Write  : in  std_logic;
      Data_In     : in  std_logic_vector(0 to C_DATA_BITS-1);
      FIFO_Read   : in  std_logic;
      Data_Out    : out std_logic_vector(0 to C_DATA_BITS-1);
      FIFO_Full   : out std_logic;
      Data_Exists : out std_logic;
      FIFO_Level  : out std_logic_vector(0 to 3);
      Half_Full   : out std_logic;
      Half_Empty  : out std_logic
      );
  end component SRL_FIFO;

  component BRAM_FIFO is
  generic (
    C_DATA_BITS : integer := 32;
    C_ADDR_BITS : integer := 9
    );
  port (
    Clk         : in  std_logic;
    Reset       : in  std_logic;
    Clear_FIFO  : in  std_logic;
    FIFO_Write  : in  std_logic;
    Data_In     : in  std_logic_vector(0 to C_DATA_BITS-1);
    FIFO_Read   : in  std_logic;
    Data_Out    : out std_logic_vector(0 to C_DATA_BITS-1);
    FIFO_Level  : out std_logic_vector(0 to C_ADDR_BITS);
    Full   : out std_logic;
    HalfFull   : out std_logic;
    HalfEmpty   : out std_logic;
    Overflow    : out std_logic;    
    Underflow   : out std_logic;    
    Empty : out std_logic
    );

  end component BRAM_FIFO;

  --   OUT_FIFO: record data from out fifo (left and right)
  --   IN_FIFO: playback data (left and right)
  --   STATUS: status of FIFOs/AC97
  --   CONTROL: overall controll. clear fifos, interrupts
  --   AC97_READ_ADR: result of AC97 register read
  --   AC97_WRITE_ADR: Value to send for a AC97 write
  --   AC97_CTRL_ADR: write ac97 command
  signal controller_addr               : std_logic_vector(0 to 2);

  -- Register Map
  -- Addr               Read            Write
  -- 0x0                OUT_FIFO        IN_FIFO
  -- 0x4                STATUS          Control
  -- 0x8                AC97_READ       AC97_WRITE
  -- 0xc                  N/A          AC97_CNTRL
  constant IN_FIFO_ADR     : std_logic_vector(0 to 2) := "000";  -- x0000
  constant OUT_FIFO_ADR    : std_logic_vector(0 to 2) := "000";  -- x0000
  constant STATUS_ADR      : std_logic_vector(0 to 2) := "001";  -- x0004
  constant CTRL_ADR        : std_logic_vector(0 to 2) := "001";  -- x0004
  constant AC97_READ_ADR   : std_logic_vector(0 to 2) := "010";  -- x0008
  constant AC97_WRITE_ADR  : std_logic_vector(0 to 2) := "010";  -- x0008
  constant AC97_CTRL_ADR   : std_logic_vector(0 to 2) := "011";  -- x000C
  constant DEBUG_ADR       : std_logic_vector(0 to 2) := "011";  -- x000C

  -- Fifo signals
  signal in_FIFO_Write      : std_logic;
  signal in_FIFO_Read       : std_logic;
  signal in_Data_FIFO       : std_logic_vector(0 to 31);
  signal in_FIFO_Full       : std_logic;
  signal in_Data_Exists     : std_logic;  
  signal in_FIFO_Empty      : std_logic;  
  signal in_FIFO_Half_Full  : std_logic;
  signal in_FIFO_Half_Empty  : std_logic;

  signal out_FIFO_Write      : std_logic;
  signal out_FIFO_Read       : std_logic;
  signal out_Data_Read       : std_logic_vector(0 to 31);
  signal out_Data_FIFO       : std_logic_vector(0 to 31);
  signal out_FIFO_Full       : std_logic;
  signal out_Data_Exists     : std_logic;
  signal out_FIFO_Empty      : std_logic;  
  signal out_FIFO_Half_Empty  : std_logic;
  signal out_FIFO_Half_Full  : std_logic;

  signal out_FIFO_Overrun : std_logic := '0';
  signal in_FIFO_Underrun : std_logic := '0';
  
  signal clear_in_fifo  : std_logic;
  signal clear_out_fifo : std_logic;
  
  signal in_fifo_interrupt_en   : std_logic;
  signal out_fifo_interrupt_en  : std_logic;

  signal status_Reg : std_logic_vector(31 downto 0) := (others => '0');

  signal IpClk_ac97_reg_addr       : std_logic_vector(0 to 6);
  signal IpClk_ac97_Reg_Write_Data : std_logic_vector(0 to 15);
  signal IpClk_ac97_reg_read       : std_logic;

  signal BitClk_codec_rdy, IpClk_codec_rdy : std_logic := '0';
  signal BitClk_ac97_Reg_Read_Data  : std_logic_vector(0 to 15);

  signal IpClk_ac97_reg_access_S : std_logic;

  signal BitClk_ac97_reg_access_St : std_logic_vector(2 downto 0);
  signal BitClk_ac97_reg_access_S : std_logic;
    
  signal BitClk_ac97_reg_read_data_valid : std_logic;

 
  signal in_fifo_level, out_fifo_level : std_logic_vector(0 to 9);
  signal in_srl_fifo_level, out_srl_fifo_level : std_logic_vector(0 to 3);
  
  signal BitClk_ac97_reg_data_valid : std_logic;  -- ignore?
  signal BitClk_record_left_valid,BitClk_record_right_valid : std_logic;
  signal BitClk_playback_left_accept,BitClk_playback_right_accept : std_logic;

  signal BitClk_ac97_reg_read_strobe : std_logic := '0';
  signal BitClk_ac97_reg_write_strobe : std_logic := '0';
  signal BitClk_playback_left_valid,BitClk_playback_right_valid : std_logic;
  signal BitClk_ac97_reg_busy, IpClk_ac97_reg_busy : std_logic := '0';
  signal BitClk_ac97_reg_error, IpClk_ac97_reg_error : std_logic := '0';

  signal IpClk_access_request : std_logic;

  signal IpClk_playback_accept_St : std_logic_vector(1 downto 0);
  signal IpClk_playback_accept_S  : std_logic;
  signal IpClk_record_valid_St :  std_logic_vector(1 downto 0);
  signal IpClk_record_accept_S   : std_logic;
  
  signal ac97_reset_i : std_logic := '0';

  signal register_access_busy : std_logic;
  type register_access_state is (IDLE, ISSUE_ACCESS, PROCESS_ACCESS);
  signal ac97_register_access_sm : register_access_state := IDLE;

  signal debug_i : std_logic_vector(0 to 15);

  signal ac97_core_reset : std_logic;
    
  begin  -- architecture IMP

  ------------------------------------------------------------
  -- IP Interface
  ------------------------------------------------------------

  -- Register address decoding bits
  controller_addr <= Bus2IP_Addr(27 to 29);
  
  -- Output multiplixer for read registers:
  --  status register
  --  AC97 register data
  --  Audio data
  OUT_MUX: process (controller_addr, status_reg, Bitclk_ac97_Reg_Read_Data,
                    out_Data_read) is
  begin
    IP2Bus_Data <= (others => '0');
    case controller_addr is
      when STATUS_ADR =>
        IP2Bus_Data((32-status_reg'length) to 31) <= status_reg;
      when AC97_READ_ADR  =>
        IP2Bus_Data(16 to 31) <= BitClk_ac97_Reg_Read_Data;  -- todo: fix
      when DEBUG_ADR       =>
        IP2Bus_Data(16 to 31) <= debug_i;
      when others          =>
        IP2Bus_Data <= out_Data_Read;
    end case;
  end process OUT_MUX;


  ----------------------------------------------------------------        
  -- FIFO Control
  ----------------------------------------------------------------        
  -- Generating read and write pulses for FIFOs
  in_FIFO_write <= '1' when ( Bus2IP_WrCE = '1'
                              and controller_addr = IN_FIFO_ADR)
                   else '0';

  out_FIFO_read <= '1' when (Bus2IP_RdCE = '1'
                             and controller_addr = OUT_FIFO_ADR)
                   else '0';

  clear_fifo_PROCESS : process (Bus2IP_WrCE, controller_addr,
                                Bus2IP_Data(30 to 31))
  begin
    if Bus2IP_WrCE = '1' and controller_addr = CTRL_ADR then
      clear_in_fifo <= Bus2IP_Data(31);
      clear_out_fifo <= Bus2IP_Data(30);
    else
      clear_in_fifo <= '0';
      clear_out_fifo <= '0';
    end if;
  end process;

  ----------------------------------------------------------------        
  -- Interrupt enable register
  ----------------------------------------------------------------        
  fifo_interrupt_enable_proc : process (Bus2IP_Clk)
  begin
    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
      if Bus2IP_Reset = '1' then
        in_fifo_interrupt_en <= '0';
        out_fifo_interrupt_en <= '0';
      elsif Bus2IP_WrCE = '1' and controller_addr = CTRL_ADR then
        in_fifo_interrupt_en <= Bus2IP_Data(29);
        out_fifo_interrupt_en <= Bus2IP_Data(28);
      end if;
    end if;
  end process fifo_interrupt_enable_proc;    

  ----------------------------------------------------------------        
  -- AC97Reset control register
  ----------------------------------------------------------------        
  ac97_reset_n_PROCESS : process (Bus2IP_Clk)
  begin
    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
      if Bus2IP_Reset = '1' then
        ac97_reset_i <= '1';
      elsif Bus2IP_WrCE = '1' and controller_addr = CTRL_ADR then
        ac97_reset_i <= Bus2IP_Data(27);
      end if;
    end if;
  end process;
  AC97Reset_n <= not ac97_reset_i;

  -- The reset signal to the core & timing module occurs when
  -- the bus is reset or when the AC97 codec is reset
  ac97_core_reset <= ac97_reset_i or Bus2IP_Reset;
  
  -----------------------------------------------------------------------------
  -- Status register
  -----------------------------------------------------------------------------
  FIFO_Error_PROCESS : process (Bus2IP_Clk) is
  begin  -- process AC97_Write_Reg_Data
    if Bus2IP_Clk'event and Bus2IP_Clk='1' then
      if Bus2IP_Reset = '1' then
        out_FIFO_Overrun <= '0';
        in_FIFO_Underrun <= '0';
      else
        if (clear_in_fifo = '1') then
          in_FIFO_Underrun <= '0';
        elsif (in_Data_Exists = '0') and (in_FIFO_Read = '1') then
          in_FIFO_Underrun <= '1';
        end if;
        if (clear_out_fifo = '1') then
          out_FIFO_Overrun <= '0';
        elsif (out_FIFO_Full = '1') and (out_FIFO_Write = '1')
          and (out_FIFO_read = '0') then
          out_FIFO_Overrun <= '1';
        end if;
      end if;
    end if;
  end process;
  


  status_reg(31 downto 22) <= out_fifo_level;
  status_reg(21 downto 12) <= in_fifo_level;

  --status_reg(11 downto 9) <= (others => '0');
  status_reg(10) <= out_fifo_interrupt_en;
  status_reg(9) <= in_fifo_interrupt_en;

  status_reg(8) <= IpClk_ac97_reg_error;
    
  status_reg(7) <= out_FIFO_Overrun;
  status_reg(6) <= in_FIFO_Underrun;
  status_reg(5) <= IpClk_codec_rdy;
  status_reg(4) <= register_access_busy; --IpClk_ac97_reg_busy;
  status_reg(3) <= out_Data_Exists;
  status_reg(2) <= out_fifo_empty;
  status_reg(1) <= in_fifo_empty;
  status_reg(0) <= in_FIFO_Full;

  process (Bus2IP_Clk) is
  begin
    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
      IpClk_codec_rdy <= BitClk_codec_rdy;
      IpClk_ac97_reg_busy <= BitClk_ac97_reg_busy;
      IpClk_ac97_reg_error <= BitClk_ac97_reg_error;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- AC97 Access Register
  -----------------------------------------------------------------------------

  -- The AC97 access register is used to initiate an AC97 register
  -- read or write command. This register holds the AC97 address to
  -- read/write as well as the direction (IpClk_ac97_reg_read).
  AC97_Access_Reg : process (Bus2IP_Clk) is
  begin  -- process AC97_Write_Reg_Data
    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
      if Bus2IP_Reset = '1' then
        IpClk_ac97_reg_addr <= (others => '0');
        IpClk_ac97_reg_read <= '0';
      else
        if Bus2IP_WrCE = '1' and AC97_CTRL_ADR = controller_addr then
          IpClk_ac97_reg_addr <= Bus2IP_Data(25 to 31);
          IpClk_ac97_reg_read <= Bus2IP_Data(24);
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- AC97 Write data register
  -----------------------------------------------------------------------------

  -- AC97 Register Write Data: This register holds the data that is to
  -- be written to the AC97 internal register.
  --
  -- Writing to this register does not cause the actual 
  -- write process to the AC97.  Once this register has been written,
  -- a command must be written to the AC97_Access_Reg to initiate the
  -- actual write.
  AC97_Write_Reg : process (Bus2IP_Clk) is
  begin  -- process AC97_Write_Reg_Data
    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
      if Bus2IP_Reset = '1' then
        IpClk_ac97_reg_write_data <= (others => '0');
      else
        if Bus2IP_WrCE = '1' and controller_addr = AC97_WRITE_ADR then
          IpClk_ac97_reg_write_data <= Bus2IP_Data(16 to 31);
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- AC97 Access initiate one shot
  -----------------------------------------------------------------------------

  -- This one bit signal is asserted when a write occurs to the AC97_CTRL_ADDR.
  -- This is a one-shot signal that is only asserted for one cycle
  -- (Bus2IP_Clk).

  -- This signal will initiate the AC97 register access state machine.
  AC97_Access_S_PROCESS : process (Bus2IP_Clk) is
  begin
    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
      if Bus2IP_WrCE = '1' and controller_addr = AC97_CTRL_ADR then
        IpClk_ac97_reg_access_S <= '1';  -- one shot
      else
        IpClk_ac97_reg_access_S <= '0';
      end if;
    end if;
  end process;

  -- busy signal
  process (Bus2IP_Clk) is
  begin

    if Bus2IP_Reset = '1' then
      ac97_register_access_sm <= IDLE;

    elsif Bus2IP_Clk'event and Bus2IP_Clk='1' then

      case ac97_register_access_sm is

        when IDLE =>
          if IpClk_ac97_reg_access_S = '1' then
            ac97_register_access_sm <= ISSUE_ACCESS;
          end if;
          
        when ISSUE_ACCESS =>
          -- TODO: add time out in case the codec is not hooked up
          if IpClk_ac97_reg_busy = '1' then
            ac97_register_access_sm <= PROCESS_ACCESS;
          end if;

        when PROCESS_ACCESS =>
          if IpClk_ac97_reg_busy = '0' then
            ac97_register_access_sm <= IDLE;
          end if;
          
      end case;
      
    end if;
  end process;
  register_access_busy <= '1' when (ac97_register_access_sm = ISSUE_ACCESS  or
                                    ac97_register_access_sm = PROCESS_ACCESS)
                          else '0';
  
  -----------------------------------------------------------------------------
  -- Clock crossing signals
  -----------------------------------------------------------------------------

  -- convert the one cycle strobe in the IpClk domain to
  -- the BitClk domain.
  fdcpe_1 : FDCPE
    port map (
      Q   => IpClk_access_request,
      C   => '0',
      CE  => '0',
      CLR => BitClk_ac97_reg_access_S,
      D   => '0',
      PRE => IpClk_ac97_reg_access_S
      );

  process (Bit_Clk) is
  begin
    if Bit_Clk'event and Bit_Clk='1' then
      BitClk_ac97_reg_access_St(0) <= IpClk_access_request;
      BitClk_ac97_reg_access_St(1) <= BitClk_ac97_reg_access_St(0);
      BitClk_ac97_reg_access_S <= BitClk_ac97_reg_access_St(0) and
                              (not BitClk_ac97_reg_access_St(1));
    end if;
  end process;
  BitClk_ac97_reg_read_strobe <= BitClk_ac97_reg_access_S and
                                 IpClk_ac97_reg_read;
  BitClk_ac97_reg_write_strobe <= BitClk_ac97_reg_access_S and
                                  (not IpClk_ac97_reg_read);
  

  BitClk_playback_left_valid <= '1';
  BitClk_playback_right_valid <= '1';

  -----------------------------------------------------------------------------
  -- Fifo Control Signals (asynchronous clock transfer)
  --
  -----------------------------------------------------------------------------

  -- BitClk is slower than IpClk.
  process (Bus2IP_Clk) is
  begin
    if Bus2IP_Clk'event and Bus2IP_clk='1' then
      IpClk_playback_accept_St(0) <= BitClk_playback_left_accept;
      IpClk_playback_accept_St(1) <= IpClk_playback_accept_St(0);
    end if;
    IpClk_playback_accept_S <= IpClk_playback_accept_St(0) and
                               (not IpClk_playback_accept_St(1));
  end process;

  process (Bus2IP_Clk) is
  begin
    if Bus2IP_Clk'event and Bus2IP_clk='1' then
      IpClk_record_valid_St(0) <= BitClk_record_left_valid;
      IpClk_record_valid_St(1) <= IpClk_record_valid_St(0);
    end if;
  end process;
  IpClk_record_accept_S <= IpClk_record_valid_St(0) and
                           (not IpClk_record_valid_St(1));

  in_FIFO_Read <= IpClk_playback_accept_S;
  out_FIFO_Write <= IpClk_record_accept_S;

  -----------------------------------------------------------------------------
  -- IN_FIFO
  --
  -- This fifo receives data directly from the OPB bus and performs a "fifo
  -- write" for each OPB write to the FIFO. The FIFO sends data directly to the
  -- AC97 core and performs a "fifo read" every time a new AC97 frame is sent.
  -- 
  -----------------------------------------------------------------------------

  Using_Playback_SRL : if (C_PLAYBACK = 1 and C_USE_BRAM = 0) generate
     
    IN_FIFO : SRL_FIFO
      generic map (
        C_DATA_BITS => 32,              -- Left and Right channel
        C_DEPTH     => 16)    
      port map (
         Clk         => Bus2IP_Clk,        
         Reset       => Bus2IP_Reset,        
         Clear_FIFO  => clear_in_fifo, 
         FIFO_Write  => in_FIFO_Write, 
         Data_In     => Bus2IP_Data,
         FIFO_Read   => in_FIFO_Read,
         Data_Out    => in_Data_FIFO,
         FIFO_Full   => in_FIFO_Full,
         Data_Exists => in_Data_Exists,
         FIFO_Level  => in_srl_fifo_level,
         Half_Full   => in_FIFO_Half_Full,
         Half_Empty  => in_FIFO_Half_Empty);

    in_fifo_level <= "000000" & in_srl_fifo_level;
    in_FIFO_Empty <= not in_Data_Exists;
  end generate Using_Playback_SRL;

  Using_Playback_BRAM : if (C_PLAYBACK = 1 and C_USE_BRAM = 1) generate
     
    IN_FIFO : BRAM_FIFO
      port map (
         Clk         => Bus2IP_Clk,        
         Reset       => Bus2IP_Reset,        
         Clear_FIFO  => clear_in_fifo, 
         FIFO_Write  => in_FIFO_Write, 
         Data_In     => Bus2IP_Data,
         FIFO_Read   => in_FIFO_Read,
         Data_Out    => in_Data_FIFO,
         FIFO_Level  => in_fifo_level,
         FULL   => in_FIFO_Full,
         HalfFull   => in_FIFO_HALF_FULL,
         HalfEmpty  => in_FIFO_Half_Empty,
         Overflow  => open,
         Underflow => open,
         Empty  => in_FIFO_Empty
         );
    in_Data_Exists <= not in_FIFO_Empty;
   end generate Using_Playback_BRAM;
    
  No_Playback : if (C_PLAYBACK = 0) generate
    in_Data_FIFO   <= (others => '0');
    in_FIFO_Full   <= '0';
    in_Data_Exists <= '0';
    in_FIFO_Empty <= '0';
    in_fifo_level <= (others => '0');
    out_fifo_level <= (others => '0');
  end generate No_Playback;

  -----------------------------------------------------------------------------
  -- OUT_FIFO
  --
  -- This fifo receives data directly from the AC97 and performs a "fifo
  -- write" for each AC97 frame. The FIFO sends data directly to the
  -- OPB Bus core and performs a "fifo read" every time data is read from the
  -- FIFO over the OPB bus.
  -- 
  -----------------------------------------------------------------------------
  Using_Recording_SRL : if (C_RECORD = 1 and C_USE_BRAM = 0) generate

    OUT_FIFO : SRL_FIFO
      generic map (
        C_DATA_BITS => 32,              -- [integer]
        C_DEPTH     => 16)              -- [integer]
      port map (
        Clk         => Bus2IP_Clk,         -- [in  std_logic]
        Reset       => Bus2IP_Reset,         -- [in  std_logic]
        Clear_FIFO  => clear_out_fifo,  -- [in  std_logic]
        FIFO_Write  => out_FIFO_Write,  -- [in  std_logic]
        Data_In     => out_Data_FIFO,
        FIFO_Read   => out_FIFO_Read,   -- [in  std_logic]
        Data_Out    => out_Data_Read,  -- [out std_logic_vector(0 to C_OPB_DWIDTH-1)]
        FIFO_Full   => out_FIFO_Full,   -- [out std_logic]
        Data_Exists => out_Data_Exists,       -- [out std_logic]
        FIFO_Level  => out_srl_fifo_level,
        Half_Full   => out_FIFO_Half_Full,    -- [out std_logic]
        Half_Empty  => open);  -- [out std_logic]

     out_fifo_level <= "000000" & out_srl_fifo_level;
     out_fifo_empty <= not out_Data_exists;
  end generate Using_Recording_SRL;

  Using_Recording_BRAM : if (C_RECORD = 1 and C_USE_BRAM = 1) generate

    OUT_FIFO : BRAM_FIFO
      port map (
         Clk         => Bus2IP_Clk,        
         Reset       => Bus2IP_Reset,        
         Clear_FIFO  => clear_out_fifo, 
         FIFO_Write  => out_FIFO_Write,
         Data_In     => out_Data_FIFO,
         FIFO_Read   => out_FIFO_Read,
         Data_Out    => out_Data_Read,
         FIFO_Level  => out_fifo_level,
         FULL   => out_FIFO_Full,
         HalfFull   => out_FIFO_HALF_FULL,
         HalfEmpty   => out_FIFO_HALF_Empty,
         Overflow => open,
         Underflow => open,
         Empty  => out_FIFO_Empty);  -- [out std_logic]

    out_Data_Exists <= not out_FIFO_Empty;
    
  end generate Using_Recording_BRAM;
  
  No_Recording : if (C_RECORD = 0) generate
    out_Data_Read   <= (others => '0');
    out_FIFO_Full   <= '0';
    out_Data_Exists <= '0';
  end generate No_Recording;

  
  -----------------------------------------------------------------------------
  -- Instanciating the core
  -----------------------------------------------------------------------------
  ac97_core_I : ac97_core 
  port map (

      Reset => ac97_core_reset,

      AC97_Bit_Clk => Bit_Clk,
      AC97_Sync => Sync,
      AC97_SData_Out => SData_Out,
      AC97_SData_In => SData_In,

      AC97_Reg_Addr                => IpClk_ac97_reg_addr,  -- async
      AC97_Reg_Write_Data          => IpClk_ac97_reg_write_data,  -- async
      AC97_Reg_Read_Data           => BitClk_ac97_Reg_Read_Data,
      AC97_Reg_Read_Strobe         => BitClk_ac97_reg_read_strobe,
      AC97_Reg_Write_Strobe        => BitClk_ac97_reg_write_strobe,
      AC97_Reg_Busy                => BitClk_ac97_reg_busy,
      AC97_Reg_Error               => BitClk_ac97_reg_error,
      AC97_Reg_Read_Data_Valid     => BitClk_ac97_reg_data_valid,
    
      PCM_Playback_Left            => in_Data_Fifo(16 to 31),
      PCM_Playback_Right           => in_Data_Fifo(0 to 15),
      PCM_Playback_Left_Valid      => BitClk_playback_left_valid,
      PCM_Playback_Right_Valid     => BitClk_playback_right_valid,
      PCM_Playback_Left_Accept     => BitClk_playback_left_accept,
      PCM_Playback_Right_Accept    => BitClk_playback_right_accept,

      PCM_Record_Left              => out_Data_Fifo(16 to 31),
      PCM_Record_Right             => out_Data_Fifo(0 to 15),
      PCM_Record_Left_Valid        => BitClk_record_left_valid,
      PCM_Record_Right_Valid       => BitClk_record_right_valid,

      DEBUG => debug_i,
      
      CODEC_RDY  => BitClk_codec_rdy

    );

                         
  -----------------------------------------------------------------------------
  -- Handling the interrupts
  -----------------------------------------------------------------------------
  Interrupt_Handle: process (in_FIFO_Half_Full, 
                              in_FIFO_Full, In_Data_Exists,
                              in_fifo_interrupt_en,
                              out_FIFO_Half_Full, out_FIFO_Half_Empty,
                              out_FIFO_Full, out_Data_Exists,
                              out_fifo_interrupt_en
                              ) is
   begin  -- process Playback_Interrupt_Handle
     if (C_INTR_LEVEL = 1) then
       Interrupt <=  (in_fifo_interrupt_en and in_FIFO_Half_Empty) or
                     (out_fifo_interrupt_en and out_FIFO_Half_Full);
     elsif (C_INTR_LEVEL = 2) then
       Interrupt <=  (in_fifo_interrupt_en and in_FIFO_Full) or
                     (out_fifo_interrupt_en and out_FIFO_Empty);
     elsif (C_INTR_LEVEL = 3) then
       Interrupt <=  (in_fifo_interrupt_en and in_FIFO_Half_Full) or
                     (out_fifo_interrupt_en and out_Fifo_Half_Empty);
       -- TODO: implement level 3
     else
       Interrupt <= '0';
     end if;
   end process Interrupt_Handle;
  
end architecture IMP;
