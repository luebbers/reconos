-------------------------------------------------------------------------------
-- Title      : 1-Wire Master
-- Project    : 
-------------------------------------------------------------------------------
-- File       : onewire_master.vhd
-- Author     : Davy Huang <Dai.Huang@Xilinx.com>
-- Company    : Xilinx, Inc.
-- Created    : 2001/01/31
-- Last Update: 2001-04-18
-- Copyright  : (c) Xilinx Inc, 2001
-------------------------------------------------------------------------------
-- Uses       : SHReg, BitReg, ByteReg, CRCReg, JCounter
-------------------------------------------------------------------------------
-- Used by    : 1-Wire Interface
-------------------------------------------------------------------------------
-- Description: This is the master module to drive the Serial Number Device.
--
--              When communicate with the Serial Number Device, this module
--              works as the master, while the Serial Number Device works as
--              slave. For more information about the Serial Number Device,
--              please refer to the datasheet at:
--              http://www.dalsemi.com/datasheets/pdfs/2401.pdf
--
--              This module has been verified to work with Dallas DS2401 
--              Silicon Serial Number Device and DS2430A EEPROM.
--
--              The function provided by this master module include:
--              (1) Send "Reset Pulse" to the Serial Number Device to reset it
--              (2) Detect "Presence Pulse" from the Serial Number Device
--              (3) Control data flow on the bidirectional one-wire bus which
--                  connects the Serial Number Device and this master module
--                  through one-wire.
--              (4) Read in the 8 bytes of data from the Serial Number Device
--                  which include the family code (x01), the serial number
--                  (6 bytes), and the CRC value (1 byte)
--              (5) Output the data to the data bus (data) as individual
--                  bytes (total 8 bytes) with a data enable signal
--                  (data_valid)  as the strobe signal.
--                  The data bytes follow the sequence:
--                      1. Family Code:    (e.g. 0x01 for DS2401 device)
--                      2. Serial Number (Byte 0) 
--                      3. Serial Number (Byte 1) 
--                      4. Serial Number (Byte 2) 
--                      5. Serial Number (Byte 3) 
--                      6. Serial Number (Byte 4) 
--                      7. Serial Number (Byte 5) 
--                      8. CRC Value 
--              (6) (optional) Calculate CRC and match it with the CRC value
--                  received from the device.
--              (7) Assert CRC OK if [a] all the bytes has been received and
--                  sent out to the data bus, and [b] CRC values are
--                  matched ([b] is optional).
--              (8) Output the 48 bits serial number at the parallel port
--                  (sn_data)
--
--              This module needs an 1MHz (1us period) clock input.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2001/01/31  1.0      Davy    Create the initial design
-- 2001/02/07  1.1      Davy    First release
-- 2001/02/08  1.2      Davy    Clearify/revise the comments
-- 2001/02/16  1.3      Davy    Remove one clock input, optimize design
-- 2001/02/23  1.3      Davy    Change name to onewire_master
-- 2001/03/06  1.3      Davy    Fix the timing spec err in INIT state
-- 2001/03/15  1.4      Davy    Change crc_ok to make it happen earlier, then
--                              use crc_ok to lead FSM back to INIT if CRC
--                              fails; Add parallel output
-- 2001/04/12  1.5      Davy    (1)detect pull-up in RX_PRE_PLS
--                              (2)use register instead of latch for din_pp
--                              (3)use register instead of latch for crcok_i
--                              (4)register the data_valid signal
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- synthesis translate_off
-- synopsys translate_off
library unisim;
use unisim.vcomponents.all;
-- synopsys translate_on
-- synthesis translate_on

