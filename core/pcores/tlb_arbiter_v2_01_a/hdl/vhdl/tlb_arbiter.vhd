------------------------------------------------------------------------------
-- TLB arbiter implementation
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library tlb_arbiter_v2_01_a;
use tlb_arbiter_v2_01_a.all;

entity tlb_arbiter is
    generic
    (
        C_TLBARB_NUM_PORTS        : integer          := 2;
        C_TAG_WIDTH               : integer          := 20;
        C_DATA_WIDTH              : integer          := 21    
    );
    port
    (
        sys_clk               : in  std_logic;
        sys_reset               : in  std_logic;
        
        -- TLB client A
        i_tag_a           : in  std_logic_vector(C_TAG_WIDTH - 1 downto 0);
        i_data_a          : in  std_logic_vector(C_DATA_WIDTH - 1 downto 0);
        o_data_a          : out std_logic_vector(C_DATA_WIDTH - 1 downto 0);
        i_request_a       : in  std_logic;
        i_we_a            : in  std_logic;
        o_match_a         : out std_logic;
        o_busy_a          : out std_logic;

        -- TLB client B
        i_tag_b           : in  std_logic_vector(C_TAG_WIDTH - 1 downto 0);
        i_data_b          : in  std_logic_vector(C_DATA_WIDTH - 1 downto 0);
        o_data_b          : out std_logic_vector(C_DATA_WIDTH - 1 downto 0);
        i_request_b       : in  std_logic;
        i_we_b            : in  std_logic;
        o_match_b         : out std_logic;
        o_busy_b          : out std_logic;
        
        -- TLB client C
        i_tag_c           : in  std_logic_vector(C_TAG_WIDTH - 1 downto 0);
        i_data_c          : in  std_logic_vector(C_DATA_WIDTH - 1 downto 0);
        o_data_c          : out std_logic_vector(C_DATA_WIDTH - 1 downto 0);
        i_request_c       : in  std_logic;
        i_we_c            : in  std_logic;
        o_match_c         : out std_logic;
        o_busy_c          : out std_logic;
        
        -- TLB client D
        i_tag_d           : in  std_logic_vector(C_TAG_WIDTH - 1 downto 0);
        i_data_d          : in  std_logic_vector(C_DATA_WIDTH - 1 downto 0);
        o_data_d          : out std_logic_vector(C_DATA_WIDTH - 1 downto 0);
        i_request_d       : in  std_logic;
        i_we_d            : in  std_logic;
        o_match_d         : out std_logic;
        o_busy_d          : out std_logic;

        -- TLB
        o_tlb_tag          : out std_logic_vector(C_TAG_WIDTH - 1 downto 0);
        i_tlb_data         : in  std_logic_vector(C_DATA_WIDTH - 1 downto 0);
        o_tlb_data         : out std_logic_vector(C_DATA_WIDTH - 1 downto 0);
        i_tlb_match        : in  std_logic;
        o_tlb_we           : out std_logic;
        i_tlb_busy         : in  std_logic
    );
end entity;

architecture imp of tlb_arbiter is
    signal active          : std_logic;
    signal counter         : std_logic_vector(1 downto 0);
    signal busy_a          : std_logic;
    signal busy_b          : std_logic;
    signal busy_c          : std_logic;
    signal busy_d          : std_logic;
begin
    o_data_a  <= i_tlb_data;
    o_data_b  <= i_tlb_data;
    o_data_c  <= i_tlb_data;
    o_data_d  <= i_tlb_data;
    o_match_a <= i_tlb_match;
    o_match_b <= i_tlb_match;
    o_match_c <= i_tlb_match;
    o_match_d <= i_tlb_match;

--	active <= busy_a = '0' or busy_b = '0';
    active <= not (busy_a and busy_b and busy_c and busy_d);

    handle_request : process(sys_clk,sys_reset)
        variable req_a : std_logic;
        variable req_b : std_logic;
        variable req_c : std_logic;
        variable req_d : std_logic;
    begin
        if sys_reset = '1' then
            busy_a <= '1';
            busy_b <= '1';
            busy_c <= '1';
            busy_d <= '1';
            counter <= (others => '0');
        elsif rising_edge(sys_clk) then
            req_a := i_request_a;
            if C_TLBARB_NUM_PORTS > 1 then req_b := i_request_b; else req_b := '0'; end if;
            if C_TLBARB_NUM_PORTS > 2 then req_c := i_request_c; else req_c := '0'; end if;
            if C_TLBARB_NUM_PORTS > 3 then req_d := i_request_d; else req_d := '0'; end if;
            if active = '1' then -- wait for end of request
                if busy_a = '0' and req_a = '0' then busy_a <= '1'; end if;
                if busy_b = '0' and req_b = '0' then busy_b <= '1'; end if;
                if busy_c = '0' and req_c = '0' then busy_c <= '1'; end if;
                if busy_d = '0' and req_d = '0' then busy_d <= '1'; end if;
            else           -- check incoming requests
                if (req_a = '1' or req_b = '1') and (req_c = '1' or req_d = '1') then
                    if counter(1) = '0' then req_c := '0'; req_d := '0'; end if;
                    if counter(1) = '1' then req_a := '0'; req_b := '0'; end if;
                end if;
                if (req_a = '1' or req_c = '1') and (req_b = '1' or req_d = '1') then
                    if counter(0) = '0' then  req_b := '0'; req_d := '0'; end if;
                    if counter(1) = '0' then  req_a := '0'; req_c := '0'; end if;
                end if;
                busy_a <= not req_a;
                busy_b <= not req_b;
                busy_c <= not req_c;
                busy_d <= not req_d;
                counter <= counter + 1;
                    
                --if    i_request_a = '1' and i_request_b = '1' then
                --	if counter = '0' then busy_a <= '0'; end if;
                --	if counter = '1' then busy_b <= '0'; end if;
                --	counter <= not counter; -- increment counter
                --elsif i_request_a = '1' and i_request_b = '0' then
                --	busy_a <= '0';
                --elsif i_request_a = '0' and i_request_b = '1' then
                --	busy_b <= '0';
                --end if;
            end if;
        end if;
    end process;
    
    tlb_mux : process(busy_a, busy_b, i_tag_a, i_tag_b, i_data_a, i_data_b, i_we_a, i_we_b, i_tlb_busy)
    begin
        o_busy_a <= '1';
        o_busy_b <= '1';
        o_busy_c <= '1';
        o_busy_d <= '1';
        if busy_a = '0' then
            o_tlb_tag   <=  i_tag_a;
            o_tlb_data  <=  i_data_a;
            o_tlb_we    <=  i_we_a;
            o_busy_a    <=  i_tlb_busy;
        elsif busy_b = '0' then
            o_tlb_tag   <=  i_tag_b;
            o_tlb_data  <=  i_data_b;
            o_tlb_we    <=  i_we_b;
            o_busy_b    <=  i_tlb_busy;
        elsif busy_c = '0' then
            o_tlb_tag   <=  i_tag_c;
            o_tlb_data  <=  i_data_c;
            o_tlb_we    <=  i_we_c;
            o_busy_c    <=  i_tlb_busy;
        elsif busy_d = '0' then
            o_tlb_tag   <=  i_tag_d;
            o_tlb_data  <=  i_data_d;
            o_tlb_we    <=  i_we_d;
            o_busy_d    <=  i_tlb_busy;
        else
            o_tlb_tag   <=  (others => '0');
            o_tlb_data  <=  (others => '0');
            o_tlb_we    <=  '0';
        end if;
    end process;

end architecture;

