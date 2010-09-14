library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--library proc_common_v1_00_b;
--use proc_common_v1_00_b.proc_common_pkg.all;

library reconos_v2_01_a;
use reconos_v2_01_a.reconos_pkg.all;

library osif_tlb_v2_01_a;
use osif_tlb_v2_01_a.all;

entity osif_tlb is
    generic
    (
        C_DCR_BASEADDR  : std_logic_vector := "1111111111";
        C_DCR_HIGHADDR  : std_logic_vector := "0000000000";
        C_DCR_AWIDTH    : integer          :=  10;
        C_DCR_DWIDTH    : integer          :=  32;
        C_TLB_TAG_WIDTH     : integer          := 20;
        C_TLB_DATA_WIDTH    : integer          := 21  
    );
    port
    (
        sys_clk        : in std_logic;
        sys_reset      : in std_logic;
        
        -- tlb interface
        o_tlb_rdata    : out std_logic_vector(C_TLB_DATA_WIDTH - 1 downto 0);
        i_tlb_wdata    : in  std_logic_vector(C_TLB_DATA_WIDTH - 1 downto 0);
        i_tlb_tag      : in  std_logic_vector(C_TLB_TAG_WIDTH - 1 downto 0);
        o_tlb_match    : out std_logic;
        i_tlb_we       : in  std_logic;
        o_tlb_busy     : out std_logic;
        --o_tlb_wdone    : out std_logic;
    
        -- dcr bus protocol ports
        o_dcrAck   : out std_logic;
        o_dcrDBus  : out std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
        i_dcrABus  : in  std_logic_vector(C_DCR_AWIDTH - 1 downto 0);
        i_dcrDBus  : in  std_logic_vector(C_DCR_DWIDTH - 1 downto 0);
        i_dcrRead  : in  std_logic;
        i_dcrWrite : in  std_logic
    );
end entity;

architecture imp of osif_tlb is
    signal tlb_invalidate : std_logic;
begin

    i_tlb : entity osif_tlb_v2_01_a.tlb
    port map
    (

        clk               => sys_clk,
        rst               => sys_reset,
        
        i_tag             => i_tlb_tag,
        i_data            => i_tlb_wdata,
        o_data            => o_tlb_rdata,
        
        i_we              => i_tlb_we,
        o_busy            => o_tlb_busy,
        --o_wdone           => o_tlb_wdone,
        o_match           => o_tlb_match,
        i_invalidate      => tlb_invalidate
    );
    
    i_tlb_dcr : entity osif_tlb_v2_01_a.tlb_dcr
    generic map
    (
        C_DCR_BASEADDR  => C_DCR_BASEADDR,
        C_DCR_HIGHADDR  => C_DCR_HIGHADDR,
        C_DCR_AWIDTH    => C_DCR_AWIDTH,
        C_DCR_DWIDTH    => C_DCR_DWIDTH
    )
    port map
    (
        clk                => sys_clk,
        rst                => sys_reset,
        
        o_invalidate       => tlb_invalidate,
        
        -- dcr bus protocol ports
        o_dcrAck   => o_dcrAck,
        o_dcrDBus  => o_dcrDBus,
        i_dcrABus  => i_dcrABus,
        i_dcrDBus  => i_dcrDBus,
        i_dcrRead  => i_dcrRead,
        i_dcrWrite => i_dcrWrite
    );
    
    
end architecture;
 
