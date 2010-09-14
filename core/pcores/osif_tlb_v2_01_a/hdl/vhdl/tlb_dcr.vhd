library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library proc_common_v1_00_b;
--use proc_common_v1_00_b.proc_common_pkg.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

entity tlb_dcr is
    generic
    (
        C_DCR_BASEADDR        : std_logic_vector := "1111111111";
        C_DCR_HIGHADDR        : std_logic_vector := "0000000000";
        C_DCR_AWIDTH          : integer          := 10;
        C_DCR_DWIDTH          : integer          := 32
    );
    port
    (
        clk                : in  std_logic;
        rst                : in  std_logic;
        
        o_invalidate       : out std_logic;
        
        -- dcr bus protocol ports
        o_dcrAck   : out std_logic;
        o_dcrDBus  : out std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
        i_dcrABus  : in  std_logic_vector(C_DCR_AWIDTH - 1 downto 0);
        i_dcrDBus  : in  std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
        i_dcrRead  : in  std_logic;
        i_dcrWrite : in  std_logic
    );
end entity;

architecture imp of tlb_dcr is

    constant C_INVALIDATE     : std_logic_vector := X"147A11DA";

    signal dcr_hit    : std_logic;
    signal pid_hit    : std_logic;
    signal inv_hit    : std_logic;
    signal pid        : std_logic_vector(31 downto 0);
    signal inv_count  : std_logic_vector(31 downto 0);
    signal invalidate : std_logic;
begin
    o_invalidate <= invalidate;
    
    dcr_hit <= pid_hit or inv_hit;

    address_decode : process (i_dcrABus)
    begin
        pid_hit <= '0';
        inv_hit <= '0';
        if i_dcrABus = C_DCR_BASEADDR then
            pid_hit <= '1';
        elsif i_dcrABus = C_DCR_BASEADDR + 1 then
            inv_hit <= '1';
        end if;
    end process;
    
    read_mux : process (dcr_hit, pid, inv_count)
    begin
        if pid_hit = '1' and i_dcrRead = '1' then
            o_dcrDBus <= pid;
        elsif inv_hit = '1' and i_dcrRead = '1' then
            o_dcrDBus <= inv_count;
        else
            o_dcrDBus <= i_dcrDBus;
        end if;
    end process;
    
    write_regs : process (clk, rst)
        variable cmd  : std_logic_vector(7 downto 0);
        variable data : std_logic_vector(15 downto 0);
    begin
        if rst = '1' then
            invalidate <= '0';
            pid <= (others => '0');
            inv_count <= (others => '0');
        elsif rising_edge(clk) then
            invalidate <= '0';
            if i_dcrWrite = '1' then
                if pid_hit = '1' then
                    pid <= i_dcrDBus;
                elsif inv_hit = '1' and i_dcrDBus = C_INVALIDATE then
                    invalidate <= '1';
                end if;
            end if;
            
            if (i_dcrWrite = '0' or inv_hit = '0') and invalidate = '1' then
                inv_count <= inv_count + 1;
            end if;
        end if;
    end process;

    sync_ack : process (clk, rst)
    begin
        if rst = '1' then
            o_dcrAck <= '0';
        elsif rising_edge(clk) then
            o_dcrAck <= dcr_hit;
        end if;
    end process;  
    
end architecture;