entity onewire_master is
    generic (CheckCRC : boolean := true);         -- turn on crc check circuit
                                                  -- if it's true; otherwise
                                                  -- the crc circuit will be
                                                  -- removed to save registers
                                                  
    port (
           clk_1MHz  : in  std_logic;             -- clock (typical 1 MHz)
                                                  
           reset     : in  std_logic;             -- reset this circuit,
  
           dq        : inout std_logic;           -- connect to external
                                                  -- one-wire bus.
                                                  -- A pullup resistor must be
                                                  -- attached to this wire
                                                  -- either externally or
                                                  -- internally.
                                                  
           
           data      : out std_logic_vector(7 downto 0); 
                                                  -- data output
                                                  -- A byte of data will be
                                                  -- available on this data bus
                                                  -- when data_valid is
                                                  -- asserted.
           
           data_valid: out std_logic;             -- data enable strobe,
                                                  -- indicates a byte of valid
                                                  -- data (20us pulse)
                                                  
           crcok     : out std_logic;             -- if CheckCRC = true, crcok
                                                  -- will give the result of
                                                  -- crc verification;
                                                  -- otherwise it will be
                                                  -- forced to '1' when all the
                                                  -- data have been received.
                                                  
           sn_data   : out std_logic_vector (47 downto 0)
                                                  -- The parallel output of the
                                                  -- serial number. If crcok
                                                  -- is active, sn_data will be
                                                  -- valid 48bits serial number
                                                  
              );
end onewire_master;

architecture rtl of onewire_master is

  ----------------------------------------------------------------------------
  -- Components Declaration
  ----------------------------------------------------------------------------

  component IOBUF  -- I/O Bidirectional buffer (T=0 : I=>IO; T=1: IO=>O)
    port (
               I : in std_logic;
               T : in std_logic;
              IO : inout std_logic;
               O : out std_logic);
  end component;  

  component SHReg  -- Parameterisable Shift Register
   generic (
          width  : natural;
        AsynReset: boolean;
        circular : boolean);
    port (
           reset : in  std_logic; -- synchronous reset
           clk   : in  std_logic;
           en    : in  std_logic;
           q     : out std_logic_vector((width - 1) downto 0) );
  end component;
 
  component BitReg  -- Parameterisable Bit Register
    generic ( numBits : integer);
  port (
           clk   : in  std_logic;
           reset : in  std_logic; -- asynchronous reset
           din   : in  std_logic; 
           en    : in  std_logic_vector((numBits - 1) downto 0);
           dout  : out std_logic_vector((numBits - 1) downto 0));
  end component;  
 
  component ByteReg  -- Parameterisable Byte Register
     generic ( numBytes : integer);
   port (
            clk   : in  std_logic;
            reset : in  std_logic; -- asynchronous reset
            din   : in  std_logic_vector(7 downto 0); 
            en    : in  std_logic_vector((numBytes - 1) downto 0);
            dout  : out std_logic_vector((numBytes * 8 -1) downto 0));
  end component;  
 
  component JCounter -- Parameterisable Johnson Counter 
   generic (
           width : natural;
        AsynReset: boolean);  -- use asynchronous reset if true
   port (  
           reset : in std_logic; 
             clk : in std_logic;
              en : in std_logic;
               q : out std_logic_vector((width - 1) downto 0));
  end component;

  component CRCReg --  Parameterisable CRC Shift Register 
    generic (
           width : natural;         
       feedback1 : natural;
       feedback2 : natural);  
    port (
           reset : in std_logic; -- asynchronous reset
             clk : in std_logic;           
              en : in std_logic;            
              d  : in std_logic;            
               q : out std_logic_vector((width - 1) downto 0));  
  end component;
 
  ----------------------------------------------------------------------------
  -- Signals Declaration
  ----------------------------------------------------------------------------
 
  -- FSM States
  type FSMState is (INIT, TX_RST_PLS, RX_PRE_PLS, TX_RD_CMD,
                    RX_DATA, IDLE);


  -- The state variables for the fsm
  signal thisState, nextState : FSMState;

  -- constant to issue Read ROM Command for DS2401 Serial Number Device
  -- which is either 0x33h (for both DS2401 and DS2430A)
  -- or 0x0Fh (for DS2401 only).
  constant ReadROMCmd       :  std_logic_vector(7 downto 0) := "00110011";


  -- command data bit to transmit
  signal tx_cmd_bit    : std_logic;

  -- internal generated clock (50KHz)
  signal clk_50KHz   : std_logic;
  
  -- time slot identification signals
  signal ts_60_to_80us  : std_logic;
  signal ts_0_to_10us   : std_logic;
  signal ts_0_to_1us    : std_logic;
  signal ts_14_to_15us  : std_logic;

  -- signals for shift register 1 (SR1)
  signal sr1_reset : std_logic;
  signal sr1_en    : std_logic;
  signal sr1_q     : std_logic_vector (7 downto 0);

  -- signals for shift register 2 (SR2)
  signal sr2_reset : std_logic;
  signal sr2_en    : std_logic;
  signal sr2_q     : std_logic_vector (7 downto 0);

  -- signals for Johnson counter 1(JC1)
  signal jc1_reset : std_logic;
  signal jc1_q     : std_logic_vector (1 downto 0);
    
  -- signals for Johnson counter 2(JC2)
  signal jc2_q     : std_logic_vector (9 downto 0);
    
  
  -- signals for the bidirectional data I/O buffer and data path
  signal din        : std_logic;  -- data from one-wire bus
  signal dout       : std_logic;  -- data to one-wire bus
  signal d_ctrl     : std_logic;  -- 0: dout=>dq (write to the bus)
                                  -- 1: din<=dq (read from the bus)
  signal din_pp     : std_logic;  -- data of presence pulse 
                                  -- it'll be 0 if presence pulse is detected.
  
  -- signals for bit register (BitReg)
  signal bitreg_en : std_logic_vector(7 downto 0); -- enable signal to load
                                  -- one bit of data into the register
  
  -- signals for byte register (ByteReg)
  signal bytereg_en : std_logic_vector(5 downto 0); -- enable signal to load
                                  -- one byte of data into the register
  
  -- several data valid signals
  signal databit_valid: std_logic;-- databit_valid signal generated from sr1
                                  -- (which identifies states), it's
                                  -- 1us pulse. It indicates
                                  -- the valid data received from the 
                                  -- Serial Number Device, excludes
                                  -- the Presence Pulse.
                                  

  signal databyte_valid: std_logic;
                                  -- valid signal for receiving a byte of
                                  -- the number data from the Serial Number
                                  -- Device.
                                  -- Include: family code, serial number
                                  -- and crc value. It's 1 us pulse.
  
  -- signals for CRC check circuit
  signal crcreg_en : std_logic;   -- enable one bit data loaded into
                                  -- the CRC Register.

  signal crcvalue_i: std_logic_vector (7 downto 0); -- The calculated
                                  -- CRC value from the CRC register
  

  -- some internal signals for internal wiring
  signal data_i  : std_logic_vector(7 downto 0); -- to data output
  signal crcok_i : std_logic;                 -- to crcok output


  -- some signals for wiring

  signal vcc : std_logic;

  signal gnd : std_logic;

  
