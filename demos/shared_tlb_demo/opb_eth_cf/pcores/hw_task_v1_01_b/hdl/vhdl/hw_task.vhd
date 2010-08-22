
------------
-- pcore top level wrapper
-- generated at 2008-08-02 04:42:39.703698 by 'mkhwthread.py hwt_mbox 1 hwt_mbox.vhd'
------------
        
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.ALL;

library burst_ram_v2_01_a;
use burst_ram_v2_01_a.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity hw_task is
        generic (
                C_BUS_BURST_AWIDTH : integer := 14;      -- Note: This addresses bytes
                C_BUS_BURST_DWIDTH : integer := 64;
                C_TASK_BURST_AWIDTH : integer := 12;     -- this addresses 32Bit words
                C_TASK_BURST_DWIDTH : integer := 32;
                C_REGISTER_OSIF_PORTS : integer := 0;    -- insert registers into OSIF ports
                C_DEDICATED_CLK     : integer := 0      -- use dedicated clock input (i_threadClk) for hardware thread
        );

        port (
                clk : in std_logic;
                reset : in std_logic;
                i_osif_flat : in std_logic_vector;
                o_osif_flat : out std_logic_vector;
                
                -- burst mem interface
                i_burstAddr : in std_logic_vector(0 to C_BUS_BURST_AWIDTH-1);
                i_burstData : in std_logic_vector(0 to C_BUS_BURST_DWIDTH-1);
                o_burstData : out std_logic_vector(0 to C_BUS_BURST_DWIDTH-1);
                i_burstWE   : in std_logic;
                i_burstBE   : in std_logic_vector(0 to C_BUS_BURST_DWIDTH/8-1);

                i_threadClk : in std_logic
        );
        
end hw_task;

architecture structural of hw_task is

        constant C_GND_TASK_DATA : std_logic_vector(0 to C_TASK_BURST_DWIDTH-1) := (others => '0');
        constant C_GND_TASK_ADDR : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1) := (others => '0');
        
        signal o_osif_flat_i : std_logic_vector(0 to C_OSIF_TASK2OS_REC_WIDTH-1);
        signal i_osif_flat_i : std_logic_vector(0 to C_OSIF_OS2TASK_REC_WIDTH-1);
        signal o_osif : osif_task2os_t;
        signal i_osif : osif_os2task_t;
        
        signal task2burst_Addr : std_logic_vector(0 to C_TASK_BURST_AWIDTH-1);
        signal task2burst_Data : std_logic_vector(0 to C_TASK_BURST_DWIDTH-1);
        signal burst2task_Data : std_logic_vector(0 to C_TASK_BURST_DWIDTH-1);
        signal task2burst_WE   : std_logic;
        signal task2burst_Clk  : std_logic;

        signal busy_local : std_logic;
        signal threadClk : std_logic;
        
        attribute keep_hierarchy : string;
        attribute keep_hierarchy of structural: architecture is "true";


begin

        dont_use_separate_clock : if C_DEDICATED_CLK = 0 generate
            threadClk <= clk;
        end generate;

        use_separate_clock : if C_DEDICATED_CLK /= 0 generate
            threadClk <= i_threadClk;
        end generate;

        -- connect top level signals
        dont_register_osif_ports : if C_REGISTER_OSIF_PORTS = 0 generate
            o_osif_flat <= o_osif_flat_i;
            i_osif_flat_i <= i_osif_flat;
        end generate;

        register_osif_ports : if C_REGISTER_OSIF_PORTS /= 0 generate
            register_osif_ports_proc: process(clk)
            begin
                if rising_edge(clk) then
                    o_osif_flat <= o_osif_flat_i;
                    i_osif_flat_i <= i_osif_flat;
                end if;
            end process;
        end generate;
        
        -- (un)flatten osif records
        o_osif_flat_i <= to_std_logic_vector(o_osif);
        -- overlay busy with local busy signal
        i_osif <= to_osif_os2task_t(i_osif_flat_i or (X"0000000000" & busy_local & "000000"));
        
        -- instantiate user task
        hwt_i : entity hwt
        generic map (
            C_BURST_AWIDTH => C_TASK_BURST_AWIDTH,
            C_BURST_DWIDTH => C_TASK_BURST_DWIDTH
        )
        port map (
                clk => threadClk,
                reset => reset,
                i_osif => i_osif,
                o_osif => o_osif,
                o_RAMAddr => task2burst_Addr,
                o_RAMData => task2burst_Data,
                i_RAMData => burst2task_Data,
                o_RAMWE => task2burst_WE,
                o_RAMClk => task2burst_Clk
        );
                                 
        burst_ram_i : entity burst_ram_v2_01_a.burst_ram
                generic map (
                        G_PORTA_AWIDTH => C_TASK_BURST_AWIDTH,
                        G_PORTA_DWIDTH => C_TASK_BURST_DWIDTH,
                        G_PORTA_PORTS  => 1,
                        G_PORTB_AWIDTH => C_BUS_BURST_AWIDTH-3,
                        G_PORTB_DWIDTH => C_BUS_BURST_DWIDTH,
                        G_PORTB_USE_BE => 1
                )
                port map (
                        addra => task2burst_Addr,
                        addrax => C_GND_TASK_ADDR,
                        addrb => i_burstAddr(0 to C_BUS_BURST_AWIDTH-1 -3),             -- RAM is addressing 64Bit values
                        clka => task2burst_Clk,
                        clkax => '0',
                        clkb => clk,
                        dina => task2burst_Data,
                        dinax => C_GND_TASK_DATA,
                        dinb => i_burstData,
                        douta => burst2task_Data,
                        doutax => open,
                        doutb => o_burstData,
                        wea => task2burst_WE,
                        weax => '0',
                        web => i_burstWE,
                        ena => '1',
                        enax => '0',
                        enb => '1',
                        beb => i_burstBE
                );

        -- infer latch for local busy signal
        -- needed for asynchronous communication between thread and OSIF
        busy_local_gen : process(reset, o_osif.request, i_osif.ack)
        begin
            if reset = '1' then
                busy_local <= '0';
            elsif o_osif.request = '1' then
                busy_local <= '1';
            elsif i_osif.ack = '1' then
                busy_local <= '0';
            end if;
        end process;

end structural;
