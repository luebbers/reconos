-------------------------------------------------------------------------------
--                                                                       
--  Module      : BRAM_macro.vhd        
--
--  Version     : 1.2
--
--  Last Update : 2005-06-29
--    
--  Project     : Parameterizable LocalLink FIFO
--
--  Description : Block SelectRAM macros and Control Mappings
--                                                                      
--  Designer    : Wen Ying Wei, Davy Huang
--                                            
--  Company     : Xilinx, Inc.                
--                                            
--  Disclaimer  : XILINX IS PROVIDING THIS DESIGN, CODE, OR    
--                INFORMATION "AS IS" SOLELY FOR USE IN DEVELOPING
--                PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY
--                PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
--                ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,
--                APPLICATION OR STANDARD, XILINX IS MAKING NO
--                REPRESENTATION THAT THIS IMPLEMENTATION IS FREE
--                FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE
--                RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY
--                REQUIRE FOR YOUR IMPLEMENTATION.  XILINX
--                EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH
--                RESPECT TO THE ADEQUACY OF THE IMPLEMENTATION,
--                INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
--                REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
--                FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES
--                OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
--                PURPOSE.
--                
--                (c) Copyright 2005 Xilinx, Inc.
--                All rights reserved.
--                                            
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.fifo_u.all;
use work.BRAM_fifo_pkg.all;
 
entity BRAM_macro is
   generic (
        BRAM_MACRO_NUM  :       integer := 1;     --Number of BRAM Blocks. 
                                                  --Allowed: 1, 2, 4, 8, 16
        WR_DWIDTH       :       integer := 32;    --FIFO write data width. 
                                                  --Allowed: 8, 16, 32, 64
        RD_DWIDTH       :       integer := 32;    --FIFO read data width.
                                                  --Allowed: 8, 16, 32, 64
        WR_REM_WIDTH    :       integer := 2;     --log2(WR_DWIDTH/8)
        RD_REM_WIDTH    :       integer := 2;     --log2(RD_DWIDTH/8)
        RD_PAD_WIDTH    :       integer := 1;
        RD_ADDR_FULL_WIDTH:     integer := 10;
        RD_ADDR_WIDTH   :       integer := 9;
        ADDR_MINOR_WIDTH:       integer := 1;
        
        WR_PAD_WIDTH    :       integer := 1;
        WR_ADDR_FULL_WIDTH:     integer := 10;
        WR_ADDR_WIDTH   :       integer := 9;

        glbtm           :       time := 1 ns );
        
   port (
         -- Reset
         fifo_gsr:           in  std_logic;
          
         -- clocks
         wr_clk:             in  std_logic;
         rd_clk:             in  std_logic;
                  
         rd_allow:           in  std_logic;
         rd_allow_minor:     in  std_logic;
         rd_addr_full:       in  std_logic_vector(RD_PAD_WIDTH+RD_ADDR_FULL_WIDTH-1 downto 0);
         rd_addr_minor:      in  std_logic_vector(ADDR_MINOR_WIDTH-1 downto 0);
         rd_addr:            in  std_logic_vector(RD_PAD_WIDTH + RD_ADDR_WIDTH -1 downto 0);
         rd_data:            out std_logic_vector(RD_DWIDTH -1 downto 0);
         rd_rem:             out std_logic_vector(RD_REM_WIDTH-1 downto 0);
         rd_sof_n:           out std_logic;
         rd_eof_n:           out std_logic;
         
                  
         wr_allow:           in std_logic;
         wr_allow_minor:     in std_logic;
         wr_addr:            in std_logic_vector(WR_PAD_WIDTH + WR_ADDR_WIDTH-1 downto 0);
         wr_addr_minor:      in std_logic_vector(ADDR_MINOR_WIDTH-1 downto 0);
         wr_addr_full:       in std_logic_vector(WR_PAD_WIDTH + WR_ADDR_FULL_WIDTH-1 downto 0);
         wr_data:            in std_logic_vector(WR_DWIDTH-1 downto 0);
         wr_rem:             in std_logic_vector(WR_REM_WIDTH-1 downto 0);
         wr_sof_n:           in std_logic;
         wr_eof_n:           in std_logic
         
         );
         
end BRAM_macro;

architecture BRAM_macro_hdl of BRAM_macro is

constant MEM_IDX : integer := SQUARE2(BRAM_MACRO_NUM);

constant WR_PAR_WIDTH : integer := GET_PAR_WIDTH(WR_DWIDTH);
constant RD_PAR_WIDTH : integer := GET_PAR_WIDTH(RD_DWIDTH);
constant RD_MINOR_HIGH: integer := POWER2(ADDR_MINOR_WIDTH);
constant REM_SEL_HIGH_VALUE : integer := GET_HIGH_VALUE(
                                               RD_REM_WIDTH,WR_REM_WIDTH);  
constant REM_SEL_HIGH1 : integer := POWER2(REM_SEL_HIGH_VALUE);
constant WR_SOF_EOF_WIDTH : integer := GET_WR_SOF_EOF_WIDTH(
                                               RD_DWIDTH, WR_DWIDTH);
constant RD_SOF_EOF_WIDTH : integer := GET_RD_SOF_EOF_WIDTH(
                                               RD_DWIDTH, WR_DWIDTH);
constant WR_CTRL_REM_WIDTH : integer := GET_WR_CTRL_REM_WIDTH(
                                               RD_DWIDTH, WR_DWIDTH);
constant RD_CTRL_REM_WIDTH : integer := GET_RD_CTRL_REM_WIDTH(
                                               RD_DWIDTH, WR_DWIDTH);
constant C_WR_ADDR_WIDTH : integer := GET_C_WR_ADDR_WIDTH(RD_DWIDTH, 
                                               WR_DWIDTH, BRAM_MACRO_NUM);
constant C_RD_ADDR_WIDTH : integer := GET_C_RD_ADDR_WIDTH(RD_DWIDTH, 
                                               WR_DWIDTH, BRAM_MACRO_NUM);
constant ratio1 : integer := GET_RATIO(RD_DWIDTH, WR_DWIDTH, 
                                               WR_SOF_EOF_WIDTH);
constant C_RD_TEMP_WIDTH : integer := GET_C_RD_TEMP_WIDTH(RD_DWIDTH, WR_DWIDTH);
constant C_WR_TEMP_WIDTH : integer := GET_C_WR_TEMP_WIDTH(RD_DWIDTH, WR_DWIDTH);
constant NUM_DIV : integer := GET_NUM_DIV(RD_DWIDTH, WR_DWIDTH);
constant WR_EN_FACTOR : integer := GET_WR_EN_FACTOR(NUM_DIV, BRAM_MACRO_NUM);
constant RDDWdivWRDW : integer := GET_RDDWdivWRDW(RD_DWIDTH, WR_DWIDTH);


type rd_data_vec_type is array(0 to BRAM_MACRO_NUM-1) of 
                                std_logic_vector(RD_DWIDTH-1 downto 0);
type rd_sof_eof_vec_type is array(0 to BRAM_MACRO_NUM-1) of 
                                std_logic_vector(RD_SOF_EOF_WIDTH-1 downto 0);
type rd_ctrl_rem_vec_type is array(0 to BRAM_MACRO_NUM-1) of 
                                std_logic_vector(RD_CTRL_REM_WIDTH-1 downto 0);
type rd_ctrl_vec_type is array(0 to BRAM_MACRO_NUM-1) of 
                                std_logic_vector(C_RD_TEMP_WIDTH-1 downto 0);

signal rd_data_grp:         std_logic_vector((RD_DWIDTH * BRAM_MACRO_NUM) -1 downto 0);  
signal rd_data_p:           rd_data_vec_type := (others=>(others=>'0'));  
signal rd_ctrl_rem_p:       rd_ctrl_rem_vec_type := (others=>(others=>'0'));  
signal rd_sof_eof_p:        rd_sof_eof_vec_type := (others=>(others=>'0'));  
signal rd_ctrl_p:           rd_ctrl_vec_type := (others=>(others=>'0'));  
signal wr_rem_plus_one:     std_logic_vector(WR_REM_WIDTH downto 0);
signal wr_ctrl_rem:         std_logic_vector(WR_CTRL_REM_WIDTH-1 downto 0);
signal rd_ctrl_rem:         std_logic_vector(RD_CTRL_REM_WIDTH-1 downto 0);
signal min_addr1:           integer := 0;
signal min_addr2:           integer := 0;
signal rem_sel1:            integer := 0;
signal rem_sel2:            integer := 0;

signal gnd_bus:             std_logic_vector(128 downto 0);
signal gnd:                 std_logic;
signal pwr:                 std_logic;

signal wr_sof_eof:              std_logic_vector(WR_SOF_EOF_WIDTH-1 downto 0);
signal rd_sof_eof:              std_logic_vector(RD_SOF_EOF_WIDTH-1 downto 0);
signal wr_sof_temp_n:           std_logic_vector(RDDWdivWRDW -1 downto 0);

signal c_rd_temp:               std_logic_vector(C_RD_TEMP_WIDTH-1 downto 0);
signal c_wr_temp:               std_logic_vector(C_WR_TEMP_WIDTH-1 downto 0);
signal c_wr_en:                 std_logic_vector(WR_EN_FACTOR-1 downto 0);
----------------------------------------------------------------------------
-- ram enable signals
-- each ram has two enables for two ports
----------------------------------------------------------------------------
signal ram_wr_en:               std_logic_vector(BRAM_MACRO_NUM -1 downto 0);

----------------------------------------------------------------------------
-- ram select signal, for read and write
-- each bit in this signal will select one bram
----------------------------------------------------------------------------
signal bram_rd_sel:             std_logic_vector (MEM_IDX downto 0);
signal bram_wr_sel:             std_logic_vector (MEM_IDX downto 0);

signal rd_sof_eof_grp:          std_logic_vector((RD_SOF_EOF_WIDTH * BRAM_MACRO_NUM)-1 downto 0);
signal rd_ctrl_rem_grp:         std_logic_vector((RD_CTRL_REM_WIDTH * BRAM_MACRO_NUM)-1 downto 0);
signal c_rd_ctrl_grp:           std_logic_vector((C_RD_TEMP_WIDTH * BRAM_MACRO_NUM)-1 downto 0);
   
signal c_rd_allow1:             std_logic;
signal c_wr_allow1:             std_logic;
signal c_rd_allow2:             std_logic;
signal c_wr_allow2:             std_logic;
signal c_rd_ctrl_rem1:          std_logic_vector(RD_CTRL_REM_WIDTH-1 downto 0);
signal c_rd_ctrl_rem2:          std_logic_vector(RD_CTRL_REM_WIDTH-1 downto 0);
    
signal rd_addr_full_r:            std_logic_vector(RD_PAD_WIDTH+RD_ADDR_FULL_WIDTH-1 downto 0);

begin

    ---------------------------------------------------------------------------
    -- Misellainous                                                          --  
    ---------------------------------------------------------------------------
    gnd <= '0';
    gnd_bus <= (others => '0');
    pwr <= '1';         

    ---------------------------------------------------------------------------
    -- Pipeline
    
    process (rd_clk)
      begin
       if rd_clk'event and rd_clk = '1' then
         if rd_allow = '1' then
           rd_addr_full_r <= rd_addr_full after glbtm;
         end if;
       end if;
    end process;
    
------------------------------------------------------------------------------
--  -- Convert minor address to integer to use as select signals for data   --
--  -- and control outputs                                                  --                   
------------------------------------------------------------------------------

min_addr1 <= slv2int(rd_addr_minor);
min_addr2 <= slv2int(wr_addr_minor);


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
---------------------------- Multiplexer on Read Port -------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


readmuxgen1:  if BRAM_MACRO_NUM > 1 generate
    rdma: for i in 0 to BRAM_MACRO_NUM - 1 generate  -- for data
        rd_data_p(i) <= rd_data_grp (RD_DWIDTH* (i+1) -1 downto RD_DWIDTH * i);    
    end generate rdma;
    rdmuxgen1a: if WR_DWIDTH > RD_DWIDTH generate
        rd_data <= rd_data_p(conv_integer(bram_rd_sel));
    end generate rdmuxgen1a;
   
    rdmuxgen1b: if WR_DWIDTH <= RD_DWIDTH generate
        rd_data <= rd_data_p(conv_integer(bram_rd_sel));
    end generate rdmuxgen1b;
   
   
    rdma_1: if WR_DWIDTH + RD_DWIDTH = 160 generate   
        rdma_1a: for i in 0 to BRAM_MACRO_NUM - 1 generate 
            rd_ctrl_rem_p(i) <= rd_ctrl_rem_grp(RD_CTRL_REM_WIDTH * (i+1) -1 
                                                  downto RD_CTRL_REM_WIDTH*i);
        end generate rdma_1a;
        rd_ctrl_rem <= rd_ctrl_rem_p(conv_integer(bram_rd_sel));
    end generate rdma_1;
      
