library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

library opb_ac97_v2_00_a;
use opb_ac97_v2_00_a.all;
use opb_ac97_v2_00_a.testbench_ac97_package.all;

entity testbench_opb_ac97 is
end testbench_opb_ac97;

architecture behavioral of testbench_opb_ac97 is

  component opb_ac97
  generic (
    C_OPB_AWIDTH      : integer                   := 32;
    C_OPB_DWIDTH      : integer                   := 32;
    C_BASEADDR        : std_logic_vector(0 to 31) := X"FFFF_8000";
    C_HIGHADDR        : std_logic_vector          := X"FFFF_80FF";
    C_PLAYBACK        : integer                   := 1;
    C_RECORD          : integer                   := 0;
    C_INTR_LEVEL : integer  := 1;
    C_USE_BRAM : integer  := 1
    );
  port (
    -- Global signals
    OPB_Clk : in std_logic;
    OPB_Rst : in std_logic;

    -- OPB signals
    OPB_ABus     : in  std_logic_vector(0 to C_OPB_AWIDTH-1);
    OPB_BE       : in  std_logic_vector(0 to C_OPB_DWIDTH/8-1);
    OPB_DBus     : in  std_logic_vector(0 to C_OPB_DWIDTH-1);
    OPB_RNW      : in  std_logic;
    OPB_select   : in  std_logic;
    OPB_seqAddr  : in  std_logic;

    Sln_DBus     : out std_logic_vector(0 to C_OPB_DWIDTH-1);
    Sln_errAck   : out std_logic;
    Sln_retry    : out std_logic;
    Sln_toutSup  : out std_logic;
    Sln_xferAck  : out std_logic;
    --Sl_Interrupt : out std_logic;

    -- CODEC signals
    Bit_Clk   : in  std_logic;
    Sync      : out std_logic;
    SData_Out : out std_logic;
    SData_In  : in  std_logic;
    AC97Reset_n : out std_logic

    );

  end component;

  component ac97_model is
  port (
    AC97Reset_n   : in  std_logic;         
    Bit_Clk   : out  std_logic;
    Sync      : in std_logic;
    SData_Out : in std_logic;
    SData_In  : out  std_logic
    );
  end component;

  signal OPB_Clk :std_logic;
  signal OPB_Rst :std_logic;

    -- OPB signals
  signal OPB_ABus :std_logic_vector(0 to 31);
  signal OPB_BE :std_logic_vector(0 to 3);
  signal OPB_RNW :std_logic;
  signal OPB_select :std_logic;
  signal OPB_seqAddr :std_logic;
  signal OPB_DBus :std_logic_vector(0 to 31);

  signal Sln_DBus :std_logic_vector(0 to 31);
  signal Sln_errAck :std_logic;
  signal Sln_retry :std_logic;
  signal Sln_toutSup :std_logic;
  signal Sln_xferAck :std_logic;

  -- Interrupt signals
  signal Interrupt :std_logic;

  -- CODEC signals
  signal Bit_Clk :std_logic;
  signal Sync :std_logic;
  signal SData_Out :std_logic;
  signal SData_In :std_logic;
  signal AC97Reset_n :std_logic;

  -- bus register
  signal opb_read_value : std_logic_vector(0 to 31) := X"0000_0000";
  signal test_number : integer := 0;

  -- Constants
  constant STATUS_ADDR : std_logic_vector(0 to 31) := X"FFFF_8004";
  constant CONTROL_ADDR : std_logic_vector(0 to 31) := X"FFFF_8004";

  constant FIFO_IN_ADDR : std_logic_vector(0 to 31) := X"FFFF_8000";
  constant FIFO_OUT_ADDR : std_logic_vector(0 to 31) := X"FFFF_8000";

  constant AC97_REGCTRL_ADDR : std_logic_vector(0 to 31) := X"FFFF_800C";
  constant AC97_REG_READ : std_logic_vector(0 to 31) := X"FFFF_8008";
  constant AC97_REG_WRITE : std_logic_vector(0 to 31) := X"FFFF_8008";