begin

  -------------------------------------------------------------------
  -- internal wiring
  -------------------------------------------------------------------
  vcc     <= '1';

  gnd     <= '0';

  data    <= data_i;           -- a byte of number data to outside
  
  crcok   <= crcok_i;

  -------------------------------------------------------------------
  -- Register the data_valid signals
  -------------------------------------------------------------------
  regs: process (clk_1MHz, reset)
    begin
      if reset = '1' then
         data_valid <= '0';
      elsif clk_1MHz'event and clk_1MHz = '1' then
         data_valid <= databyte_valid; -- the data_valid output connects
                                       -- to the valid signal when
                                       -- getting a byte of data
      end if;
   end process regs;

  -------------------------------------------------------------------
  -- Clock generation
  -------------------------------------------------------------------
  clk_50KHz <= not jc2_q(9);   -- use the msb of JC2 to generate
                               -- 50KHz slow clock
                               -- use "not" here to generate rising
                               -- edge at proper position

                               
  -------------------------------------------------------------------
  -- Several time slot identification signals
  -------------------------------------------------------------------
  -- Suppose the beginning of each state is time 0.
  -- Use combination of JC1 and JC2, we can id any time slot during
  -- each state as small as 1 us.
  ts_60_to_80us <= jc1_q(1) and (not jc1_q(0));
  ts_0_to_10us  <= (not jc1_q(0)) and (not jc2_q(9));
  ts_0_to_1us   <= ts_0_to_10us and (not jc2_q(0)) ;
  ts_14_to_15us <= (not jc1_q(0)) and jc2_q(4) and (not jc2_q(3));  
  
  -------------------------------------------------------------------
  -- ROM Command data bit to transmit (write) to the one wire bus
  -- Use SR1 to pick up each bit out of the Command data byte.
  -------------------------------------------------------------------
  tx_cmd_bit      <= ReadROMCmd(0) when sr1_q(0) = '1'
                else ReadROMCmd(1) when sr1_q(1) = '1'
                else ReadROMCmd(2) when sr1_q(2) = '1'
                else ReadROMCmd(3) when sr1_q(3) = '1' 
                else ReadROMCmd(4) when sr1_q(4) = '1'
                else ReadROMCmd(5) when sr1_q(5) = '1'
                else ReadROMCmd(6) when sr1_q(6) = '1'
                else ReadROMCmd(7) when sr1_q(7) = '1'
                else '0';

  -------------------------------------------------------------------
  -- Bidirectional iobuffer to control the direction of data flow on
  -- the one-wire bus
  -------------------------------------------------------------------  
   iobuf_i : iobuf
          port map (
            T  => d_ctrl, -- control signal to switch in/out
            IO => dq,     -- connect to bidirectional one-wire bus
            I  => dout,   -- data output to the bus
            O  => din);   -- data input from the bus


  -------------------------------------------------------------------
  -- Shift Register 1 
  -- Used to count 8 bits in a byte of data
  -------------------------------------------------------------------
   sr1: SHReg      
          generic map (
            circular => true,  -- 8 bits in a row and scroll over
            AsynReset=> false,
            width    => 8)
          port map (
              reset  => sr1_reset, -- synchronous reset
              clk    => clk_50KHz,
              en     => sr1_en,
              q      => sr1_q);
              
  -------------------------------------------------------------------
  -- Shift Register 2  
  -- Used to count 8 bytes stored in the Serial Number Device
  -------------------------------------------------------------------
   sr2: SHReg      
          generic map (
            circular => false,
            AsynReset=> false,
            width    => 8)
          port map (
            reset    => sr2_reset, -- synchronous reset
            clk      => clk_50KHz,
            en       => sr2_en,
            q        => sr2_q);

  -------------------------------------------------------------------
  -- Johnson Counter 1  
  -- This Johnson counter is used to deal with the time slots.
  -- It chops one state into small time slots.Each is 20 us long,
  -- total 4 slots. 
  -- The reason to use Johnson Counter is to save register bits.
  -- n bits of Johnson counter can count for 2n values.
  -- for the shift register, n bits can only count for n values
  -- In addition, Johnson counter is fast since only NOT gates
  -- are used in this counter.
  -- It's driven by the slow clock (20us) in this system.
  -------------------------------------------------------------------
   jcnt1: JCounter          
          generic map (    
            width    => 2,
            AsynReset=> false)
          port map (
              reset  => jc1_reset, -- synchronous reset
              clk    => clk_50KHz,
              en     => vcc,
              q      => jc1_q);


  -------------------------------------------------------------------
  -- Johnson Counter 2 
  -- (1) Use this counter to generate 20 us slow clock.
  -- (2) It is also used to divide a period of time into time slots.
  --     It counts for small time slot which
  --     is 1 us wide, add up to total 20 slots. 
  -- It should be synchronized with JCount1. 
  -------------------------------------------------------------------
   jcnt2: JCounter          
          generic map (    
            width    => 10,
            AsynReset=> true) -- asynchronous reset
          port map (
            reset  => reset,  -- asynchronous reset!
            clk    => clk_1MHz,
            en     => vcc,
            q      => jc2_q);

  -------------------------------------------------------------------
  -- Bit Register
  -- It accumulates 8 bits of data according to the strobes of
  -- bitreg_en, and output a byte of data.
  -------------------------------------------------------------------
  bitreg_i: BitReg
      generic map ( numBits => 8)
      port map (
            clk   => clk_1MHz,    -- for each bit, use faster clock
            reset => reset,       -- asynchronous reset !
            din   => din,         -- one bit
            en    => bitreg_en,   -- std_logic_vector(7 downto 0)
            dout  => data_i);     -- a byte
            
    
   -- This is the enable signal for the BitReg. When a bit of data
   -- is ready, the BitReg is enabled to load this bit of data
   -- at corresponding bit. For example: bitreg_en = "00001000"
   -- means the data bit will be stored into the register bit 3.
   -- This enable strobe is asserted only one clock period of 1 us.
   -- It's generated from the output of SR1, which is used to
   -- count for 8 bits in a byte of data. It is also controlled by
   -- the numberbits_valid, which indicates a valid data bit received
   -- from the Serial Number Device.
   bitreg_en <= sr1_q when (databit_valid='1') else (others=>'0'); 
   

  -------------------------------------------------------------------
  -- Byte Register
  -- It accumulates 6 bytes of data (serial number) according to
  -- the strobes of bytereg_en, and output the serial number.
  -------------------------------------------------------------------
  
    bytereg_i: ByteReg
      generic map ( numBytes => 6)
      port map (
            clk   => clk_50KHz,   -- for each byte, can use slower clock
            reset => reset,       -- asynchronous reset !
            din   => data_i,      -- one bit
            en    => bytereg_en,  -- std_logic_vector(5 downto 0)
            dout  => sn_data);    -- 48 bits parallel output
            
    
     bytereg_en <= sr2_q(6 downto 1);
                                  -- only enables for the 48 bits
                                  -- serial number by bypassing
                                  -- the first byte (family code)
                                  -- and the last byte (crc code)
   
   ------------------------------------------------------------------------
   -- Check CRC and Generate CRCOK signal
   -- Use CRCReg to calculate CRC value
   -- Latch crcok result when reach the last state (IDLE state)
   --
   -- Note: Use generic to turn on or off this CRC check circuit.
   -- If CheckCRC is false, this circuit will be removed to save
   -- register resources. And CRCOK output will be asserted high as
   -- long as all the data are received. So it won't reflect the CRC
   -- checking result.
   ------------------------------------------------------------------------

   --
   -- If we employ CRC check circuit,
   --
   crcgen  : if CheckCRC = true generate 
   
    crcreg_i: CRCReg
       generic map  (
           width     => 8,
           feedback1 => 4,
           feedback2 => 5)
       port map (
           clk       => clk_1MHz, -- for each bit, use faster clock
           reset     => reset, -- asynchronous reset !
           d         => din,
           en        => crcreg_en,
           q         => crcvalue_i);
           
       -- This enable signal is generated for each data bit when we
       -- receive the crc data from the one-wire device. It's 1us pulse.
       -- use sr2_q(7) here to exclude the situation when we receive
       -- the crc value from the one-wire device.
      crcreg_en <=  databit_valid and (not sr2_q(7));

      -- Assert crcok signal when the last byte of data (crc value) is
      -- received and it matches the caculated crc value from the CRCReg
      crcokreg: process (clk_1MHz, reset)
        begin 
         if reset = '1' then -- need asynchonous reset
           crcok_i <= '0';
         elsif clk_1MHz'event and clk_1MHz = '1' then
           if sr2_q(7) = '1' and databyte_valid = '1' and data_i = crcvalue_i then
               crcok_i <= '1';
           end if;
         end if;
       end process crcokreg;
      
   end generate crcgen;

   --
   -- If we do not use CRC check circuit,
   --
   nocrcgen  : if CheckCRC = false generate 

      -- Assert crcok when the all the data has been received
      crcokreg: process (clk_1MHz, reset)
        begin 
         if reset = '1' then  -- need asynchonous reset
           crcok_i <= '0';
         elsif clk_1MHz'event and clk_1MHz = '1' then
           if sr2_q(7) = '1' and databyte_valid = '1'then
               crcok_i <= '1';
           end if;
         end if;
       end process crcokreg;

   end generate nocrcgen;
         
   ----------------------------------------------------------------------------
   -- The Presence Pulse Register
   ----------------------------------------------------------------------------
   ppreg: process(clk_50KHz, reset)
   begin
     if reset = '1' then
        din_pp <= '1';
     elsif clk_50KHz'event and clk_50KHz = '1' then
        if sr2_q(0) = '1' and thisState = RX_PRE_PLS then
          din_pp <= din;
        end if;
     end if;
   end process ppreg;

   ----------------------------------------------------------------------------
   -- The FSM register
   ----------------------------------------------------------------------------
   fsmr: process (clk_50KHz, reset)
   begin  -- process fsmr
      if reset = '1' then  -- asynchronous reset !
       thisState <= INIT;
      elsif clk_50KHz'event and clk_50KHz = '1' then 
       thisState <= nextState;
      end if;
    end process fsmr;
   

   ------------------------------------------------------------------------
   -- State Mux 
   -- Combinational Logic for the state machine.
   --
   -- Any action in this state mux is synchronized with the 20 us clock
   -- and a few of them are synchronized with the 1us clock.
   --
   -- The transition of the state will take effect on next
   -- rising edge of the clock. 
   ------------------------------------------------------------------------
   
   statemux: process (thisState, din_pp, din, sr1_q, sr2_q,
                      ts_60_to_80us, ts_0_to_10us, ts_0_to_1us, ts_14_to_15us,
                       tx_cmd_bit, crcok_i)

   begin
       
       -- Default values assigned to these signals
       -- Any signal without an assignment in the combinational logic
       -- will use these default values.
       nextState   <= thisState; -- stay at current state by default
       sr1_reset  <= '1';        -- hold sr1 at reset by default
       sr1_en     <= '0';
       sr2_reset  <= '1';        -- hold sr2 at reset by default
       sr2_en     <= '0';
       dout       <= '1';        -- data output to the one-wire bus
       d_ctrl     <= '1';        -- read mode on the one-wire bus by default
       databyte_valid  <= '0';   -- data enable signal for a byte of data
       databit_valid  <= '0';    -- data valid strobe for a bit of data
       jc1_reset  <= '0';        -- hold jc1 at reset by default
       
       -- Case statement as a Mux       
       case thisState is
         
         when INIT =>        ---------------------------------------
                             -- Reset/Initialization state
                             ---------------------------------------
                             -- The one-wire bus will be pulled up,
                             -- so that next state we can send a
                             -- Reset Pulse (active low) to the bus.
                             ---------------------------------------
              
               dout <= '1';   -- begin the operation by pulling up
                              -- one-wire bus to high
                              
               d_ctrl <= '0'; -- write to the one-wire bus

               nextState <= TX_RST_PLS;
               
               jc1_reset <= '1';

         when TX_RST_PLS =>  ---------------------------------------
                               -- Transmit Reset Pulse state     
                               ---------------------------------------
                               -- In this state, the one-wire bus will
                               -- be pulled down (Tx "Reset Pulse") for
                               -- 480 us to reset the one-wire
                               -- device connected to the bus.
                               --
                               -- It enables FSM to move to next state
                               -- at 480 us. The transition of the state
                               -- will happend at 500 us.
                               --
                               -- Use JC1 and SR2 here to count for
                               -- longer time duration (0 ~ 480 us):
                               -----------------------------------------
                               -- Time    JC1 SR2  SR2    SR2
                               -- elapse      En   Rst
                               --  (us)                 msb     lsb
                               -----------------------------------------
                               --    0    "00" '0' '0'  "00000001"
                               --    20   "01" '0' '0'  "00000001"
                               --    40   "11" '0' '0'  "00000001" 
                               --    60   "10" '1' '0'  "00000001"
                               --    80   "00" '0' '0'  "00000010"
                               --   100   "01" '0' '0'  "00000010"
                               --   120   "11" '0' '0'  "00000010"
                               --   140   "10" '1' '0'  "00000010"
                               --   160   "00" '0' '0'  "00000100"
                               --   180   "01" '0' '0'  "00000100"
                               --   ...   ...  ... ...      ...
                               --   ...   ...  ... ...      ...
                               --   240   "00" '0' '0'  "00001000"
                               --   ...   ...  ... ...      ...
                               --   320   "00" '0' '0'  "00010000"
                               --   ...   ...  ... ...      ...
                               --   400   "00" '0' '0'  "00100000"
                               --   ...   ...  ... ...      ...
                               --   480   "00" '0' '1'  "01000000" 
                               --   500   "01" '0' '0'  "00000001"
                               ----------------------------------------

                                    
              sr2_en <= ts_60_to_80us; -- enable sr2 to shift every 80 us,
                                       -- transition will occur at next clock
                                       -- cycle
              
              if sr2_q(6) = '1'  then  -- count till 480 us has passed.
                               
                 d_ctrl <= '1'; -- release one-wire bus by changing to
                                -- read mode
                 nextState <= RX_PRE_PLS; -- goes to next state
                 jc1_reset <= '1';
                 sr2_reset <= '1'; -- reset sr2 at 480us

              else  -- 0 ~ 480 us
              
                 d_ctrl <= '0'; -- write data to one-wire bus
                 dout   <= '0'; -- Tx "Reset Pulse" for 480us
                     
                 sr2_reset <= '0'; -- use sr2 to count for longer
                                   -- time duration (0 ~ 480 us),
                 
              end if;
              
             
         when RX_PRE_PLS => 
                               ---------------------------------------
                               -- Detect Presence Pulse state     
                               ---------------------------------------
                               -- In this state, it sample the data
                               --  on the one wire bus when the
                               -- "Presence Pulse" will occur.
                               -- The data will be latched at 0~80 us.
                               -- Then it waits till total 500us has
                               -- has passed, and moves to next state
                               -- or goes back to INIT state according
                               -- to the presence of the "Presence
                               -- Pulse"
                               --
                               -- Use JC1 and SR2 here to count for
                               -- longer time duration (0 ~ 480 us):
                               --
                               -- Note:"Presence Pulse" indicates
                               -- a Serial Number Device is on the bus
                               -- and it's ready to operate.
                               ----------------------------------------
                               
              sr2_reset <=  '0'  ;   -- use sr2 to count for longer
                                     -- time duration (0 ~ 480 us),

              sr2_en <= ts_60_to_80us; -- enable sr2 to shift every 80 us

                             
              if sr2_q(6) = '1' then     -- 480us passed
              
                 d_ctrl <= '1'; -- remain read status on the bus
                    
                 if din_pp ='0' and din = '1' then -- detect presence pulse
                                                   -- and pull up after the
                                                   -- presence pulse
                   nextState <= TX_RD_CMD;
                   jc1_reset <= '1';
                 else
                   nextState <= INIT;
                 end if;
              
              else   -- 0 ~  480 us
                 
                 d_ctrl <= '1'; -- use read mode on the one-wire bus
                 
              end if;
         
         
         when TX_RD_CMD =>  ---------------------------------------
                               -- Transmit ROM Function Command state
                               ---------------------------------------
                               -- In this state, the onewire bus is
                               -- pulled down during first 10 us.
                               --
                               -- Then according to each bit of data
                               -- in the ROM Command (0x0F for Read ROM),
                               -- we write data to the Serial Number
                               -- Device:
                               -- (1) if we need to write '1' to the serial
                               -- number device, it will release
                               -- the one-wire bus to allow the
                               -- pull-up resistor to pull the wire to
                               -- '1';(2) if we need to write '0' to
                               -- the device, we output '0' directly
                               -- to the bus. This process happens from
                               -- 10 us to 60 us.
                               -- 
                               -- After 60us, it releases the bus allowing
                               -- the one-wire bus to be pulled back to
                               -- high, and enable SR1 to shift to 
                               -- next bit.
                               --  
                               -- After another 20us, the transition of SR1
                               -- will take place. The process will repeat
                               -- to transmit another bit in the ROM Command,
                               -- till all 8 bits in the ROM Command have
                               -- been sent out. 
                               --
                               -- After 8 bits of data has been sent out,
                               -- it moves to next state
                               -----------------------------------------
              
              sr1_reset <= '0';  -- start to use sr1 to count 8 bits in
                                 -- one byte of data

            
              if ts_60_to_80us = '1' then  -- 60 us passed
              
                 d_ctrl <= '1';       -- set read mode to release the one-wire
                                      -- bus
                 sr1_en <= '1';       -- one bit is sent, enable sr1 to
                                      -- move to next bit after 80us
               
                 if sr1_q(7) = '1' then  -- when all 8 bits has been sent
                    nextState <= RX_DATA; -- move to next state
                    jc1_reset <= '1';
                 end if;
              
              elsif ts_0_to_10us = '1'  then  -- 0 ~ 10 us

                 dout <= '0';   -- output '0' to one-wire bus
                 d_ctrl <= '0'; -- set write mode on the bus
                 
   
              else     -- 10 us ~ 60 us 

                 dout <= tx_cmd_bit;  -- write command bit to the bus
                 d_ctrl <= tx_cmd_bit; 
                                -- if write '1' to the one-wire bus,
                                -- we disable output by set read mode on
                                -- the bus, and use the external pull-up
                                -- resistor to pull up the one wire bus
                                -- to high (which represents '1')
                                --
                                -- if write '0' to the one-wire bus,
                                -- we actually send a '0' to the one-wire
                                -- bus using write mode on the bus
              end if;   
              
         
         when RX_DATA =>     ---------------------------------------
                               -- Receive Serial Number Data state
                               ---------------------------------------
                               -- In this state, the onewire bus is
                               -- pulled down during first 1 us, thisthen
                               -- is the initialization of the Rx of one
                               -- bit . Then it release the bus by change
                               -- back to read mode.
                               --
                               -- From 13us to 15 us, it samples the 
                               -- data on the one-wire bus, and assert
                               -- databit_valid signal. 
                               --
                               -- After 15us, it release the bus allowing
                               -- the one-wire bus to be pulled back to
                               -- high.
                               --
                               -- At 60us, it enables SR1 to shift to
                               -- next bit. After 80us, it finished
                               -- reading ONE bit. Then it repeats
                               -- the process to receive other 7
                               -- bits in one byte.
                               --
                               -- After 8 bits for one byte of data have
                               -- been received, the SR2 is used to
                               -- count for total 8 bytes of serial
                               -- number data.
                               --
                               -- After 8 bytes of data has been received,
                               -- it moves to next state
                               -----------------------------------------
         
              sr1_reset <= '0';  -- start to use sr1 to count 8 bits.
                                 -- sr1 is configured to scroll over
                                 -- when it reach the end. So it's
                                 -- not necessary to reset it.
              
              sr2_reset <= '0';  -- start to use sr2 to count for 
                                 -- 8 bytes coming from the one-wire device
                                 
              if ts_60_to_80us = '1' then  -- 60 us passed
              
                 sr1_en <= '1';     -- one bit is read, enable sr1 to move to
                                    -- next bit
                                 
                
                 sr2_en <= sr1_q(7);-- when sr1 shift to last bit which
                                    -- means all 8 bits in this byte of
                                    -- data have already been read,
                                    -- then we can move to next byte
                                    
                 databyte_valid <= sr1_q(7);  
                                    -- enable data output to external
                                    -- world when all 8 bits are read
                                    -- in.
                 
                 if ( sr2_q(7) and databyte_valid) = '1' then
                                    -- move to next state when all 8 bytes
                                    -- has been received.
                      nextState <= IDLE;
                      jc1_reset <= '1';
                 end if;
                 
              
              elsif ts_0_to_1us = '1' then -- 0~1 us
              
                 dout <= '0';   -- pull down for only 1 us
                 d_ctrl <= '0'; -- output '0' to one-wire bus to start write
                                -- period

              else   -- 1~ 60 us

                 d_ctrl <= '1'; -- release one-wire bus by keeping the read
                                -- mode
                 databit_valid <= ts_14_to_15us; 
                                -- assert databit_valid from 13 to 15us
                                -- in order to latch the data reading from
                                -- the one-wire device.

                    
              end if;   

         when IDLE =>
                               ---------------------------------------
                               -- IDLE state
                               ---------------------------------------
                               -- The onewire bus will be released to
                               -- read mode; the data bus will keep the
                               -- last byte (CRC value); crcok will
                               -- be valid as a latch signal.
                               --
                               -- Once enter IDLE state, it stays here
                               -- unless getting a system reset signal.
                               ---------------------------------------
              if crcok_i = '0' then
                 nextState <= INIT;
              else
                 nextState <= IDLE;
              end if;
                
         when Others =>
         

       end case;
     end process statemux;
     
          
end rtl;