end generate readmuxgen1;

readmuxgen2:  if BRAM_MACRO_NUM = 1 generate
    rdmuxgen1a: if WR_DWIDTH > RD_DWIDTH generate
        rd_data <= rd_data_grp (RD_DWIDTH -1 downto 0);
    end generate rdmuxgen1a;
   
    rdmuxgen1b: if WR_DWIDTH <= RD_DWIDTH generate
        rd_data <= rd_data_grp (RD_DWIDTH -1 downto 0);
    end generate rdmuxgen1b;
   
    rdma_2: if WR_DWIDTH + RD_DWIDTH = 160 generate   
        rd_ctrl_rem <= rd_ctrl_rem_grp(RD_CTRL_REM_WIDTH -1 downto 0);
    end generate rdma_2;
end generate readmuxgen2;   


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
----------------------- Generate Select Signal on Multiple BRAMs --------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

    bramselgen: if BRAM_MACRO_NUM > 1 generate
    
        bramsel_gen1: if RD_DWIDTH /= WR_DWIDTH generate
 
            bramsel_proc: process (rd_clk, fifo_gsr)
            begin
                if (fifo_gsr = '1') then
                    bram_rd_sel <= (others => '0');
                elsif (rd_clk'EVENT and rd_clk = '1') then
                  if (rd_allow_minor = '1'  or rd_allow = '1') then
                    bram_rd_sel <= '0' & rd_addr_full(RD_ADDR_FULL_WIDTH-1 
                                        downto RD_ADDR_FULL_WIDTH-MEM_IDX); 
                  end if;
                end if;
            end process bramsel_proc;
                                         
            bram_wr_sel <= '0' & wr_addr_full(WR_ADDR_FULL_WIDTH-1 downto 
                                           WR_ADDR_FULL_WIDTH-MEM_IDX);
                                           
        end generate bramsel_gen1;
      
        bramsel_gen2: if RD_DWIDTH = WR_DWIDTH generate
            bramsel_proc: process (rd_clk, fifo_gsr)
            begin
                if (fifo_gsr = '1') then
                    bram_rd_sel <= (others => '0');
                elsif (rd_clk'EVENT and rd_clk = '1') then
                  if (rd_allow_minor = '1' or rd_allow = '1') then                
                    bram_rd_sel <= '0' & rd_addr(RD_ADDR_WIDTH-1 
                        downto RD_ADDR_WIDTH-MEM_IDX);
                  end if;
                end if;
            end process bramsel_proc;
                                         
            bram_wr_sel <= '0' & wr_addr(WR_ADDR_FULL_WIDTH-1 downto 
                                           WR_ADDR_FULL_WIDTH-MEM_IDX);
        end generate bramsel_gen2;      
    end generate bramselgen;


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
----------------------------   SOF/EOF/REM Mappings   -------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Read Width is smaller
-------------------------------------------------------------------------------

GEN1: if RD_DWIDTH < WR_DWIDTH generate -- If rd width is smaller

    ---------------------------------------------------------------------------
    -- Ram enable signal for each ram unit (GEN1)                            --
    -- each bit of this signal will select one unit of ram                   --
    ---------------------------------------------------------------------------   
    ram_en_gen1a: if BRAM_MACRO_NUM > 1 generate
        ram_wr_en <=  conv_std_logic_vector(POWER2(conv_integer(bram_wr_sel)), 
                                            BRAM_MACRO_NUM)
             when wr_allow = '1' else (others=>'0');
    end generate ram_en_gen1a;

    ram_en_gen1b: if BRAM_MACRO_NUM = 1 generate
        ram_wr_en <=  "1" when wr_allow = '1' else (others=>'0');
    end generate ram_en_gen1b;


    GEN1_wr_map_1: if RD_DWIDTH > 8 generate -- rd width is greater than 8
    
        rem_sel1 <= slv2int(wr_rem(WR_REM_WIDTH-1 downto RD_REM_WIDTH));
        
        -- SOF mapping 
        wr_sof_eof(0) <= wr_sof_n;            
        GEN1_wr_map_2: for k in 1 to REM_SEL_HIGH1-1 generate
            wr_sof_eof(k*ratio1) <= '1';            
        end generate GEN1_wr_map_2;
       
        -- EOF mapping
        GEN1_wr_map_3: for j in 0 to REM_SEL_HIGH1-1 generate
            wr_sof_eof(j*ratio1 + 1) <= wr_eof_n when rem_sel1 = j else '1'; 
        end generate GEN1_wr_map_3;
       
        -- REM mapping
        GEN1_wr_map_4: if RD_DWIDTH > 16 generate  
            GEN1_wr_map_5: if WR_DWIDTH + RD_DWIDTH = 96 generate
            --  For this case, the rem and sof and eof are all group together
            --  to become wr_sof_eof.
                GEN1_wr_map_6: for i in 0 to REM_SEL_HIGH1-1 generate
                    wr_sof_eof(i*ratio1+RD_REM_WIDTH+1 downto i*ratio1+2) <= 
                               wr_rem(RD_REM_WIDTH-1 downto 0) 
                                        when rem_sel1 = i else (others => '0');  
                end generate GEN1_wr_map_6;
            end generate GEN1_wr_map_5;
                    
            GEN1_wr_map_7: if WR_DWIDTH + RD_DWIDTH = 160 generate
                GEN1_wr_map_8: for i in 0 to REM_SEL_HIGH1-1 generate
                    wr_ctrl_rem(i*4+WR_REM_WIDTH-1 downto i*4) <= gnd & gnd &
                               wr_rem(RD_REM_WIDTH-1 downto 0) 
                                        when rem_sel1 = i else (others => '0');  
                end generate GEN1_wr_map_8;      
            end generate GEN1_wr_map_7;
                        
            GEN1_wr_map_9: if WR_DWIDTH + RD_DWIDTH = 192 generate
                GEN1_wr_map_10: for i in 0 to REM_SEL_HIGH1-1 generate
                    wr_sof_eof(i*ratio1+RD_REM_WIDTH+1 downto i*ratio1+2) <= 
                               wr_rem(RD_REM_WIDTH-1 downto 0) 
                                        when rem_sel1 = i else (others => '0');  
                end generate GEN1_wr_map_10;      
            end generate GEN1_wr_map_9;
        end generate GEN1_wr_map_4;
        
        GEN1_wr_map_11: if RD_DWIDTH = 16 generate
            GEN1_wr_map_12: if WR_DWIDTH /= 128 generate
                GEN1_wr_map_13: for i in 0 to REM_SEL_HIGH1-1 generate
                    wr_ctrl_rem(i) <= wr_rem(0) when rem_sel1 = i else '0';
                end generate GEN1_wr_map_13;
            end generate GEN1_wr_map_12;
            
            GEN1_wr_map_14: if WR_DWIDTH = 128 generate
                GEN1_wr_map_15: for i in 0 to REM_SEL_HIGH1-1 generate
                    wr_sof_eof(i*ratio1+2)<=wr_rem(0) when rem_sel1=i else '0';  
                end generate GEN1_wr_map_15;
            end generate GEN1_wr_map_14;
        end generate GEN1_wr_map_11;
    end generate GEN1_wr_map_1;
   
    ---------------------------------------------------------------------------
    -- The following generate statments Covers cases: 128:8, 64:8, 32:8, 16:8--
    -- There is no need to find rem, so we only need two bit wide to store   --
    -- sof and eof. (GEN1)                                                   --                                 
    ---------------------------------------------------------------------------

     GEN1_wr_map_16: if RD_DWIDTH = 8 generate -- rd width is 8
        rem_sel2 <= slv2int(wr_rem(WR_REM_WIDTH-1 downto 0));
        -- SOF Mapping
        wr_sof_eof(0) <= wr_sof_n; 
        
        GEN1_wr_map_17: if WR_DWIDTH /= 16 generate 
            GEN1_wr_map_18: if WR_DWIDTH /= 128 generate
                GEN1_wr_map_19: for k in 1 to REM_SEL_HIGH1*2-1 generate
                    wr_sof_eof(k*ratio1) <= '1';            
                end generate GEN1_wr_map_19;
                -- EOF mapping
                GEN1_wr_map_20: for p in 0 to REM_SEL_HIGH1*2-1 generate
                    wr_sof_eof(p*ratio1 + 1)<=wr_eof_n when rem_sel2=p else '1'; 
                end generate GEN1_wr_map_20;
            end generate GEN1_wr_map_18;
            
            GEN1_wr_map_21: if WR_DWIDTH = 128 generate
                GEN1_wr_map_22: for k in 1 to REM_SEL_HIGH1*2-1 generate
                    wr_sof_eof(k*ratio1) <= '1';            
                end generate GEN1_wr_map_22;
                -- EOF mapping
                GEN1_wr_map_23: for p in 0 to REM_SEL_HIGH1*2-1 generate
                    wr_sof_eof(p*ratio1 + 1)<=wr_eof_n when rem_sel2=p else '1'; 
                end generate GEN1_wr_map_23;
            end generate GEN1_wr_map_21;
            
        end generate GEN1_wr_map_17;
        
        GEN1_wr_map_24: if WR_DWIDTH = 16 generate 
            GEN1_wr_map_25: for k in 1 to REM_SEL_HIGH1-1 generate
                wr_sof_eof(k*ratio1) <= '1';            
            end generate GEN1_wr_map_25;
            -- EOF mapping
            GEN1_wr_map_26: for p in 0 to REM_SEL_HIGH1-1 generate
                wr_sof_eof(p*ratio1 + 1) <= wr_eof_n when rem_sel2=p else '1'; 
            end generate GEN1_wr_map_26;
        end generate GEN1_wr_map_24;
        
    end generate GEN1_wr_map_16;


    ---------------------------------------------------------------------------
    -- Reading SOF, EOF, REM with mapping (GEN1)                             --
    ---------------------------------------------------------------------------
    rd_sof_n <= rd_sof_eof(0) when min_addr1 = 1 else '1';
    rd_eof_n <= rd_sof_eof(1);

    GEN1_rd_map_0: if RD_DWIDTH = 8 generate
      rd_rem <= (others => '0');
    end generate;
     
    GEN1_rd_map_1: if RD_DWIDTH > 8 generate
        GEN1_rd_map_2: if RD_DWIDTH = 16 generate    
            rd_rem <= rd_ctrl_rem when rd_sof_eof(1) = '0' else (others => '0');
        end generate GEN1_rd_map_2;

        GEN1_rd_map_3: if RD_DWIDTH = 64 generate
            rd_rem <= rd_ctrl_rem(RD_REM_WIDTH-1 downto 0);          
        end generate GEN1_rd_map_3;
        
        GEN1_rd_map_4: if RD_DWIDTH = 32 generate
            GEN1_rd_map_5: if WR_DWIDTH = 64 generate
                rd_rem <= rd_sof_eof(RD_REM_WIDTH+1 downto 2);       
            end generate GEN1_rd_map_5;
            
            GEN1_rd_map_6: if WR_DWIDTH = 128 generate
                rd_rem <= rd_ctrl_rem(RD_REM_WIDTH-1 downto 0);
            end generate GEN1_rd_map_6;
        end generate GEN1_rd_map_4;
    end generate GEN1_rd_map_1;


end generate GEN1;


-------------------------------------------------------------------------------
-- Write Width is smaller
-------------------------------------------------------------------------------

GEN2: if RD_DWIDTH > WR_DWIDTH generate

    ---------------------------------------------------------------------------
    -- Ram enable signal for each ram unit   (GEN2)                          --
    -- each bit of this signal will select one unit of ram                   --
    ---------------------------------------------------------------------------   
    ram_en_gen2a: if BRAM_MACRO_NUM > 1 generate
        ram_wr_en <=  conv_std_logic_vector( POWER2(conv_integer(bram_wr_sel)),
                                          BRAM_MACRO_NUM)
             when wr_allow_minor = '1' else (others=>'0');
    end generate ram_en_gen2a;

    ram_en_gen2b: if BRAM_MACRO_NUM = 1 generate
        ram_wr_en <=  "1" when wr_allow_minor = '1' else (others=>'0');
    end generate ram_en_gen2b;

    ---------------------------------------------------------------------------
    -- Writing SOF, EOF, REM with mapping (GEN2)                             --
    -- The process below is used to pipeline wr_sof_n in a register to avoid --
    -- latches.                                                              --
    ---------------------------------------------------------------------------
    
    wr_sw_gen2a2_proc: process (wr_clk, fifo_gsr)
    begin
        if (fifo_gsr = '1') then
            wr_sof_temp_n <= (others => '0');
        elsif wr_clk'EVENT and wr_clk = '1' then
            if wr_allow_minor = '1' then
                wr_sof_temp_n(min_addr2) <= wr_sof_n after glbtm; 
            end if;
        end if;
    end process wr_sw_gen2a2_proc;
    
    GEN2_wr_map_1: if WR_DWIDTH = 32 generate
         
        GEN2_wr_map_2: if RD_DWIDTH = 64 generate 
            wr_sof_eof(0) <= wr_sof_n when (min_addr2 = 0) else wr_sof_temp_n(0); 
            wr_sof_eof(1) <= wr_eof_n;
            wr_ctrl_rem(RD_REM_WIDTH-1 downto 0) <= wr_addr_minor & wr_rem 
                                  when wr_eof_n = '0' else (others => '0');
        end generate GEN2_wr_map_2;
        
        GEN2_wr_map_3: if RD_DWIDTH = 128 generate       
            wr_sof_eof(0) <= wr_sof_n when min_addr2 = 0 else wr_sof_temp_n(0);   
            wr_sof_eof(1) <= wr_eof_n;            
            wr_ctrl_rem(RD_REM_WIDTH-1 downto 0) <= wr_addr_minor & wr_rem 
                                  when wr_eof_n = '0' else (others => '0');
        end generate GEN2_wr_map_3;
    end generate GEN2_wr_map_1;
      
    GEN2_wr_map_4: if WR_DWIDTH = 16 generate
        GEN2_wr_map_5: if RD_DWIDTH /=128 generate
            wr_sof_eof(0) <= wr_sof_n when min_addr2 = 0 else wr_sof_temp_n(0);    
            wr_sof_eof(1) <= wr_eof_n;
            wr_ctrl_rem(RD_REM_WIDTH-1 downto 0) <= wr_addr_minor & wr_rem 
                               when wr_eof_n = '0' else (others => '0');
        end generate GEN2_wr_map_5;
        
        GEN2_wr_map_6: if RD_DWIDTH = 128 generate
            wr_sof_eof(0) <= wr_sof_n when (min_addr2 = 0 and wr_eof_n = '0')
                                                else wr_sof_temp_n(0);
            wr_sof_eof(1) <= wr_eof_n;
            wr_ctrl_rem(RD_REM_WIDTH-1 downto 0) <= wr_addr_minor & wr_rem 
                               when wr_eof_n = '0' else (others => '0');
        end generate GEN2_wr_map_6;           
    end generate GEN2_wr_map_4;
      
    GEN2_wr_map_7: if WR_DWIDTH = 8 generate               
        wr_sof_eof(0) <= wr_sof_n when (min_addr2 = 0 and wr_eof_n = '0') 
                                  else wr_sof_temp_n(0);
        wr_sof_eof(1) <= wr_eof_n after glbtm;
         
        GEN2_wr_map_8: if RD_DWIDTH > 32 generate 
            wr_ctrl_rem(RD_REM_WIDTH-1 downto 0) <= wr_addr_minor when 
                                        wr_eof_n = '0' else (others => '0');
        end generate GEN2_wr_map_8;
        
        GEN2_wr_map_9: if RD_DWIDTH <= 32 generate
            wr_ctrl_rem(0) <= '1' when wr_eof_n = '0' else '0';
        end generate GEN2_wr_map_9;
    end generate GEN2_wr_map_7;

    GEN2_wr_map_10: if WR_DWIDTH = 64 generate
        wr_sof_eof(0) <= wr_sof_n when min_addr2 = 0 else wr_sof_temp_n(0);   
        wr_sof_eof(1) <= wr_eof_n;
        wr_sof_eof(RD_REM_WIDTH+1 downto 2) <= wr_addr_minor & wr_rem when 
                                        wr_eof_n = '0' else (others => '0');
        wr_sof_eof(7 downto RD_REM_WIDTH+2) <= (others => '0');
    end generate GEN2_wr_map_10;
    
    ---------------------------------------------------------------------------
    -- Reading SOF, EOF, REM with mapping (GEN2)                             --
    ---------------------------------------------------------------------------
   
    GEN2_rd_map_1: if WR_DWIDTH = 32 generate
       rd_sof_n <= rd_sof_eof(0);
       
       GEN2_rd_map_2: if RD_DWIDTH = 64 generate
           rd_eof_n <= rd_sof_eof(1) when rd_sof_eof(1) = '0' else rd_sof_eof(5);
           rd_rem <= rd_ctrl_rem(2 downto 0);
       end generate GEN2_rd_map_2;
       
       GEN2_rd_map_3: if RD_DWIDTH = 128 generate
       
           rd_eof_n <= rd_sof_eof(1) when rd_sof_eof(1) = '0' 
               else rd_sof_eof(3) when rd_sof_eof(3) = '0' 
               else rd_sof_eof(5) when rd_sof_eof(5) = '0'
               else rd_sof_eof(7);
       
           rd_rem <= rd_ctrl_rem(3 downto 0) when rd_sof_eof(1) = '0'  
                else rd_ctrl_rem(7 downto 4) 
                when rd_ctrl_rem(7 downto 6) = "01" and rd_sof_eof(3) = '0' 
                else rd_ctrl_rem(11 downto 8) 
                when rd_ctrl_rem(11 downto 10) = "10" and rd_sof_eof(5) = '0' 
                else rd_ctrl_rem(15 downto 12) 
                when rd_ctrl_rem(15 downto 14) = "11" and rd_sof_eof(7) = '0'
                else (others => '0');
       end generate GEN2_rd_map_3;  
    end generate GEN2_rd_map_1;
     
    GEN2_rd_map_4: if WR_DWIDTH = 16 generate
       GEN2_rd_map_5: if RD_DWIDTH = 64 generate
           rd_sof_n <= rd_sof_eof(0);
           rd_eof_n <= rd_sof_eof(1) when rd_sof_eof(1) = '0'
               else rd_sof_eof(3) when rd_sof_eof(3) = '0'
               else rd_sof_eof(5) when rd_sof_eof(5) = '0'
               else rd_sof_eof(7);
           rd_rem <= rd_ctrl_rem(RD_REM_WIDTH-1 downto 0);
       end generate GEN2_rd_map_5;
       
       GEN2_rd_map_6: if RD_DWIDTH = 32 generate
           rd_sof_n <= rd_sof_eof(0);
           rd_eof_n <= rd_sof_eof(1) when rd_sof_eof(1) = '0'
                                     else rd_sof_eof(3);
           rd_rem <= rd_ctrl_rem(RD_REM_WIDTH-1 downto 0);
       end generate GEN2_rd_map_6;       
       
       GEN2_rd_map_7: if RD_DWIDTH = 128 generate
           rd_sof_n <= rd_sof_eof(0);
           rd_eof_n <= rd_sof_eof(1);
           rd_rem <= rd_ctrl_rem(RD_REM_WIDTH-1 downto 0);
       end generate GEN2_rd_map_7;
    end generate GEN2_rd_map_4;

    GEN2_rd_map_8: if WR_DWIDTH = 8 generate
        rd_sof_n <= rd_sof_eof(0);
        rd_eof_n <= rd_sof_eof(1);
        
        GEN2_rd_map_9: if RD_DWIDTH > 32 generate
            rd_rem <= rd_ctrl_rem(RD_REM_WIDTH-1 downto 0);
        end generate GEN2_rd_map_9;
        
        GEN2_rd_map_10: if RD_DWIDTH = 32 generate
            rd_rem <= "00" when rd_ctrl_rem(0) = '1' 
                 else "01" when rd_ctrl_rem(1) = '1' 
                 else "10" when rd_ctrl_rem(2) = '1' 
                 else "11" when rd_ctrl_rem(3) = '1' 
                 else "00";
        end generate GEN2_rd_map_10;
        
        GEN2_rd_map_11: if RD_DWIDTH = 16 generate
            rd_rem(0) <= '0' when rd_ctrl_rem(0) = '1'
                 else '1' when rd_ctrl_rem(1) = '1' 
                 else '0';
        end generate GEN2_rd_map_11;
        
    end generate GEN2_rd_map_8;
    
    GEN2_rd_map_12: if WR_DWIDTH = 64 generate
        rd_sof_n <= rd_sof_eof(0);
        rd_eof_n <= rd_sof_eof(1) when rd_sof_eof(1) = '0' else rd_sof_eof(9); 
        rd_rem <= rd_sof_eof(RD_REM_WIDTH+1 downto 2) when rd_sof_eof(1) = '0'
                              else rd_sof_eof(RD_REM_WIDTH+9 downto 10);
    end generate GEN2_rd_map_12;


end generate GEN2;

-------------------------------------------------------------------------------
-- Read Width and write width are the same 
-------------------------------------------------------------------------------

GEN3: if RD_DWIDTH = WR_DWIDTH generate

    ---------------------------------------------------------------------------
    -- Ram enable signal for each ram unit (GEN3)                            --
    -- each bit of this signal will select one unit of ram                   --
    ---------------------------------------------------------------------------   
    ram_en_gen3a: if BRAM_MACRO_NUM > 1 generate
        ram_wr_en <=  conv_std_logic_vector( POWER2(conv_integer(bram_wr_sel)),
                                          BRAM_MACRO_NUM)
             when wr_allow = '1' else (others=>'0');
    end generate ram_en_gen3a;

    ram_en_gen3b: if BRAM_MACRO_NUM = 1 generate
        ram_wr_en <=  "1" when wr_allow = '1' else (others=>'0');
    end generate ram_en_gen3b;

    ---------------------------------------------------------------------------
    -- Reading SOF, EOF, REM with mapping (GEN3)                             --
    -- In the case when WR_DWIDTH and RD_DWIDTH are larger than 16 bit wide, --
    -- all control signals(including sof and eof) are group together for     --
    -- mapping. This group name is different when the data width are         --
    -- different for easier implementations.                                 --
    ---------------------------------------------------------------------------
    wr_sof_eof(0) <= wr_sof_n;
    wr_sof_eof(1) <= wr_eof_n;
    rd_sof_n <= rd_sof_eof(0);
    rd_eof_n <= rd_sof_eof(1);
    
    rd_ctrl_gen3a: if WR_DWIDTH + RD_DWIDTH > 32 generate -- 32, 64, 128
       wr_sof_eof(WR_REM_WIDTH+1 downto 2) <= wr_rem;
       rd_rem <= rd_sof_eof(RD_REM_WIDTH+1 downto 2);
    end generate rd_ctrl_gen3a;
    
    rd_ctrl_gen3b: if WR_DWIDTH + RD_DWIDTH < 32 generate -- 16
       rd_rem <= (others => '0');
    end generate rd_ctrl_gen3b;
   
    rd_ctrl_gen3c: if WR_DWIDTH + RD_DWIDTH /= 16 generate -- 16, 32, 64, 128
        rd_ctrl_gen3c1: for i in 0 to BRAM_MACRO_NUM - 1 generate 
            rd_sof_eof_p(i) <= rd_sof_eof_grp(RD_SOF_EOF_WIDTH * (i+1) -1 
                                              downto RD_SOF_EOF_WIDTH*i);
        end generate rd_ctrl_gen3c1;
        rd_sof_eof <= rd_sof_eof_p(conv_integer(bram_rd_sel));
    end generate rd_ctrl_gen3c;

end generate GEN3;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--------------------------- Data and Control BRAMs ----------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  Same Data Width                                                          --
-------------------------------------------------------------------------------
BRAM_gen_1: if WR_DWIDTH + RD_DWIDTH = 16 generate   -- rd and wr are 8-bit wide
   -- Data BRAM
    BRAM_gen_1aa: for i in 0 to BRAM_MACRO_NUM-1 generate
        bram1a: RAMB16_S9_S9 port map (ADDRA => rd_addr(10 downto 0), 
              ADDRB => wr_addr(10 downto 0),
              DIA => gnd_bus(8 downto 1), DIPA => gnd_bus(0 downto 0),
              DIB => wr_data, DIPB(0) => gnd,
              WEA => gnd, WEB => pwr, CLKA => rd_clk, 
              CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
              ENA => rd_allow, ENB => ram_wr_en(i), 
              DOA => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i));
    end generate BRAM_gen_1aa;

    -- Control BRAM
    
    BRAM_gen_1ab: if BRAM_MACRO_NUM < 16 generate -- if DATA BRAM is small, all
                                  -- control data can fit into one BRAM
        bram1b: RAMB16_S2_S2 port map (ADDRA => rd_addr(12 downto 0), 
              ADDRB => wr_addr(12 downto 0),
              DIA => gnd_bus(1 downto 0), DIB => wr_sof_eof,              
              WEA => gnd, WEB => pwr, CLKA => rd_clk, 
              CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
              ENA => rd_allow, ENB => wr_allow, 
              DOA => rd_sof_eof);
        end generate  BRAM_gen_1ab;
   
    BRAM_gen_1ac: if BRAM_MACRO_NUM >= 16 generate -- If DATA BRAM is large,
                                   -- multiple control BRAMs are used
        BRAM_gen_1ac1: for i in 0 to BRAM_MACRO_NUM/4-1 generate 
            bram1c: RAMB16_S2_S2 port map (ADDRA => rd_addr(12 downto 0), 
                ADDRB => wr_addr(12 downto 0),
                DIA => gnd_bus(1 downto 0), DIB => wr_sof_eof,              
                WEA => gnd, WEB => pwr, CLKA => rd_clk, 
                CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
                ENA => rd_allow, ENB => c_wr_en(i), 
                DOA => rd_sof_eof_grp(RD_SOF_EOF_WIDTH*(i+1)-1 
                                      downto RD_SOF_EOF_WIDTH*i));
                
            rd_sof_eof_p(i) <= rd_sof_eof_grp(RD_SOF_EOF_WIDTH *(i+1)-1 
                                              downto RD_SOF_EOF_WIDTH*i);  
            c_wr_en(i) <= ram_wr_en(i*4) or ram_wr_en(i*4+1) or 
                                ram_wr_en(i*4+2) or ram_wr_en(i*4+3) ;                                 

        end generate BRAM_gen_1ac1;
        
        rd_sof_eof <= rd_sof_eof_p(conv_integer(bram_rd_sel)/4);

    end generate  BRAM_gen_1ac;   
end generate BRAM_gen_1;

-------------------------------------------------------------------------------

BRAM_gen_2: if WR_DWIDTH + RD_DWIDTH = 32 generate  -- rd and wr are 16-bit wide

   -- Data and Control BRAM
   BRAM_gen_2aa: for i in 0 to BRAM_MACRO_NUM-1 generate
      bram2a: RAMB16_S18_S18 port map (ADDRA => rd_addr(9 downto 0), 
          ADDRB => wr_addr(9 downto 0),
          DIA => gnd_bus(17 downto 2), DIPA => gnd_bus(1 downto 0),
          DIB => wr_data, DIPB => wr_sof_eof(1 downto 0),
          WEA => gnd, WEB => pwr, CLKA => rd_clk, 
          CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
          ENA => rd_allow, ENB => ram_wr_en(i), 
          DOA => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i), 
          DOPA => rd_sof_eof_grp(RD_SOF_EOF_WIDTH*(i+1)-1 
                                 downto RD_SOF_EOF_WIDTH*i));
                                        
   end generate BRAM_gen_2aa;
      
   -- Additional Control BRAM  
   bram2b: RAMB16_S1_S1 port map (ADDRA => rd_addr(13 downto 0), 
              ADDRB => wr_addr(13 downto 0),
              DIA(0) => gnd, DIB(0) => wr_rem(0), 
              WEA => gnd, WEB => pwr, CLKA => rd_clk, 
              CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
              ENA => rd_allow, ENB => wr_allow, 
              DOA(0) => rd_rem(0));