begin  -- behavioral

  uut: opb_ac97
  generic map (
    C_RECORD => 1
  )
  port map (
    -- Global signals
    OPB_Clk => OPB_Clk,
    OPB_Rst => OPB_Rst,

    -- OPB signals
    OPB_ABus => OPB_ABus,
    OPB_BE => OPB_BE,
    OPB_RNW => OPB_RNW,
    OPB_select => OPB_select,
    OPB_seqAddr => OPB_seqAddr,
    OPB_DBus => OPB_DBus,

    Sln_DBus => Sln_DBus,
    Sln_errAck => Sln_errAck,
    Sln_retry => Sln_retry,
    Sln_toutSup => Sln_toutSup,
    Sln_xferAck => Sln_xferAck,

    -- Interrupt signals
    --Sl_Interrupt => Interrupt,

    -- CODEC signals
    Bit_Clk => Bit_Clk,
    Sync => Sync,
    SData_Out => SData_Out,
    SData_In => SData_In,
    AC97Reset_n => AC97Reset_n
    );

  uut_1 : ac97_model
  port map (
    AC97Reset_n => ac97reset_n,
    Bit_Clk => Bit_Clk,
    Sync => Sync,
    SData_Out => SData_Out,
    SData_In => SData_In
    );

  -- simulate a reset
  opb_rst_gen: process
    begin
      OPB_Rst <= '1';
      wait for 20 ns;
      OPB_Rst <= '0'; 
      wait;
   end process opb_rst_gen;

  -- simulate a 50 MHz OPB clk
  opb_clk_gen: process
    begin
      OPB_Clk <= '0';
      wait for 10 ns;
      OPB_Clk <= '1'; 
      wait for 10 ns;
   end process opb_clk_gen;

  -- Bus register
  bus_read_register : process (opb_clk,OPB_RNW)
  begin
    if (OPB_Clk'event and OPB_Clk='1' and OPB_RNW='1' and OPB_select='1') then
      opb_read_value <= sln_dbus;
    end if;
  end process bus_read_register;
  
  -- OPB Bus transactions
  opb_bus_drive: process
    variable data_value : unsigned (0 to 31);
  begin
    OPB_select <= '0';
    OPB_RNW <= '0';
    OPB_ABus <= X"0000_0000";
    OPB_DBus <= X"0000_0000";

    -- skip a frame & some time slots before performing a bus cycle 
    delay(OPB_clk, 20);
     
    -------------------------------------------------------
    -- Test #8: Reset CODEC
    -------------------------------------------------------
    test_number <= 8;
    write_opb(opb_clk, Sln_xferAck,
              CONTROL_ADDR,X"0000_0010", OPB_select, OPB_RNW,
              OPB_ABus, OPB_DBus);
    delay(OPB_clk, 20);
    write_opb(opb_clk, Sln_xferAck,
              CONTROL_ADDR,X"0000_0000", OPB_select, OPB_RNW,
              OPB_ABus, OPB_DBus);

    -------------------------------------------------------
    -- Test 9. Wait until codec ready is found (ready status)
    -------------------------------------------------------
    test_number <= 9;
    while opb_read_value(26) /= '1' loop
    read_opb(opb_clk, Sln_xferAck,
             STATUS_ADDR, OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);
    end loop;

    -------------------------------------------------------
    -- Test #1: Read Status
    -------------------------------------------------------
    test_number <= 1;
    read_opb(opb_clk, Sln_xferAck,
              STATUS_ADDR, OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);
    -- 006A000:
    --  in_FIFO NOT full
    --  in FIFO NOT empty
    --  out_FIFO NOT empty
    --  out_FIFO data exists
    --  NOT register_Access_Finished
    --  codec_rdy
    --  in_FIFO_Underrun
    --  not out_FIFO_underrun
    delay(OPB_clk, 32);
    
    -------------------------------------------------------
    -- Test #2: Clear FIFO status & read status again
    -------------------------------------------------------
    test_number <= 2;
    write_opb(opb_clk, Sln_xferAck, CONTROL_ADDR,X"0000_0003",
              OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);
    read_opb(opb_clk, Sln_xferAck,
              STATUS_ADDR, OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);
    -- 0026000:
    --  in_FIFO NOT full
    --  in FIFO empty
    --  out_FIFO empty
    --  NOT out_FIFO data exists
    --  NOT register_Access_Finished
    --  codec_rdy
    --  NOT in_FIFO_Underrun
    --  NOT out_FIFO_underrun


    -------------------------------------------------------
    -- Test #3: Playback data
    -------------------------------------------------------
    -- Write to data fifo (playback data) & check status
    -- 1. Check to see if Sdata_out has appropriate signals (one package per frame)
    test_number <= 3;
    delay(OPB_clk, 32);
    write_opb(opb_clk, Sln_xferAck,FIFO_IN_ADDR,X"8001_8001",
            OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);
    write_opb(opb_clk, Sln_xferAck,FIFO_IN_ADDR,X"AAAA_5555",
            OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);
    write_opb(opb_clk, Sln_xferAck,FIFO_IN_ADDR,X"2004_2004",
            OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);
    write_opb(opb_clk, Sln_xferAck,FIFO_IN_ADDR,X"1008_1008",
            OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);
    read_opb(opb_clk, Sln_xferAck,
              STATUS_ADDR, OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);
    
    -- 0025000:
    --  in_FIFO full
    --  in FIFO NOT empty
    --  out_FIFO empty
    --  NOT out_FIFO data exists
    --  NOT register_Access_Finished
    --  codec_rdy
    --  NOT in_FIFO_Underrun
    --  NOT out_FIFO_underrun

    -------------------------------------------------------
    -- Test #4: Perform a AC97 "read"
    -------------------------------------------------------

    test_number <= 4;
    delay(OPB_clk, 256);

    -- Write to AC97_CTRL_ADDR (perform a AC97 "read")
    -- Address = "41" (lower 7 bits)
    -- Read = 1 "0b1xxx xxxx"
    write_opb(opb_clk, Sln_xferAck,AC97_REGCTRL_ADDR,X"0000_00C1",
              OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);

    -- Poll until read is complete
    -- read from the status register until transfer is complete
    read_opb(opb_clk, Sln_xferAck,
              STATUS_ADDR, OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);
    while opb_read_value(27) = '0' loop
      -- read from the status register until transfer is complete
      read_opb(opb_clk, Sln_xferAck,
               STATUS_ADDR, OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);
    end loop;
    -- Now read the value of the data register returned
    read_opb(opb_clk, Sln_xferAck, AC97_REG_READ,
           OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);

    delay(OPB_clk, 128);

    -------------------------------------------------------
    -- Test #5: Perform a AC97 "write"
    -------------------------------------------------------

    -- Write data that will be sent to AC97
    test_number <= 5;
    write_opb(opb_clk, Sln_xferAck,AC97_REG_WRITE,X"0000_8001",
              OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);

    -- Write to AC97_CTRL_ADDR (perform a AC97 "read")
    -- Address = "41" (lower 7 bits)
    -- Read = 0 "0b1xxx xxxx"
    write_opb(opb_clk, Sln_xferAck,AC97_REGCTRL_ADDR,X"0000_0041",
              OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);

    -- Poll until write is complete
    read_opb(opb_clk, Sln_xferAck,
              STATUS_ADDR, OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);
    while opb_read_value(27) = '0' loop
      -- read from the status register until transfer is complete
      read_opb(opb_clk, Sln_xferAck,
               STATUS_ADDR, OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);
    end loop;
    

    -------------------------------------------------------
    -- Fill FIFO (#6)
    -------------------------------------------------------
    test_number <= 6;

    -- Clear fifo and start over
    write_opb(opb_clk, Sln_xferAck, CONTROL_ADDR,X"0000_0003",
              OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);

    -- Read status and write data until fifo is full
    read_opb(opb_clk, Sln_xferAck,
             STATUS_ADDR, OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);
    data_value := (others => '0');
    while opb_read_value(31) = '0' loop  -- in not full

      write_opb(opb_clk, Sln_xferAck,
                FIFO_IN_ADDR,
                CONV_STD_LOGIC_VECTOR(data_value,data_value'length),
                OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);

      -- read from the status register until transfer is complete
      read_opb(opb_clk, Sln_xferAck,
               STATUS_ADDR, OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);

      data_value := data_value + 1;
    end loop;

    -------------------------------------------------------
    -- test #13 - Wait until fifo is empty (a long time!)
    -- Make sure each sample is "played"
    -------------------------------------------------------
    test_number <= 13;

--     -- Read status and write data until fifo is empty
--     read_opb(opb_clk, Sln_xferAck,
--              STATUS_ADDR, OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);
--     data_value := (others => '0');
--     while opb_read_value(30) = '0' loop  -- in not empty

--       -- read from the status register until transfer is complete
--       read_opb(opb_clk, Sln_xferAck,
--                STATUS_ADDR, OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);

--       delay(OPB_clk, 256);
      
--     end loop;

    -------------------------------------------------------
    -- test #12 - Wait until fifo loses a slot and send another item
    -------------------------------------------------------
    test_number <= 12;

    -- Read status and write data until fifo is full
    read_opb(opb_clk, Sln_xferAck,
             STATUS_ADDR, OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);
    while opb_read_value(31) = '1' loop  -- in full

      -- read from the status register until transfer is complete
      read_opb(opb_clk, Sln_xferAck,
               STATUS_ADDR, OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);

    end loop;         

    -- Now that buffer isn't full, put an item in it (is it now full?)
    write_opb(opb_clk, Sln_xferAck,
            FIFO_IN_ADDR,CONV_STD_LOGIC_VECTOR(data_value,data_value'length),
              OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);

    -------------------------------------------------------
    -- test #11 - get recorded data
    -------------------------------------------------------
    delay(OPB_clk, 64);
    test_number <= 10;

    -- Wait until there is data in out buffer (should be there)
    read_opb(opb_clk, Sln_xferAck,
             STATUS_ADDR, OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);
    while opb_read_value(29) = '0' loop  -- while out buffer not empty

      -- Read data from bus
      read_opb(opb_clk, Sln_xferAck,
               FIFO_OUT_ADDR, OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);

      -- read from the status register until transfer is complete
      read_opb(opb_clk, Sln_xferAck,
               STATUS_ADDR, OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);
    end loop;


    -------------------------------------------------------
    -- Test #7: Interrupts
    -------------------------------------------------------
    test_number <= 7;
    delay(OPB_clk, 128);

    -- Enable Interrupts (don't clear fifo)
    write_opb(opb_clk, Sln_xferAck,
              X"FFFF_800C",X"0000_000C", OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);

    -- Wait for interrupt
    wait until Interrupt = '1';
    -- Clear interrupt by putting data back into fifo
    write_opb(opb_clk, Sln_xferAck,
              FIFO_IN_ADDR,X"1234_5678", OPB_select, OPB_RNW, OPB_ABus, OPB_DBus);

    
    test_number <= 0;
    wait;
    
    
  end process opb_bus_drive;
  
  
end behavioral;
