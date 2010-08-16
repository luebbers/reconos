----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:02:34 07/20/2006 
-- Design Name: 
-- Module Name:    icapFIFO - icapFIFO_rtl 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity icapFIFO is
   generic (
      C_FIFO_DEPTH   : integer := 64;
      C_DIN_WIDTH    : integer := 64;
      C_DOUT_WIDTH   : integer := 8
   );
   port (
      clk      : in std_logic;
      reset    : in std_logic;
      
      wEn_i    : in std_logic;
      wData_i  : in std_logic_vector(C_DIN_WIDTH-1 downto 0);
      
      rEn_i    : in std_logic;
      rData_o  : out std_logic_vector(C_DOUT_WIDTH-1 downto 0);
      
      full_o   : out std_logic;
      empty_o  : out std_logic
   );
end icapFIFO;

architecture icapFIFO_rtl of icapFIFO is

-- A synthesizable function that returns the integer part of the base 2 logarithm for a positive number 
-- is (uses recursion) from http://tams-www.informatik.uni-hamburg.de/vhdl/doc/faq/FAQ1.html

	function log2(x:positive) return natural is
	begin
		if(x<=1) then
			return 0;
		else
			return log2(x/2)+1;
		end if;
	end function log2;

   constant C_AIN_WIDTH    : integer := log2(C_FIFO_DEPTH);								-- 6 in this case
   constant C_AOUT_WIDTH   : integer := log2(C_FIFO_DEPTH*C_DIN_WIDTH/C_DOUT_WIDTH);    -- 9 in this case
   constant C_AOUT_SPLIT   : integer := C_AOUT_WIDTH - C_AIN_WIDTH;						-- 3 in this case

   type fifo_type is array(C_FIFO_DEPTH-1 downto 0) of std_logic_vector(C_DIN_WIDTH-1 downto 0);
	signal fifo         : fifo_type;

   signal head, head_n : std_logic_vector(C_AIN_WIDTH-1 downto 0);
   signal tail, tail_n : std_logic_vector(C_AOUT_WIDTH-1 downto 0);

   signal empty, empty_p : std_logic;

   -- Add keep attribute to tail_n to prevent synthesis of both counter and adder
   attribute keep : string;
   attribute keep of tail_n : signal is "true";

   signal fData        : std_logic_vector(C_DIN_WIDTH-1 downto 0);
   type fMux_type is array(C_DIN_WIDTH/C_DOUT_WIDTH-1 downto 0) of std_logic_vector(C_DOUT_WIDTH-1 downto 0);
   signal fMux         : fMux_type;
begin
   head_n <= head+1 when(wEn_i='1') else head;
   tail_n <= tail+1 when(rEn_i='1') else tail;

   process(clk) begin
      if(clk='1' and clk'event) then
         if(reset='1') then
            head <= (others=>'0');
            tail <= (others=>'0');
         else
            head <= head_n;
            tail <= tail_n;
         end if;
-- 	    if wEn_i ='1' write wData_i to Address specified by head pointer.

         if(wEn_i='1') then
            fifo(CONV_INTEGER(UNSIGNED(head))) <= wData_i;
         end if;

--         if(wEn_i='1' and tail_n(C_AOUT_WIDTH-1 downto C_AOUT_WIDTH-C_AIN_WIDTH)=head) then
--            fData <= wData_i;
--         else
         fData <= fifo(CONV_INTEGER(UNSIGNED(tail_n(C_AOUT_WIDTH-1 downto C_AOUT_SPLIT))));			-- tail_n(8 downto 3)
         																							-- ???
--         end if;
      end if;
   end process;

   --empty signal one cycle delayed, because no write through is supported
   empty <= '1' when(tail(C_AOUT_WIDTH-1 downto C_AOUT_SPLIT) = head) else '0';						-- tail(8 downto 3)
   process(clk) begin
      if(clk='1' and clk'event) then
         empty_p <= empty;
      end if;
   end process;
   empty_o <= '0' when(empty='0' and empty_p='0') else '1';

   -- Generate the full signal
   -- asserted whenever the fifo memory is 3/4 full
   -- here is an example when the fifo memory is 3/4 full (fMSB = 1100) 
   
   --	  00	   01		10		 11		  00       01		10			<- MSBs from head and tail
   -- |________|________|________|________|________|________|________|
   --
   -- ^							 ^	
   -- |							 |
   -- Tail						Head
   --
   -- The fifo is 3/4 full when fMSB equals (0001, 0110, 1011, 1100)
   
   
   -- These processes generate the full and the empty signal
   
   process(head, tail)
      variable fMSB : std_logic_vector(3 downto 0);
   begin
      -- in this case fMSB is composed of head(5) & head (4) & tail(8) & tail(7) 
      fMSB := head(C_AIN_WIDTH-1)&head(C_AIN_WIDTH-2)&tail(C_AOUT_WIDTH-1)&tail(C_AOUT_WIDTH-2);
      case(fMSB) is
      when "0000" => full_o <= '0';
      when "0001" => full_o <= '1';
      when "0010" => full_o <= '0';
      when "0011" => full_o <= '0';
      when "0100" => full_o <= '0';
      when "0101" => full_o <= '0';
      when "0110" => full_o <= '1';
      when "0111" => full_o <= '0';
      when "1000" => full_o <= '0';
      when "1001" => full_o <= '0';
      when "1010" => full_o <= '0';
      when "1011" => full_o <= '1';
      when "1100" => full_o <= '1';
      when "1101" => full_o <= '0';
      when "1110" => full_o <= '0';
      when "1111" => full_o <= '0';
      when others => full_o <= '0';
      end case;
   end process;

   process(fData) begin
      for i in 0 to C_DIN_WIDTH/C_DOUT_WIDTH-1 loop
         --  BUG:   fMux(C_DIN_WIDTH/C_DOUT_WIDTH-1-i) <= fData((i+1)*(C_DIN_WIDTH/C_DOUT_WIDTH)-1 downto i*(C_DIN_WIDTH/C_DOUT_WIDTH));
         fMux(C_DIN_WIDTH/C_DOUT_WIDTH-1-i) <= fData((i+1)*C_DOUT_WIDTH-1 downto i*C_DOUT_WIDTH);
      end loop;
   end process;

   rData_o <= fMux(CONV_INTEGER(UNSIGNED(tail(C_AOUT_SPLIT-1 downto 0)))); 							-- tail(2 downto 0)

end icapFIFO_rtl;