end generate BRAM_gen_2;

-------------------------------------------------------------------------------

BRAM_gen_3: if WR_DWIDTH + RD_DWIDTH = 64 generate -- rd and wr are 32-bit wide

   -- Data and Control BRAM
   BRAM_gen_3aa: for i in 0 to BRAM_MACRO_NUM-1 generate
      bram3a: RAMB16_S36_S36 port map (ADDRA => rd_addr(8 downto 0), 
              ADDRB => wr_addr(8 downto 0),
              DIA => gnd_bus(35 downto 4), DIPA => gnd_bus(3 downto 0),
              DIB => wr_data, DIPB => wr_sof_eof,
              WEA => gnd, WEB => pwr, CLKA => rd_clk, 
              CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
              ENA => rd_allow, ENB => ram_wr_en(i), 
              DOA => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i), 
              DOPA => rd_sof_eof_grp(RD_SOF_EOF_WIDTH*(i+1)-1 
                                     downto RD_SOF_EOF_WIDTH*i) );
   end generate BRAM_gen_3aa;
end generate BRAM_gen_3;

-------------------------------------------------------------------------------

BRAM_gen_3a: if WR_DWIDTH + RD_DWIDTH = 128 generate -- rd and wr are 64-bit wide

   -- Data and Control BRAM
   BRAM_gen_3bb: for i in 0 to BRAM_MACRO_NUM-1 generate
      bram3b: BRAM_S72_S72 port map (ADDRA => rd_addr(8 downto 0), 
              ADDRB => wr_addr(8 downto 0),
              DIA => gnd_bus(71 downto 8), DIPA => gnd_bus(7 downto 0),
              DIB => wr_data, DIPB => wr_sof_eof,
              WEA => gnd, WEB => pwr, CLKA => rd_clk, 
              CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
              ENA => rd_allow, ENB => ram_wr_en(i), 
              DOA => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i), 
              DOPA => rd_sof_eof_grp(RD_SOF_EOF_WIDTH*(i+1)-1 
                                     downto RD_SOF_EOF_WIDTH*i));
   end generate BRAM_gen_3bb;
