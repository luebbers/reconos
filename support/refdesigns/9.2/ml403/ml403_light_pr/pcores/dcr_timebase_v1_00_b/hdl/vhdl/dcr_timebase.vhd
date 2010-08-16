--
--
-- register at offset 0 is timebase. read- and writeable
-- reguster at offset 1 is control register. not yet used.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--library proc_common_v2_00_a;
--use proc_common_v2_00_a.proc_common_pkg.all;
--use proc_common_v2_00_a.ipif_pkg.all;
--library opb_ipif_v3_01_c;
--use opb_ipif_v3_01_c.all;


entity dcr_timebase is
    generic (
        C_DCR_BASEADDR :     std_logic_vector := "1111111111";
        C_DCR_HIGHADDR :     std_logic_vector := "0000000000";
        C_DCR_AWIDTH   :     integer          := 10;
        C_DCR_DWIDTH   :     integer          := 32
        );
    port (
        i_clk          : in  std_logic;
        i_reset        : in  std_logic;
        o_dcrAck       : out std_logic;
        o_dcrDBus      : out std_logic_vector(0 to C_DCR_DWIDTH-1);
        i_dcrABus      : in  std_logic_vector(0 to C_DCR_AWIDTH-1);
        i_dcrDBus      : in  std_logic_vector(0 to C_DCR_DWIDTH-1);
        i_dcrRead      : in  std_logic;
        i_dcrWrite     : in  std_logic;

        o_timeBase     : out std_logic_vector(0 to C_DCR_DWIDTH-1);
        o_irq          : out std_logic

        );

end dcr_timebase;

architecture implementation of dcr_timebase is

    constant C_NUM_REGS : natural := 2;

    signal dcrDBus : std_logic_vector( 0 to C_DCR_DWIDTH-1 );
    signal dcrAck  : std_logic;

    signal dcrAddrHit : std_logic;
    signal regAddr    : std_logic_vector(0 to 0);  -- FIXME: hardcoded
    signal readCE     : std_logic_vector(0 to C_NUM_REGS-1);
    signal writeCE    : std_logic_vector(0 to C_NUM_REGS-1);

    signal slv_reg0 : std_logic_vector(0 to C_DCR_DWIDTH-1);
    signal slv_reg1 : std_logic_vector(0 to C_DCR_DWIDTH-1);

    signal timebase : std_logic_vector(0 to C_DCR_DWIDTH-1) := (others => '0');

    signal set_timebase : std_logic := '0';         -- loads slv_reg0 into timebase when '1'
begin

    -- generate outputs
    o_dcrAck  <= dcrAck;
    o_dcrDBus <= dcrDBus;

    -- 2 registers = 1 LSBs FIXME: hardcoded. Use log2 instead!
    dcrAddrHit <= '1' when i_dcrABus(0 to C_DCR_AWIDTH-2) = C_DCR_BASEADDR(0 to C_DCR_AWIDTH-2)
                  else '0';
    regAddr    <= i_dcrABus(C_DCR_AWIDTH-1 to C_DCR_AWIDTH-1);

    --
    -- decode read and write accesses into chip enable signals
    -- ASYNCHRONOUS
    --
    ce_gen : process(dcrAddrHit, i_dcrRead, i_dcrWrite,
                     regAddr)
    begin
        -- clear all chip enables by default
        for i in 0 to C_NUM_REGS-1 loop
            readCE(i)  <= '0';
            writeCE(i) <= '0';
        end loop;

        -- decode register address and set
        -- corresponding chip enable signal
        if dcrAddrHit = '1' then
            if i_dcrRead = '1' then
                readCE(TO_INTEGER(unsigned(regAddr)))  <= '1';
            elsif i_dcrWrite = '1' then
                writeCE(TO_INTEGER(unsigned(regAddr))) <= '1';
            end if;
        end if;
    end process;

    --
    -- generate DCR slave acknowledge signal
    -- SYNCHRONOUS
    --
    gen_ack_proc : process(i_clk, i_reset)
    begin
        if i_reset = '1' then
            dcrAck <= '0';
        elsif rising_edge(i_clk) then
            dcrAck <= ( i_dcrRead or i_dcrWrite ) and
                      dcrAddrHit;
        end if;
    end process;


    --
    -- update slave registers on write access
    -- SYNCHRONOUS
    --
    reg_write_proc : process(i_clk, i_reset)
    begin
        if i_reset = '1' then
            slv_reg0         <= (others => '0');
            slv_reg1         <= (others => '0');
            set_timebase     <= '0';
        elsif rising_edge(i_clk) then
            set_timebase <= '0';
            if dcrAck = '0' then    -- register values only ONCE per write select
                case writeCE is
                    when "01"             =>
                        slv_reg0 <= i_dcrDBus;
                        set_timebase <= '1';
                    when "10"             =>
                        slv_reg1 <= i_dcrDBus;
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    --
    -- output slave registers on data bus on read access
    -- ASYNCHRONOUS
    --
    reg_read_proc: process(readCE, timebase, slv_reg1, 
                           i_dcrDBus)
    begin
        dcrDBus <= i_dcrDBus;
        case readCE is
            when "01" =>
                dcrDBus <= timebase;
            when "10" =>
                dcrDBus <= slv_reg1;
            when others =>
                dcrDBus <= i_dcrDBus;
        end case;
    end process;


    --
    -- timebase register implementation
    --
    timebase_proc : process(i_clk, i_reset)

    begin
        if i_reset = '1' then
            timebase <= (others => '0');
        elsif rising_edge(i_clk) then
            if set_timebase = '1' then
                timebase <= slv_reg0;
            else
                timebase <= STD_LOGIC_VECTOR(UNSIGNED(timebase) + 1);
            end if;
        end if;
    end process;

    o_timeBase <= timebase;
    o_irq <= '1' when timebase = X"FFFFFFFF" else '0';

end implementation;