end generate BRAM_gen_3a;

-------------------------------------------------------------------------------

BRAM_gen_3b: if WR_DWIDTH + RD_DWIDTH = 256 generate  -- rd and wr are 128-bit wide

   BRAM_gen_3cc: for i in 0 to BRAM_MACRO_NUM-1 generate
      bram3c: BRAM_S144_S144 port map (ADDRA => rd_addr(8 downto 0), 
              ADDRB => wr_addr(8 downto 0),
              DIA => gnd_bus(127 downto 0), DIPA => gnd_bus(15 downto 0),
              DIB => wr_data, DIPB => wr_sof_eof,
              WEA => gnd, WEB => pwr, CLKA => rd_clk, 
              CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
              ENA => rd_allow, ENB => ram_wr_en(i), 
              DOA => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i), 
              DOPA => rd_sof_eof_grp(RD_SOF_EOF_WIDTH*(i+1)-1 
                                     downto RD_SOF_EOF_WIDTH*i));
   end generate BRAM_gen_3cc;
end generate BRAM_gen_3b;


-------------------------------------------------------------------------------
--  Different Data Width                                                     --
-------------------------------------------------------------------------------

BRAM_gen_4: if WR_DWIDTH + RD_DWIDTH = 24 generate  
    BRAM_gen_4a: if RD_DWIDTH = 8 generate -- rd is 8-bit, wr is 16-bit wide
        -- Data BRAM
        BRAM_gen_4aa: for i in 0 to BRAM_MACRO_NUM-1 generate
            bram4a: RAMB16_S9_S18 port map (ADDRA => rd_addr_full(10 downto 0), 
                ADDRB => wr_addr_full(9 downto 0),
                DIA => gnd_bus(7 downto 0), DIPA => gnd_bus(0 downto 0),
                DIB => wr_data, DIPB => gnd_bus(1 downto 0),
                WEA => gnd, WEB => pwr, CLKA => rd_clk, 
                CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
                ENA => rd_allow_minor, ENB => ram_wr_en(i), 
                DOA => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i));
        end generate BRAM_gen_4aa;
           
       -- Control BRAM
       BRAM_gen_4ab: if BRAM_MACRO_NUM < 8 generate      
            bram4b: RAMB16_S2_S4 port map (ADDRA => rd_addr_full(12 downto 0), 
                ADDRB => wr_addr_full(11 downto 0),
                DIA => gnd_bus(1 downto 0), DIB => wr_sof_eof, 
                WEA => gnd, WEB => pwr, CLKA => rd_clk, 
                CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
                ENA => rd_allow_minor, ENB => wr_allow, 
                DOA => rd_sof_eof);  
        end generate BRAM_gen_4ab;
      
        BRAM_gen_4ac: if BRAM_MACRO_NUM >= 8 generate      
            BRAM_gen_4ac1: for i in 0 to BRAM_MACRO_NUM/4-1 generate  
                bram4c: RAMB16_S2_S4 port map (ADDRA =>rd_addr_full(12 downto 0), 
                    ADDRB => wr_addr_full(11 downto 0),
                    DIA => gnd_bus(1 downto 0), DIB => wr_sof_eof, 
                    WEA => gnd, WEB => pwr, CLKA => rd_clk, 
                    CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
                    ENA => rd_allow_minor, ENB => c_wr_en(i), 
                    DOA => rd_sof_eof_grp(RD_SOF_EOF_WIDTH*(i+1)-1 
                                          downto RD_SOF_EOF_WIDTH*i)); 
                                          
                rd_sof_eof_p(i) <= rd_sof_eof_grp(RD_SOF_EOF_WIDTH *(i+1)-1 
                                                  downto RD_SOF_EOF_WIDTH*i);  
                c_wr_en(i) <= ram_wr_en(i*4) or ram_wr_en(i*4+1) 
                                             or ram_wr_en(i*4+2) 
                                             or ram_wr_en(i*4+3);                                 

            end generate BRAM_gen_4ac1;
            
            rd_sof_eof <= rd_sof_eof_p(conv_integer(bram_rd_sel)/4);
            
        end generate BRAM_gen_4ac;
    end generate BRAM_gen_4a;

-------------------------------------------------------------------------------

    BRAM_gen_4b: if RD_DWIDTH = 16 generate -- rd is 16-bit, wr is 8-bit wide
    
        -- Data and Control BRAM
        BRAM_gen_4bb: for i in 0 to BRAM_MACRO_NUM-1 generate
            bram4d: RAMB16_S9_S18 port map ( ADDRB => rd_addr_full(9 downto 0),
                ADDRA => wr_addr_full(10 downto 0),
                DIB => gnd_bus(17 downto 2), DIPB => gnd_bus(1 downto 0),
                DIA => wr_data, DIPA(0) => wr_ctrl_rem(0),
                WEA => pwr, WEB => gnd, CLKA => wr_clk, 
                CLKB => rd_clk, SSRA => gnd, SSRB => gnd, 
                ENA => ram_wr_en(i), ENB => rd_allow, 
                DOB => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i),
                DOPB => rd_ctrl_rem_grp(RD_CTRL_REM_WIDTH*(i+1)-1 
                                        downto RD_CTRL_REM_WIDTH*i));
                                        
            rd_ctrl_rem_p(i) <= rd_ctrl_rem_grp(RD_CTRL_REM_WIDTH*(i+1)-1 
                                        downto RD_CTRL_REM_WIDTH*i);
        end generate BRAM_gen_4bb;
        
        rd_ctrl_rem <= rd_ctrl_rem_p(conv_integer(bram_rd_sel));
   
        -- Additional Control BRAM
        BRAM_gen_4cc: if BRAM_MACRO_NUM < 16 generate   
        bram4e: RAMB16_S2_S2 port map (ADDRB => rd_addr_full(12 downto 0),  
              ADDRA=> wr_addr(12 downto 0),
              DIA => wr_sof_eof,  DIB => gnd_bus(1 downto 0) ,
              WEA => pwr, WEB => gnd, CLKA => wr_clk, 
              CLKB => rd_clk, SSRA => gnd, SSRB => gnd, 
              ENA => wr_allow, ENB => rd_allow, 
              DOB => rd_sof_eof);  
        end generate BRAM_gen_4cc;

        BRAM_gen_4dd: if BRAM_MACRO_NUM >= 16 generate   
            BRAM_gen_4dda: for i in 0 to BRAM_MACRO_NUM/8 -1 generate
                bram4f: RAMB16_S2_S2 port map (ADDRB => rd_addr_full(12 downto 0),  
                    ADDRA=> wr_addr(12 downto 0),
                    DIA => wr_sof_eof,  DIB => gnd_bus(1 downto 0) ,
                    WEA => pwr, WEB => gnd, CLKA => wr_clk, 
                    CLKB => rd_clk, SSRA => gnd, SSRB => gnd, 
                    ENA => c_wr_en(i), ENB => rd_allow, 
                    DOB => rd_sof_eof_grp(RD_SOF_EOF_WIDTH*(i+1)-1 
                                          downto RD_SOF_EOF_WIDTH*i)); 
                                          
                rd_sof_eof_p(i) <= rd_sof_eof_grp(RD_SOF_EOF_WIDTH *(i+1)-1 
                                              downto RD_SOF_EOF_WIDTH*i);  
                c_wr_en(i) <= ram_wr_en(i*8) or ram_wr_en(i*8+1) 
                                         or ram_wr_en(i*8+2) 
                                         or ram_wr_en(i*8+3) or ram_wr_en(i*8+4) 
                                         or ram_wr_en(i*8+5) or ram_wr_en(i*8+6) 
                                         or ram_wr_en(i*8+7);
            end generate BRAM_gen_4dda;
            
            rd_sof_eof <= rd_sof_eof_p(conv_integer(bram_rd_sel)/8);
            
        end generate BRAM_gen_4dd;
    end generate BRAM_gen_4b;   
end generate BRAM_gen_4;

-----------------------------------------------------------------------------

BRAM_gen_5: if WR_DWIDTH + RD_DWIDTH = 40 generate   
    BRAM_gen_5a: if RD_DWIDTH = 8 generate -- rd is 8-bit, wr is 32-bit wide
        BRAM_gen_5aa: for i in 0 to BRAM_MACRO_NUM-1 generate
            bram5a: RAMB16_S9_S36 port map (ADDRA => rd_addr_full(10 downto 0), 
            ADDRB => wr_addr_full(8 downto 0),
            DIA => gnd_bus(8 downto 1), DIPA => gnd_bus(0 downto 0),
            DIB => wr_data, DIPB => gnd_bus(4 downto 1),
            WEA => gnd, WEB => pwr, CLKA => rd_clk, 
            CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
            ENA => rd_allow_minor, ENB => ram_wr_en(i), 
            DOA => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i));
        end generate BRAM_gen_5aa;
                           
        BRAM_gen_5ab: if BRAM_MACRO_NUM < 8 generate      
            bram5b: RAMB16_S2_S9 port map (ADDRA => rd_addr_full(12 downto 0), 
                ADDRB => wr_addr_full(10 downto 0),
                DIA => gnd_bus(10 downto 9), DIB => wr_sof_eof, 
                DIPB => gnd_bus(0 downto 0),
                WEA => gnd, WEB => pwr, CLKA => rd_clk, 
                CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
                ENA => rd_allow_minor, ENB => wr_allow, 
                DOA => rd_sof_eof);                         
        end generate BRAM_gen_5ab;
      
        BRAM_gen_5ac: if BRAM_MACRO_NUM >= 8 generate      
            BRAM_gen_5ac1: for i in 0 to BRAM_MACRO_NUM/4-1 generate  
                bram5c: RAMB16_S2_S9 port map (ADDRA => rd_addr_full(12 downto 0), 
                    ADDRB => wr_addr_full(10 downto 0),
                    DIA => gnd_bus(10 downto 9), DIB => wr_sof_eof, 
                    DIPB => gnd_bus(0 downto 0),
                    WEA => gnd, WEB => pwr, CLKA => rd_clk, 
                    CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
                    ENA => rd_allow_minor, ENB => c_wr_en(i) , 
                    DOA => rd_sof_eof_grp(RD_SOF_EOF_WIDTH*(i+1)-1 
                                          downto RD_SOF_EOF_WIDTH*i));  
                                          
                rd_sof_eof_p(i) <= rd_sof_eof_grp(RD_SOF_EOF_WIDTH *(i+1)-1 
                                              downto RD_SOF_EOF_WIDTH*i);  
                c_wr_en(i) <= ram_wr_en(i*4) or ram_wr_en(i*4+1) 
                                             or ram_wr_en(i*4+2) 
                                             or ram_wr_en(i*4+3);                                 
            end generate BRAM_gen_5ac1;
            
            rd_sof_eof <= rd_sof_eof_p(conv_integer(bram_rd_sel)/4);
        end generate BRAM_gen_5ac;
    end generate BRAM_gen_5a;

-------------------------------------------------------------------------------

    BRAM_gen_5b: if RD_DWIDTH = 32 generate -- rd is 32-bit, wr is 8-bit wide
        BRAM_gen_5bb: for i in 0 to BRAM_MACRO_NUM-1 generate
            bram5d: RAMB16_S9_S36 port map (ADDRB => rd_addr_full(8 downto 0),
                ADDRA => wr_addr_full(10 downto 0),
                DIB => gnd_bus(35 downto 4), DIPB => gnd_bus(3 downto 0),
                DIA => wr_data, DIPA => wr_ctrl_rem,
                WEB => gnd, WEA => pwr, CLKB => rd_clk, 
                CLKA => wr_clk, SSRA => gnd, SSRB => gnd, 
                ENB => rd_allow, ENA => ram_wr_en(i), 
                DOB => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i),
                DOPB => rd_ctrl_rem_grp(RD_CTRL_REM_WIDTH*(i+1)-1 
                                        downto RD_CTRL_REM_WIDTH*i));
                                        
            rd_ctrl_rem_p(i) <= rd_ctrl_rem_grp(RD_CTRL_REM_WIDTH*(i+1)-1 
                                        downto RD_CTRL_REM_WIDTH*i);
        end generate BRAM_gen_5bb;
       rd_ctrl_rem <= rd_ctrl_rem_p(conv_integer(bram_rd_sel));        
                       
    bram5e: RAMB16_S2_S2 port map (ADDRB => rd_addr_full(12 downto 0),  
        ADDRA=> wr_addr(12 downto 0),
        DIA => wr_sof_eof,  DIB => gnd_bus(1 downto 0),
        WEA => pwr, WEB => gnd, CLKA => wr_clk, 
        CLKB => rd_clk, SSRA => gnd, SSRB => gnd, 
        ENA => wr_allow, ENB => rd_allow, 
        DOB => rd_sof_eof);     
    end generate BRAM_gen_5b;   
end generate BRAM_gen_5;

-------------------------------------------------------------------------------

BRAM_gen_6: if WR_DWIDTH + RD_DWIDTH = 48 generate   
    BRAM_gen_6a: if RD_DWIDTH = 16 generate  -- rd is 16-bit, wr is 32-bit wide  
        BRAM_gen_6aa: for i in 0 to BRAM_MACRO_NUM-1 generate
            bram6a: RAMB16_S18_S36 port map (ADDRA => rd_addr_full(9 downto 0), 
                ADDRB => wr_addr_full(8 downto 0),
                DIA => gnd_bus(17 downto 2), DIPA => gnd_bus(1 downto 0),
                DIB => wr_data, DIPB => wr_sof_eof,
                WEA => gnd, WEB => pwr, CLKA => rd_clk, 
                CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
                ENA => rd_allow_minor, ENB => ram_wr_en(i), 
                DOA => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i), 
                DOPA => rd_sof_eof_grp(RD_SOF_EOF_WIDTH*(i+1)-1 
                                       downto RD_SOF_EOF_WIDTH*i));
                                       
            rd_sof_eof_p(i) <= rd_sof_eof_grp(RD_SOF_EOF_WIDTH *(i+1)-1 
                                              downto RD_SOF_EOF_WIDTH*i);  
            
        end generate BRAM_gen_6aa;
            
        rd_sof_eof <= rd_sof_eof_p(conv_integer(bram_rd_sel));
                             
        bram6b: RAMB16_S1_S2 port map (ADDRA => rd_addr_full(13 downto 0), 
            ADDRB => wr_addr_full(12 downto 0),
            DIA(0) => gnd, DIB => wr_ctrl_rem, 
            WEA => gnd, WEB => pwr, CLKA => rd_clk, 
            CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
            ENA => rd_allow_minor, ENB => wr_allow, 
            DOA => rd_ctrl_rem);
    end generate BRAM_gen_6a;

-------------------------------------------------------------------------------

    BRAM_gen_6b: if RD_DWIDTH = 32 generate -- rd is 32-bit, wr is 16-bit wide
        BRAM_gen_6bb: for i in 0 to BRAM_MACRO_NUM-1 generate
            bram6c: RAMB16_S18_S36 port map (ADDRB => rd_addr_full(8 downto 0), 
                ADDRA => wr_addr_full(9 downto 0),
                DIB => gnd_bus(35 downto 4), DIPB => gnd_bus(3 downto 0),
                DIA=> wr_data, DIPA => wr_sof_eof,
                WEB => gnd, WEA => pwr, CLKB => rd_clk, 
                CLKA => wr_clk, SSRA => gnd, SSRB => gnd, 
                ENB => rd_allow, ENA => ram_wr_en(i), 
                DOB => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i), 
                DOPB => rd_sof_eof_grp(RD_SOF_EOF_WIDTH*(i+1)-1 
                                       downto RD_SOF_EOF_WIDTH*i));

            rd_sof_eof_p(i) <= rd_sof_eof_grp(RD_SOF_EOF_WIDTH *(i+1)-1 
                                              downto RD_SOF_EOF_WIDTH*i);  
        end generate BRAM_gen_6bb;
            
        rd_sof_eof <= rd_sof_eof_p(conv_integer(bram_rd_sel));
 
        bram6d: RAMB16_S2_S2 port map (ADDRB => rd_addr_full(12 downto 0), 
            ADDRA => wr_addr(12 downto 0),
            DIB => gnd_bus(1 downto 0), DIA=> wr_ctrl_rem, 
            WEB => gnd, WEA => pwr, CLKB => rd_clk, 
            CLKA => wr_clk, SSRA => gnd, SSRB => gnd, 
            ENB => rd_allow, ENA => wr_allow, 
            DOB => rd_ctrl_rem);
    end generate BRAM_gen_6b;   
end generate BRAM_gen_6;

-------------------------------------------------------------------------------

BRAM_gen_7: if WR_DWIDTH + RD_DWIDTH = 72 generate   
    BRAM_gen_7a: if RD_DWIDTH = 8  generate -- rd is 8-bit, wr is 64-bit wide   
        BRAM_gen_7aa: for i in 0 to BRAM_MACRO_NUM-1 generate
            bram7a: BRAM_S8_S72 port map (ADDRA => rd_addr_full(11 downto 0), 
                ADDRB => wr_addr_full(8 downto 0),
                DIA => gnd_bus(7 downto 0), DIB => wr_data, 
                DIPB => gnd_bus(15 downto 8),
                WEA => gnd, WEB => pwr,
                CLKA => rd_clk, CLKB => wr_clk,
                SSRA => gnd, SSRB => gnd,
                ENA => rd_allow_minor, ENB => ram_wr_en(i),
                DOA => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i));
        end generate BRAM_gen_7aa;
              
        BRAM_gen_7ab: if BRAM_MACRO_NUM < 4 generate      
            bram7b: RAMB16_S2_S18 port map (ADDRA => rd_addr_full(12 downto 0), 
                ADDRB => wr_addr_full(9 downto 0),
                DIA => gnd_bus(1 downto 0),
                DIB => wr_sof_eof, DIPB => gnd_bus(3 downto 2),
                WEA => gnd, WEB => pwr,
                CLKA => rd_clk, CLKB => wr_clk,
                SSRA => gnd, SSRB => gnd,
                ENA => rd_allow_minor, ENB => wr_allow,
                DOA => rd_sof_eof);   
        end generate BRAM_gen_7ab;
      
        BRAM_gen_7ac: if BRAM_MACRO_NUM >= 4 generate            
            BRAM_gen_7ac1: for i in 0 to BRAM_MACRO_NUM/2-1 generate  
                bram7c: RAMB16_S2_S18 port map (ADDRA => rd_addr_full(12 downto 0), 
                ADDRB => wr_addr_full(9 downto 0),
                DIA => gnd_bus(1 downto 0),
                DIB => wr_sof_eof, DIPB => gnd_bus(3 downto 2),
                WEA => gnd, WEB => pwr,
                CLKA => rd_clk, CLKB => wr_clk,
                SSRA => gnd, SSRB => gnd,
                ENA => rd_allow_minor, ENB => c_wr_en(i),  
                DOA => rd_sof_eof_grp(RD_SOF_EOF_WIDTH*(i+1)-1 
                                      downto RD_SOF_EOF_WIDTH*i));
                                      
            rd_sof_eof_p(i) <= rd_sof_eof_grp(RD_SOF_EOF_WIDTH *(i+1)-1 
                                              downto RD_SOF_EOF_WIDTH*i); 
             c_wr_en(i) <= ram_wr_en(i*2) or ram_wr_en(i*2+1);                                 
            end generate BRAM_gen_7ac1;
            
            rd_sof_eof <= rd_sof_eof_p(conv_integer(bram_rd_sel)/2); 
            
        end generate BRAM_gen_7ac;
    end generate BRAM_gen_7a;
   
-------------------------------------------------------------------------------

    BRAM_gen_7b: if RD_DWIDTH = 64  generate -- rd is 64-bit, wr is 8-bit wide   
        BRAM_gen_7bb: for i in 0 to BRAM_MACRO_NUM-1 generate
            bram7d: BRAM_S8_S72 port map (ADDRB => rd_addr_full(8 downto 0), 
                ADDRA => wr_addr_full(11 downto 0),
                DIB => gnd_bus(63 downto 0), DIA => wr_data, 
                DIPB => gnd_bus(71 downto 64),
                WEB => gnd, WEA => pwr,
                CLKB => rd_clk, CLKA => wr_clk,
                SSRA => gnd, SSRB => gnd,
                ENB => rd_allow, ENA => ram_wr_en(i),
                DOB => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i));
        end generate BRAM_gen_7bb;
                  
        c_wr_temp <= "000" & wr_ctrl_rem & wr_sof_eof;
        rd_sof_eof <= c_rd_temp(1 downto 0);
        rd_ctrl_rem <= c_rd_temp(4 downto 2);
      
        BRAM_gen_7cc: if BRAM_MACRO_NUM <= 4 generate   
            bram7e: RAMB16_S9_S9 port map (ADDRB => rd_addr_full(10 downto 0), 
                ADDRA => wr_addr(10 downto 0),
                DIB => gnd_bus(7 downto 0), DIA => c_wr_temp,
                DIPA => gnd_bus(0 downto 0), DIPB => gnd_bus(0 downto 0),
                WEB => gnd, WEA => pwr,
                CLKB => rd_clk, CLKA => wr_clk,
                SSRA => gnd, SSRB => gnd,
                ENB => rd_allow, ENA => wr_allow,
                DOB => c_rd_temp);   
        end generate BRAM_gen_7cc;
      
        BRAM_gen_7dd: if BRAM_MACRO_NUM > 4 generate      
            BRAM_gen_7dda: for i in 0 to BRAM_MACRO_NUM/2 -1 generate
                bram7f: RAMB16_S9_S9 port map (ADDRB => rd_addr_full(10 downto 0), 
                ADDRA => wr_addr(10 downto 0),
                DIB => gnd_bus(7 downto 0), DIA => c_wr_temp,
                DIPA => gnd_bus(0 downto 0), DIPB => gnd_bus(0 downto 0),
                WEB => gnd, WEA => pwr,
                CLKB => rd_clk, CLKA => wr_clk,
                SSRA => gnd, SSRB => gnd,
                ENB => rd_allow, ENA => c_wr_en(i),
                DOB => c_rd_ctrl_grp(8*(i+1)-1 downto 8*i));   
 
                c_wr_en(i) <= ram_wr_en(i*2) or ram_wr_en(i*2+1);                                 
                rd_ctrl_p(i) <= c_rd_ctrl_grp(8*(i+1) -1 downto 8*i);
        
            end generate BRAM_gen_7dda;
            c_rd_temp <= rd_ctrl_p(conv_integer(bram_rd_sel)/2);
        end generate BRAM_gen_7dd;
    end generate BRAM_gen_7b;   
end generate BRAM_gen_7;

--------------------------------------------------------------------------------   

BRAM_gen_9: if WR_DWIDTH + RD_DWIDTH = 80 generate   
    BRAM_gen_9a: if RD_DWIDTH = 16  generate  -- rd is 16-bit, wr is 64-bit wide  
        BRAM_gen_9aa: for i in 0 to BRAM_MACRO_NUM-1 generate
            bram9a: BRAM_S18_S72 port map (ADDRA => rd_addr_full(10 downto 0), 
                ADDRB => wr_addr_full(8 downto 0),
                DIA => gnd_bus(15 downto 0),DIPA => gnd_bus(17 downto 16),
                DIB => wr_data, DIPB => wr_sof_eof ,
                WEA => gnd, WEB => pwr,
                CLKA => rd_clk, CLKB => wr_clk,
                SSRA => gnd, SSRB => gnd,
                ENA => rd_allow_minor, ENB => ram_wr_en(i),
                DOA => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i), 
                DOPA => rd_sof_eof_grp(RD_SOF_EOF_WIDTH*(i+1)-1 
                                       downto RD_SOF_EOF_WIDTH*i));
            rd_sof_eof_p(i) <= rd_sof_eof_grp(RD_SOF_EOF_WIDTH *(i+1)-1 
                                              downto RD_SOF_EOF_WIDTH*i);  
        end generate BRAM_gen_9aa;
        rd_sof_eof <= rd_sof_eof_p(conv_integer(bram_rd_sel)); 
                
        BRAM_gen_9ab: if BRAM_MACRO_NUM < 16 generate      
            bram9b: RAMB16_S1_S4 port map (ADDRA => rd_addr_full(13 downto 0),
                ADDRB => wr_addr_full(11 downto 0),
                DIA => gnd_bus(0 downto 0), DIB => wr_ctrl_rem, 
                WEA => gnd, WEB => pwr, CLKA => rd_clk, 
                CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
                ENA => rd_allow_minor, ENB => wr_allow, 
                DOA => rd_ctrl_rem);
        end generate BRAM_gen_9ab;
 
        BRAM_gen_9ac: if BRAM_MACRO_NUM >= 16 generate      
            c_rd_allow1 <= rd_allow_minor and rd_addr_full(14);
            c_rd_allow2 <= rd_allow_minor and not c_rd_allow1 ;
            
            c_wr_allow1 <= wr_allow and wr_addr_full(12);
            c_wr_allow2 <= wr_allow and not c_wr_allow1;
            rd_ctrl_rem <= c_rd_ctrl_rem1 when rd_addr_full_r(14) = '1' else c_rd_ctrl_rem2;
                   
            bram9c: RAMB16_S1_S4 port map (ADDRA => rd_addr_full(13 downto 0), 
                ADDRB => wr_addr_full(11 downto 0),
                DIA => gnd_bus(0 downto 0), DIB => wr_ctrl_rem, 
                WEA => gnd, WEB => pwr, CLKA => rd_clk, 
                CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
                ENA => c_rd_allow1, ENB => c_wr_allow1, 
                DOA => c_rd_ctrl_rem1);
         
            bram9d: RAMB16_S1_S4 port map (ADDRA => rd_addr_full(13 downto 0), 
                ADDRB => wr_addr_full(11 downto 0),
                DIA => gnd_bus(0 downto 0), DIB => wr_ctrl_rem, 
                WEA => gnd, WEB => pwr, CLKA => rd_clk, 
                CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
                ENA => c_rd_allow2, ENB => c_wr_allow2, 
                DOA => c_rd_ctrl_rem2);
        end generate BRAM_gen_9ac;
    end generate BRAM_gen_9a;  
   
-------------------------------------------------------------------------------

    BRAM_gen_9b: if RD_DWIDTH = 64  generate -- rd is 64-bit, wr is 16-bit wide   
        BRAM_gen_9bb: for i in 0 to BRAM_MACRO_NUM-1 generate
            bram9e: BRAM_S18_S72 port map (ADDRB => rd_addr_full(8 downto 0), 
                ADDRA => wr_addr_full(10 downto 0),
                DIA => wr_data, DIPA => wr_sof_eof,
                DIB => gnd_bus(63 downto 0), DIPB => gnd_bus(71 downto 64),
                WEB => gnd, WEA => pwr,
                CLKB => rd_clk, CLKA => wr_clk,
                SSRA => gnd, SSRB => gnd,
                ENB => rd_allow, ENA => ram_wr_en(i),
                DOB => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i),
                DOPB => rd_sof_eof_grp(RD_SOF_EOF_WIDTH*(i+1)-1 
                                       downto RD_SOF_EOF_WIDTH*i));
                                  
            rd_sof_eof_p(i) <= rd_sof_eof_grp(RD_SOF_EOF_WIDTH *(i+1)-1 
                                              downto RD_SOF_EOF_WIDTH*i);  
        end generate BRAM_gen_9bb;
       
            
        rd_sof_eof <= rd_sof_eof_p(conv_integer(bram_rd_sel)); 
          
      BRAM_gen_9cc: if BRAM_MACRO_NUM <= 8 generate
         bram9f: RAMB16_S4_S4 port map (ADDRB => rd_addr_full(11 downto 0), 
          ADDRA => wr_addr(11 downto 0),
          DIB => gnd_bus(3 downto 0), DIA => wr_ctrl_rem,
          WEB => gnd, WEA => pwr,
          CLKB => rd_clk, CLKA => wr_clk,
          SSRA => gnd, SSRB => gnd,
          ENB =>  rd_allow, ENA => wr_allow,  
          DOB => rd_ctrl_rem);   
      end generate BRAM_gen_9cc;
      
      BRAM_gen_9dd: if BRAM_MACRO_NUM > 8 generate      
         c_rd_allow1 <= rd_allow and rd_addr_full(12);
         c_rd_allow2 <= rd_allow and not c_rd_allow1;
         
         c_wr_allow1 <= wr_allow and wr_addr(12);
         c_wr_allow2 <= wr_allow and not c_wr_allow1;
         
         rd_ctrl_rem <= c_rd_ctrl_rem1 when rd_addr_full_r(12) = '1' else c_rd_ctrl_rem2;
        
         bram9g: RAMB16_S4_S4 port map (ADDRB => rd_addr_full(11 downto 0),
           ADDRA => wr_addr(11 downto 0),
           DIA => wr_ctrl_rem, DIB => gnd_bus(3 downto 0),            
           WEB => gnd, WEA => pwr,
           CLKB => rd_clk, CLKA => wr_clk,
           SSRA => gnd, SSRB => gnd,
           ENB => c_rd_allow1, ENA => c_wr_allow1,
           DOB => c_rd_ctrl_rem1);
           
         bram9h: RAMB16_S4_S4 port map (ADDRB => rd_addr_full(11 downto 0), 
           ADDRA => wr_addr(11 downto 0),
           DIA => wr_ctrl_rem, DIB => gnd_bus(3 downto 0),            
           WEB => gnd, WEA => pwr,
           CLKB => rd_clk, CLKA => wr_clk,
           SSRA => gnd, SSRB => gnd,
           ENB => c_rd_allow2, ENA => c_wr_allow2,
           DOB => c_rd_ctrl_rem2);
      end generate BRAM_gen_9dd;
    end generate BRAM_gen_9b;
   end generate BRAM_gen_9;

-------------------------------------------------------------------------------

BRAM_gen_8: if WR_DWIDTH + RD_DWIDTH = 96 generate   
    BRAM_gen_8a: if RD_DWIDTH = 32  generate  -- rd is 32-bit, wr is 64-bit wide  
        BRAM_gen_8aa: for i in 0 to BRAM_MACRO_NUM-1 generate
            bram8a: BRAM_S36_S72 port map (ADDRA => rd_addr_full(9 downto 0),
                ADDRB => wr_addr_full(8 downto 0),
                DIA => gnd_bus(31 downto 0),DIPA => gnd_bus(35 downto 32),
                DIB => wr_data, DIPB => wr_sof_eof ,
                WEA => gnd, WEB => pwr,
                CLKA => rd_clk, CLKB => wr_clk,
                SSRA => gnd, SSRB => gnd,
                ENA => rd_allow_minor, ENB => ram_wr_en(i),
                DOA => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i), 
                DOPA => rd_sof_eof_grp(RD_SOF_EOF_WIDTH*(i+1)-1 
                                       downto RD_SOF_EOF_WIDTH*i));
                                       
            rd_sof_eof_p(i) <= rd_sof_eof_grp(RD_SOF_EOF_WIDTH *(i+1)-1 
                                              downto RD_SOF_EOF_WIDTH*i);              
        end generate BRAM_gen_8aa;
        rd_sof_eof <= rd_sof_eof_p(conv_integer(bram_rd_sel));
    end generate BRAM_gen_8a;   

-------------------------------------------------------------------------------

    BRAM_gen_8b: if RD_DWIDTH = 64  generate -- rd is 64-bit, wr is 32-bit wide   
        BRAM_gen_8bb: for i in 0 to BRAM_MACRO_NUM-1 generate
            bram8b: BRAM_S36_S72 port map (ADDRB => rd_addr_full(8 downto 0), 
                ADDRA => wr_addr_full(9 downto 0),
                DIA => wr_data, DIPA => wr_sof_eof,
                DIB => gnd_bus(63 downto 0), DIPB => gnd_bus(71 downto 64),
                WEB => gnd, WEA => pwr,
                CLKB => rd_clk, CLKA => wr_clk,
                SSRA => gnd, SSRB => gnd,
                ENB => rd_allow, ENA => ram_wr_en(i),
                DOB => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i),
                DOPB => rd_sof_eof_grp(RD_SOF_EOF_WIDTH*(i+1)-1 
                                       downto RD_SOF_EOF_WIDTH*i));
                                       
            rd_sof_eof_p(i) <= rd_sof_eof_grp(RD_SOF_EOF_WIDTH *(i+1)-1 
                                              downto RD_SOF_EOF_WIDTH*i);  
            
        end generate BRAM_gen_8bb;
        rd_sof_eof <= rd_sof_eof_p(conv_integer(bram_rd_sel));
          
        BRAM_gen_8cc: if BRAM_MACRO_NUM <= 8 generate
            bram8c: RAMB16_S4_S4 port map (ADDRB => rd_addr_full(11 downto 0), 
                ADDRA => wr_addr(11 downto 0),
                DIA => wr_ctrl_rem, DIB => gnd_bus(3 downto 0),            
                WEB => gnd, WEA => pwr,
                CLKB => rd_clk, CLKA => wr_clk,
                SSRA => gnd, SSRB => gnd,
                ENB => rd_allow, ENA => wr_allow,
                DOB => rd_ctrl_rem);
        end generate BRAM_gen_8cc;
      
        BRAM_gen_8dd: if BRAM_MACRO_NUM > 8 generate                  
            c_rd_allow1 <= rd_allow and rd_addr_full(12);
            c_rd_allow2 <= rd_allow and not c_rd_allow1;
            
            rd_ctrl_rem <= c_rd_ctrl_rem1 when rd_addr_full_r(12) = '1' else c_rd_ctrl_rem2;
            c_wr_allow1 <= wr_allow and wr_addr(12);
            c_wr_allow2 <= wr_allow and not c_wr_allow1;

        
            bram8d: RAMB16_S4_S4 port map (ADDRB => rd_addr_full(11 downto 0),
                ADDRA => wr_addr(11 downto 0),
                DIA => wr_ctrl_rem, DIB => gnd_bus(3 downto 0),            
                WEB => gnd, WEA => pwr,
                CLKB => rd_clk, CLKA => wr_clk,
                SSRA => gnd, SSRB => gnd,
                ENB => c_rd_allow1, ENA => c_wr_allow1,
                DOB => c_rd_ctrl_rem1);
                
            bram8e: RAMB16_S4_S4 port map (ADDRB => rd_addr_full(11 downto 0), 
                ADDRA => wr_addr(11 downto 0),
                DIA => wr_ctrl_rem, DIB => gnd_bus(3 downto 0),            
                WEB => gnd, WEA => pwr,
                CLKB => rd_clk, CLKA => wr_clk,
                SSRA => gnd, SSRB => gnd,
                ENB => c_rd_allow2, ENA => c_wr_allow2,
                DOB => c_rd_ctrl_rem2);
        end generate BRAM_gen_8dd;
    end generate BRAM_gen_8b;   
end generate BRAM_gen_8;

   
-------------------------------------------------------------------------------

BRAM_gen_10: if WR_DWIDTH + RD_DWIDTH = 136 generate   
    BRAM_gen_10a: if RD_DWIDTH = 8  generate  -- rd is 8-bit, wr is 128-bit wide  
        BRAM_gen_10aa: for i in 0 to BRAM_MACRO_NUM-1 generate
            bram10a: BRAM_S8_S144 port map (ADDRA => rd_addr_full(12 downto 0), -- Data FIFO
                ADDRB => wr_addr_full(8 downto 0),
                DIA => gnd_bus(7 downto 0), DIB => wr_data, 
                DIPB => gnd_bus(15 downto 0),
                WEA => gnd, WEB => pwr,
                CLKA => rd_clk, CLKB => wr_clk,
                SSRA => gnd, SSRB => gnd,
                ENA => rd_allow_minor, ENB => ram_wr_en(i),
                DOA => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i));
          
            bram10b: RAMB16_S2_S36 port map (ADDRA => rd_addr_full(12 downto 0), -- Control FIFO 
                ADDRB => wr_addr_full(8 downto 0),
                DIA => gnd_bus(1 downto 0),
                DIB => wr_sof_eof, DIPB => gnd_bus(3 downto 0),
                WEA => gnd, WEB => pwr,
                CLKA => rd_clk, CLKB => wr_clk,
                SSRA => gnd, SSRB => gnd,
                ENA => rd_allow_minor, ENB =>  ram_wr_en(i),
                DOA => rd_sof_eof_grp(RD_SOF_EOF_WIDTH*(i+1)-1 downto RD_SOF_EOF_WIDTH*i));    
                
            rd_sof_eof_p(i) <= rd_sof_eof_grp(RD_SOF_EOF_WIDTH *(i+1)-1 
                                              downto RD_SOF_EOF_WIDTH*i);  
            
        end generate BRAM_gen_10aa;
        rd_sof_eof <= rd_sof_eof_p(conv_integer(bram_rd_sel));
    end generate BRAM_gen_10a;      

-------------------------------------------------------------------------------

    BRAM_gen_10b: if RD_DWIDTH = 128  generate -- rd is 128-bit, wr is 8-bit wide   
        BRAM_gen_10bb: for i in 0 to BRAM_MACRO_NUM-1 generate  
            bram10c: BRAM_S8_S144 port map (ADDRB => rd_addr_full(8 downto 0), -- Data FIFO
                ADDRA => wr_addr_full(12 downto 0),
                DIB => gnd_bus(127 downto 0), DIA => wr_data, 
                DIPB => gnd_bus(15 downto 0),
                WEB => gnd, WEA => pwr,
                CLKB => rd_clk, CLKA => wr_clk,
                SSRA => gnd, SSRB => gnd,
                ENB => rd_allow, ENA => ram_wr_en(i),
                DOB => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i));
        end generate BRAM_gen_10bb;
               
        c_wr_temp <= "00" & wr_ctrl_rem & wr_sof_eof;
        rd_sof_eof <= c_rd_temp(1 downto 0);
        rd_ctrl_rem <= c_rd_temp(5 downto 2);
      
       
        BRAM_gen_10cc: if BRAM_MACRO_NUM < 8 generate   
            bram10d: RAMB16_S9_S9 port map (ADDRB => rd_addr_full(10 downto 0),   -- Control FIFO
                ADDRA => wr_addr(10 downto 0),
                DIB => gnd_bus(7 downto 0), DIA => c_wr_temp,
                DIPA => gnd_bus(0 downto 0), DIPB => gnd_bus(0 downto 0),
                WEB => gnd, WEA => pwr,
                CLKB => rd_clk, CLKA => wr_clk,
                SSRA => gnd, SSRB => gnd,
                ENB => rd_allow, ENA => wr_allow,
                DOB => c_rd_temp);   
        end generate BRAM_gen_10cc;
      
        BRAM_gen_10dd: if BRAM_MACRO_NUM >= 8 generate      
            BRAM_gen_10dda: for i in 0 to BRAM_MACRO_NUM/4 -1 generate
                bram10e: RAMB16_S9_S9 port map (ADDRB => rd_addr_full(10 downto 0), -- Control FIFO
                    ADDRA => wr_addr(10 downto 0),
                    DIB => gnd_bus(7 downto 0), DIA => c_wr_temp,
                    DIPA => gnd_bus(0 downto 0), DIPB => gnd_bus(0 downto 0),
                    WEB => gnd, WEA => pwr,
                    CLKB => rd_clk, CLKA => wr_clk,
                    SSRA => gnd, SSRB => gnd,
                    ENB => rd_allow, ENA => c_wr_en(i),
                    DOB => c_rd_ctrl_grp(8*(i+1)-1 downto 8*i));
              
                c_wr_en(i) <= ram_wr_en(i*4) or ram_wr_en(i*4+1) 
                        or ram_wr_en(i*4+2) or ram_wr_en(i*4+3) ;                                 
                rd_ctrl_p(i) <= c_rd_ctrl_grp(8*(i+1) -1 downto 8*i);
            end generate BRAM_gen_10dda;
            c_rd_temp <= rd_ctrl_p(conv_integer(bram_rd_sel)/4);
        end generate BRAM_gen_10dd;
    end generate BRAM_gen_10b;   
end generate BRAM_gen_10;     
      
-----------------------------------------------------------------------------

BRAM_gen_11: if WR_DWIDTH + RD_DWIDTH = 144 generate -- rd is 16-bit, wr is 128-bit wide  
   BRAM_gen_11a: if RD_DWIDTH = 16 generate    
      BRAM_gen_11aa: for i in 0 to BRAM_MACRO_NUM-1 generate
         bram11a: BRAM_S16_S144 port map (ADDRA => rd_addr_full(11 downto 0), 
          ADDRB => wr_addr_full(8 downto 0),
          DIA => gnd_bus(15 downto 0),
          DIB => wr_data, DIPB => gnd_bus(15 downto 0) ,
          WEA => gnd, WEB => pwr,
          CLKA => rd_clk, CLKB => wr_clk,
          SSRA => gnd, SSRB => gnd,
          -- ENA => pwr, ENB => ram_wr_en(i),
          ENA => rd_allow_minor, ENB => ram_wr_en(i),  -- DH: fixed read enable to handle dst_rdy
          DOA => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i));
          
         bram11b: RAMB16_S4_S36 port map (ADDRA => rd_addr_full(11 downto 0), 
            ADDRB => wr_addr_full(8 downto 0),
            DIA => gnd_bus(3 downto 0),
            DIB => wr_sof_eof, DIPB => gnd_bus(3 downto 0),
            WEA => gnd, WEB => pwr,
            CLKA => rd_clk, CLKB => wr_clk,
            SSRA => gnd, SSRB => gnd,
            -- ENA => pwr, ENB => ram_wr_en(i), 
            ENA => rd_allow_minor, ENB => ram_wr_en(i), -- DH: fixed read enable to handle dst_rdy
            DOA => c_rd_ctrl_grp(4*(i+1)-1 downto 4*i));  
            
         rd_ctrl_p(i) <= c_rd_ctrl_grp(4*(i+1) -1 downto 4*i);
      end generate BRAM_gen_11aa;
         
      c_rd_temp <= rd_ctrl_p(conv_integer(bram_rd_sel));
           
      rd_sof_eof <= c_rd_temp(1 downto 0);
      rd_ctrl_rem <= c_rd_temp(2 downto 2);
   end generate BRAM_gen_11a;

-------------------------------------------------------------------------------

   BRAM_gen_11b: if RD_DWIDTH = 128 generate -- rd is 128-bit, wr is 16-bit wide   
      BRAM_gen_11bb: for i in 0 to BRAM_MACRO_NUM-1 generate
         bram11c: BRAM_S16_S144 port map (ADDRB => rd_addr_full(8 downto 0), 
          ADDRA => wr_addr_full(11 downto 0),
          DIB => gnd_bus(127 downto 0), DIA => wr_data, DIPB => gnd_bus(15 downto 0),
          WEB => gnd, WEA => pwr,
          CLKB => rd_clk, CLKA => wr_clk,
          SSRA => gnd, SSRB => gnd,
          ENB => rd_allow, ENA => ram_wr_en(i),
          DOB => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i));
      end generate BRAM_gen_11bb;
               
      c_wr_temp <= "00" & wr_ctrl_rem & wr_sof_eof;
      rd_sof_eof <= c_rd_temp(1 downto 0);
      rd_ctrl_rem <= c_rd_temp(5 downto 2);
      
       
      BRAM_gen_11cc: if BRAM_MACRO_NUM < 8 generate   
         bram11d: RAMB16_S9_S9 port map (ADDRB => rd_addr_full(10 downto 0),
            ADDRA => wr_addr(10 downto 0),
            DIB => gnd_bus(7 downto 0), DIA => c_wr_temp,
            DIPA => gnd_bus(0 downto 0), DIPB => gnd_bus(0 downto 0),
            WEB => gnd, WEA => pwr,
            CLKB => rd_clk, CLKA => wr_clk,
            SSRA => gnd, SSRB => gnd,
            ENB => rd_allow, ENA => wr_allow,
            DOB => c_rd_temp);   
      end generate BRAM_gen_11cc;
      
      BRAM_gen_11dd: if BRAM_MACRO_NUM >= 8 generate      
         BRAM_gen_11dda: for i in 0 to BRAM_MACRO_NUM/4 -1 generate
            bram11e: RAMB16_S9_S9 port map (ADDRB => rd_addr_full(10 downto 0),
              ADDRA => wr_addr(10 downto 0),
              DIB => gnd_bus(7 downto 0), DIA => c_wr_temp,
              DIPA => gnd_bus(0 downto 0), DIPB => gnd_bus(0 downto 0),
              WEB => gnd, WEA => pwr,
              CLKB => rd_clk, CLKA => wr_clk,
              SSRA => gnd, SSRB => gnd,
              ENB => rd_allow, ENA => c_wr_en(i),
              DOB => c_rd_ctrl_grp(8*(i+1)-1 downto 8*i));
              
            c_wr_en(i) <= ram_wr_en(i*4) or ram_wr_en(i*4+1) 
                        or ram_wr_en(i*4+2) or ram_wr_en(i*4+3) ;                                 
            rd_ctrl_p(i) <= c_rd_ctrl_grp(8*(i+1) -1 downto 8*i);
         end generate BRAM_gen_11dda;
            c_rd_temp <= rd_ctrl_p(conv_integer(bram_rd_sel)/4);
      end generate BRAM_gen_11dd;
   end generate BRAM_gen_11b;
end generate BRAM_gen_11;

-----------------------------------------------------------------------------

BRAM_gen_12: if WR_DWIDTH + RD_DWIDTH = 160 generate   
   BRAM_gen_12a: if RD_DWIDTH = 32 generate  -- rd is 32-bit, wr is 128-bit wide  
      BRAM_gen_12aa: for i in 0 to BRAM_MACRO_NUM-1 generate
         bram12a: BRAM_S36_S144 port map (ADDRA => rd_addr_full(10 downto 0),
          ADDRB => wr_addr_full(8 downto 0),
          DIA => gnd_bus(31 downto 0),DIPA => gnd_bus(35 downto 32),
          DIB => wr_data, DIPB => wr_ctrl_rem ,
          WEA => gnd, WEB => pwr,
          CLKA => rd_clk, CLKB => wr_clk,
          SSRA => gnd, SSRB => gnd,
          ENA => rd_allow_minor, ENB => ram_wr_en(i),
          DOA => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i),
          DOPA => rd_ctrl_rem_grp(RD_CTRL_REM_WIDTH * (i+1) -1 downto RD_CTRL_REM_WIDTH*i));
      end generate BRAM_gen_12aa;
      
      BRAM_gen_12ab: if BRAM_MACRO_NUM < 8 generate      
         bram12b: RAMB16_S2_S9 port map (ADDRA => rd_addr_full(12 downto 0), 
              ADDRB => wr_addr_full(10 downto 0),
              DIA => gnd_bus(10 downto 9), DIB => wr_sof_eof, DIPB => gnd_bus(0 downto 0),
              WEA => gnd, WEB => pwr, CLKA => rd_clk, 
              CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
              ENA => rd_allow_minor, ENB => wr_allow, 
              DOA => rd_sof_eof);                         
      end generate BRAM_gen_12ab;    
      
        BRAM_gen_12ac: if BRAM_MACRO_NUM >= 8 generate      
            BRAM_gen_12ac1: for i in 0 to BRAM_MACRO_NUM/4-1 generate  
                bram12c: RAMB16_S2_S9 port map (ADDRA => rd_addr_full(12 downto 0), 
                    ADDRB => wr_addr_full(10 downto 0),
                    DIA => gnd_bus(10 downto 9), DIB => wr_sof_eof, 
                    DIPB => gnd_bus(0 downto 0),
                    WEA => gnd, WEB => pwr, CLKA => rd_clk, 
                    CLKB => wr_clk, SSRA => gnd, SSRB => gnd, 
                    ENA => rd_allow_minor, ENB => c_wr_en(i), 
                    DOA => rd_sof_eof_grp(RD_SOF_EOF_WIDTH*(i+1)-1 
                                          downto RD_SOF_EOF_WIDTH*i)); 
                                          
            rd_sof_eof_p(i) <= rd_sof_eof_grp(RD_SOF_EOF_WIDTH *(i+1)-1 
                                              downto RD_SOF_EOF_WIDTH*i);  
          c_wr_en(i) <= ram_wr_en(i*4) or ram_wr_en(i*4+1) or ram_wr_en(i*4+2) or ram_wr_en(i*4+3) ;                                 
          
         end generate BRAM_gen_12ac1;
         
         rd_sof_eof <= rd_sof_eof_p(conv_integer(bram_rd_sel)/4);
         
      end generate BRAM_gen_12ac;      
      
   end generate BRAM_gen_12a;   

-------------------------------------------------------------------------------

   BRAM_gen_12b: if RD_DWIDTH = 128  generate  -- rd is 128-bit, wr is 32-bit wide  
      BRAM_gen_12ba: for i in 0 to BRAM_MACRO_NUM-1 generate
         bram12d: BRAM_S36_S144 port map (ADDRB => rd_addr_full(8 downto 0), 
           ADDRA => wr_addr_full(10 downto 0),
           DIA => wr_data, DIPA => wr_ctrl_rem,
           DIB => gnd_bus(127 downto 0), DIPB => gnd_bus(15 downto 0),
           WEB => gnd, WEA => pwr,
           CLKB => rd_clk, CLKA => wr_clk,
           SSRA => gnd, SSRB => gnd,
           ENB => rd_allow, ENA => ram_wr_en(i),
           DOB => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i),
           DOPB => rd_ctrl_rem_grp(RD_CTRL_REM_WIDTH * (i+1) -1 downto RD_CTRL_REM_WIDTH*i));
      end generate BRAM_gen_12ba;

      BRAM_gen_12bb: if BRAM_MACRO_NUM < 8 generate      
         bram12e: RAMB16_S2_S9 port map (ADDRB => rd_addr_full(10 downto 0), 
           ADDRA => wr_addr_full(12 downto 0),
           DIA => wr_sof_eof, DIB => gnd_bus(7 downto 0),            
           DIPB => gnd_bus(0 downto 0),
           WEB => gnd, WEA => pwr,
           CLKB => rd_clk, CLKA => wr_clk,
           SSRA => gnd, SSRB => gnd,
           ENB => rd_allow, ENA => wr_allow_minor,
           DOB => rd_sof_eof);
      end generate BRAM_gen_12bb;    

      BRAM_gen_12bc: if BRAM_MACRO_NUM >= 8 generate      
          BRAM_gen_12bc1: for i in 0 to BRAM_MACRO_NUM/4-1 generate  
              bram12e: RAMB16_S2_S9 port map (ADDRB => rd_addr_full(10 downto 0), 
                ADDRA => wr_addr_full(12 downto 0),
                DIA => wr_sof_eof, DIB => gnd_bus(7 downto 0),            
                DIPB => gnd_bus(0 downto 0),
                WEB => gnd, WEA => pwr,
                CLKB => rd_clk, CLKA => wr_clk,
                SSRA => gnd, SSRB => gnd,
                ENB => rd_allow, ENA =>  c_wr_en(i),
                DOB => rd_sof_eof_grp(RD_SOF_EOF_WIDTH*(i+1)-1 
                                          downto RD_SOF_EOF_WIDTH*i)); 
            rd_sof_eof_p(i) <= rd_sof_eof_grp(RD_SOF_EOF_WIDTH *(i+1)-1 
                                              downto RD_SOF_EOF_WIDTH*i);  
          c_wr_en(i) <= ram_wr_en(i*4) or ram_wr_en(i*4+1) or ram_wr_en(i*4+2) or ram_wr_en(i*4+3) ;                                 
          
         end generate BRAM_gen_12bc1;
         
         rd_sof_eof <= rd_sof_eof_p(conv_integer(bram_rd_sel)/4);
      end generate BRAM_gen_12bc;      
    end generate BRAM_gen_12b;   
end generate BRAM_gen_12;

-------------------------------------------------------------------------------

BRAM_gen_13: if WR_DWIDTH + RD_DWIDTH = 192 generate   
   BRAM_gen_13a: if RD_DWIDTH = 64 generate  -- rd is 64-bit, wr is 128-bit wide  
      BRAM_gen_13aa: for i in 0 to BRAM_MACRO_NUM-1 generate
         bram13a: BRAM_S72_S144 port map (
         ADDRA => rd_addr_full(9 downto 0),
          ADDRB => wr_addr_full(8 downto 0),
          DIA => gnd_bus(63 downto 0),DIPA => gnd_bus(7 downto 0),
          DIB => wr_data, 
          DIPB => wr_sof_eof(15 downto 0) ,
          WEA => gnd, WEB => pwr,
          CLKA => rd_clk, CLKB => wr_clk,
          SSRA => gnd, SSRB => gnd,
          ENA => rd_allow_minor, ENB => ram_wr_en(i),
          DOA => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i),
          DOPA => c_rd_ctrl_grp(8*(i+1)-1 downto 8*i));
          
          rd_ctrl_p(i) <= c_rd_ctrl_grp(8*(i+1) -1 downto 8*i);
      end generate BRAM_gen_13aa;
      c_rd_temp <= rd_ctrl_p(conv_integer(bram_rd_sel));
      
      rd_sof_eof <= c_rd_temp(1 downto 0);
      rd_ctrl_rem <= c_rd_temp(4 downto 2);
   end generate BRAM_gen_13a;

-------------------------------------------------------------------------------

   BRAM_gen_13b: if RD_DWIDTH = 128 generate -- rd is 128-bit, wr is 64-bit wide   
      BRAM_gen_13bb: for i in 0 to BRAM_MACRO_NUM-1 generate
            bram13b: BRAM_S72_S144 port map (ADDRB => rd_addr_full(8 downto 0), 
              ADDRA => wr_addr_full(9 downto 0),
              DIA => wr_data, DIPA => wr_sof_eof,
              DIB => gnd_bus(127 downto 0), DIPB => gnd_bus(15 downto 0),
              WEB => gnd, WEA => pwr,
              CLKB => rd_clk, CLKA => wr_clk,
              SSRA => gnd, SSRB => gnd,
              ENB => rd_allow, ENA => ram_wr_en(i),
              DOB => rd_data_grp(RD_DWIDTH*(i+1)-1 downto RD_DWIDTH*i),
              DOPB => c_rd_ctrl_grp(16*(i+1)-1 downto 16*i));
              
          rd_ctrl_p(i) <= c_rd_ctrl_grp(16*(i+1) -1 downto 16*i);
      end generate BRAM_gen_13bb;
      rd_sof_eof <= rd_ctrl_p(conv_integer(bram_rd_sel));
  end generate BRAM_gen_13b;
end generate BRAM_gen_13;


end BRAM_macro_hdl;