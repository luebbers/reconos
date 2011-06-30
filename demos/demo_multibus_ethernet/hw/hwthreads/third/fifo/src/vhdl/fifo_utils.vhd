-------------------------------------------------------------------------------
--                                                                       
--  Module      : fifo_utils.vhd
--
--  Version     : 1.2
--
--  Last Update : 2005-06-29
--    
--  Project     : Parameterizable LocalLink FIFO
--
--  Description : Utility package created for LocalLink FIFO Design
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package fifo_u is
-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-- data type conversion functions
function to_character (bv : bit_vector(3 downto 0)) return character;
function conv_ascii_logic_vector(nib:std_logic_vector(3 downto 0)) 
                                        return std_logic_vector;
function to_string (bv : bit_vector) return string;
function to_string (b : bit) return string;
function conv_std_logic_vector (ch : character) return std_logic_vector;
function to_std_logic_vector (b : bit_vector) return std_logic_vector;
function to_std_logic (b : bit) return std_logic;
function boolean_to_std_logic (b : boolean) return std_logic;
function to_bit_vector (a : std_logic_vector) return bit_vector;
function slv2int (S: std_logic_vector) return integer;
function bitv2int (S: bit_vector) return integer;
function int2bv (int_value, width : integer) return bit_vector;
function revByteOrder( arg : std_logic_vector) return std_logic_vector;

-- arithmetic
function log2 (i: natural) return natural;
function POWER2 (p: integer)  return integer;
function SQUARE2 (p: integer) return integer;
function maxNat (arg1, arg2 : natural)          return natural;
function allZeroes (inp     : std_logic_vector) return boolean;
function allOnes (inp       : std_logic_vector) return boolean;
function bin_to_gray ( a : std_logic_vector) return std_logic_vector;
function gray_to_bin ( a : std_logic_vector) return std_logic_vector;
function bit_duplicate (b : std_logic; size : natural) return std_logic_vector;

-- FIFO related functions 
function GET_ADDR_WIDTH (dw : integer)        return integer;
function GET_ADDR_MAJOR_WIDTH (a ,b : integer) return integer;
function GET_ADDR_MINOR_WIDTH (a ,b : integer) return integer;
function GET_WIDTH (i, a, b, m, RorW : integer) return integer;
function GET_MAX_WIDTH(a, b: integer) return integer;
function GET_CTRL_WIDTH(ra,wa,rb,wb:integer) return integer;
function GET_HIGH_VALUE(ra,wa: integer) return integer;
function GET_ADDR_FULL_B(ra, wa, RorW: integer) return integer;
function GET_ADDR_MAJOR_WIDTH(ra, wa, RorW: integer) return integer;
function GET_REM_WIDTH(a: integer) return integer;
function GET_PAR_WIDTH(a: integer) return integer;
function GET_EOF_REM_WIDTH(ra, wa: integer) return integer;
function GET_RATIO(ra, wa, par: integer) return integer;
 
function GET_WR_SOF_EOF_WIDTH(ra, wa : integer) return integer;
function GET_RD_SOF_EOF_WIDTH(ra, wa : integer) return integer;
function GET_WR_CTRL_REM_WIDTH(ra, wa : integer) return integer;
function GET_RD_CTRL_REM_WIDTH(ra, wa : integer) return integer;

function GET_C_WR_ADDR_WIDTH(ra, wa, mem_num: integer) return integer;
function GET_C_RD_ADDR_WIDTH(ra, wa, mem_num: integer) return integer;
function GET_C_RD_TEMP_WIDTH(ra, wa: integer) return integer;
function GET_C_WR_TEMP_WIDTH(ra, wa: integer) return integer;
function GET_WR_PAD_WIDTH(rd, wd, c_wa, waf, wa: integer) return integer;
function GET_RD_PAD_WIDTH(da, db: integer) return integer;
function GET_NUM_DIV(ra, wa : integer) return integer;
function GET_WR_EN_FACTOR(NUM_DIV, MEM_NUM: integer) return integer;
function GET_RDDWdivWRDW(RD_DWIDTH, WR_DWIDTH : integer) return integer;
function GET_WRDW_div_RDDW(RD_DWIDTH, WR_DWIDTH : integer) return integer;

end fifo_u;


package body fifo_u is


-------------------------------------------------------------------------------
-- data type conversion functions
-------------------------------------------------------------------------------
  -- duplicate the bit value to specific width, e.g. '1' -> "1111"
  function bit_duplicate (b : std_logic; size : natural)
  return std_logic_vector is
   variable o : std_logic_vector(size -1 downto 0);
   begin
     for i in size -1 downto 0 loop
       o(i) := b;
     end loop;
     return o;
   end function;

    -- convert a character to a nibble wide std_logic_vector
    function conv_std_logic_vector (ch : character) return std_logic_vector is
    begin
        case ch is
            when '0'    => return "0000";
            when '1'    => return "0001";
            when '2'    => return "0010";
            when '3'    => return "0011";
            when '4'    => return "0100";
            when '5'    => return "0101";
            when '6'    => return "0110";
            when '7'    => return "0111";
            when '8'    => return "1000";
            when '9'    => return "1001";
            when 'a'    => return "1010";
            when 'b'    => return "1011";
            when 'c'    => return "1100";
            when 'd'    => return "1101";
            when 'e'    => return "1110";
            when 'f'    => return "1111";
            when others => assert false report "unrecognised character" 
                                                severity failure;
        end case;
        return "0000";
    end conv_std_logic_vector;
  
    -- convert bit to std_logic
    function to_std_logic (b : bit) return std_logic is
    begin
        case b is
            when '0'    => return '0';
            when '1'    => return '1';
            when others => assert false report "unrecognised bit value" 
                        severity failure;
        end case;
        return '0';
    end to_std_logic;

    -- convert boolean to std_logic
    function boolean_to_std_logic (b : boolean) return std_logic is
    begin
        case b is
            when FALSE    => return '0';
            when TRUE     => return '1';
            when others => return '0';
        end case;
        return '0';
    end boolean_to_std_logic;

    -- Convert 4-bit vector to a character
    function to_character (bv : bit_vector(3 downto 0)) return character is
    begin  -- to_character
        case bv is
            when b"0000" => return '0';
            when b"0001" => return '1';
            when b"0010" => return '2';
            when b"0011" => return '3';
            when b"0100" => return '4';
            when b"0101" => return '5';
            when b"0110" => return '6';
            when b"0111" => return '7';
            when b"1000" => return '8';
            when b"1001" => return '9';
            when b"1010" => return 'a';
            when b"1011" => return 'b';
            when b"1100" => return 'c';
            when b"1101" => return 'd';
            when b"1110" => return 'e';
            when b"1111" => return 'f';
        end case;
    end to_character;
    
    function conv_ascii_logic_vector (nib : std_logic_vector(3 downto 0)) 
                        return std_logic_vector is
    begin
        case nib is
            when "0000" => return "00110000";
            when "0001" => return "00110001";
            when "0010" => return "00110010";
            when "0011" => return "00110011";
            when "0100" => return "00110100";
            when "0101" => return "00110101";
            when "0110" => return "00110110";
            when "0111" => return "00110111";
            when "1000" => return "00111000";
            when "1001" => return "00111001";
            when "1010" => return "01000001";
            when "1011" => return "01000010";
            when "1100" => return "01000011";
            when "1101" => return "01000100";
            when "1110" => return "01000101";
            when "1111" => return "01000110";
            when others => return "00100000";
        end case;
        return "00100000";
    end conv_ascii_logic_vector;

    -- Convert n-bits vector to n/4-character string
    function to_string (bv : bit_vector) return string is
        constant strlen : integer := bv'length / 4;
        variable str : string(1 to strlen);
    begin  -- to_string
        for i in 0 to strlen - 1 loop
            str(strlen-i) := to_character(bv((i * 4) + 3 downto (i * 4)));
        end loop;  -- i
        return str;
    end to_string;


    -- Convert 1-bit  to 1-character string
    function to_string (b : bit) return string is
    begin
        case b is
            when '0'    => return "0";
            when '1'    => return "1";
            when others => assert false report "unrecognised bit value" 
                                        severity failure;
        end case;
        return "0";
    end to_string;

    -- Convert std_logic_vector to bit_vector
    function to_bit_vector (a : std_logic_vector) return bit_vector is
        variable b : bit_vector(a'length -1 downto 0);
    begin
        for i in 0 to a'length - 1 loop
            b(i) := to_bit (a(i));
        end loop;
        return b;
    end to_bit_vector;


    -- Convert  bit_vector to std_logic_vector
    function to_std_logic_vector (b : bit_vector) return std_logic_vector is
        variable a : std_logic_vector(b'length -1 downto 0);
    begin
        for i in 0 to b'length - 1 loop
            a(i) := to_std_logic (b(i));
        end loop;
        return a;
    end to_std_logic_vector;

    -- std_logic_vector to integer
    function slv2int (S: std_logic_vector) return integer is
        variable S_i: std_logic_vector(S'Length-1 downto 0) := S;
        variable N  : integer := 0;
    begin
        for i in S_i'Right to S_i'Left loop
            if (S_i(i)) = '1' then
               N := N + (2**i);
            elsif (S_i(i)) = 'X' then
               N := 0;
            end if;
        end loop;
        return N;
    end;

    -- bit_vector to integer
    function bitv2int (S: bit_vector) return integer is
        variable S_i: bit_vector(S'Length-1 downto 0) := S;
        variable N  : integer := 0;
    begin
        for i in S_i'Right to S_i'Left loop
            if (S_i(i)) = '1' then
                N := N + (2**i);
            end if;
        end loop;
        return N;
    end;

    function int2bv (int_value, width : integer) return bit_vector is
        variable result : bit_vector(width-1 downto 0) := (others => '0');
    begin
        for i in 0 to width-1 loop
            if ( ((int_value/(2**i)) mod 2) = 1) then
                result(i) := '1';
            end if;
        end loop;
        return result;
    end int2bv;

    function revByteOrder( arg : std_logic_vector) return std_logic_vector is
      variable tmp : std_logic_vector(arg'high downto 0);   -- length is numNibs
      variable numbytes : integer;
    begin
      numbytes := arg'length/8;
     lp0: for i in 0 to numbytes -1 loop
          tmp( (8*(numbytes-i)-1) downto 8*(numbytes-i-1) ) := arg( (8*i+7) downto 8*i);
     end loop lp0;
     return tmp ;
    end revbyteOrder;

-------------------------------------------------------------------------------
-- arithmetic
-------------------------------------------------------------------------------
    function allZeroes (inp : std_logic_vector) return boolean is
        variable t : boolean := true;
    begin
        t := true;  -- for synopsys
        for i in inp'range loop
            if inp(i) = '1' then
                t := false;
            end if;
        end loop;
        return t;
    end allZeroes;

    function allOnes (inp : std_logic_vector) return boolean is
        variable t : boolean := true;
    begin
        t := true;  -- for synopsys
        for i in inp'range loop
            if inp(i) = '0' then
                t := false;
            end if;
        end loop;
        return t;
    end allOnes;


    -- returns the maximum of two naturals
    function maxNat (arg1, arg2 : natural)
        return natural is
    begin  -- maxNat
        if arg1 >= arg2 then
            return arg1;
        else
            return arg2;
        end if;
    end maxNat;


    -- a function to calculate log2(i)
    function log2 (i: natural) return natural is
        variable answer : natural ;
    begin
        for n in 1 to 32 loop  -- works for upto 32 bits
            if (2**(n-1) < i) and (2**n >= i) then
                return (n);
            end if;
        end loop;
        return (1);
    end log2;

    --  a function to caculate 2 ** p
    function POWER2 ( p: in integer) return integer is
        variable answer : integer ;
    begin
        answer := 2**p;
        return answer;
    end function POWER2;

    --  a function to caculate square2(p)
    function SQUARE2 ( p: in integer) return integer is
        variable answer : integer ;
    begin
        case p is
            when 1 => answer := 0;
            when 2 => answer := 1;
            when 4 => answer := 2;
            when 8 => answer := 3;
            when 16 => answer := 4;
            when 32 => answer := 5;
            when 64 => answer := 6;
            when 128 => answer := 7;
            when 256 => answer := 8;
            when 512 => answer := 9;
            when 1024 => answer := 10;
            when others => assert false report "overflow or input exceeds acceptable range." severity failure;
        end case;
        return answer;
    end function SQUARE2;

    -- convert binary code to gray code
    function bin_to_gray ( a : std_logic_vector) return std_logic_vector is
        variable b : std_logic_vector(a'range);
    begin
        b(b'high) := a(a'high);
        for i in b'high -1 downto 0 loop
            b(i) := a(i+1) XOR a(i);
        end loop;
        return b;
    end function;
    
    -- conver gray code to binary code
    function gray_to_bin ( a : std_logic_vector) return std_logic_vector is
        variable b : std_logic_vector(a'range);
    begin
        for i in a'range loop
            if i = a'left then
                b(i) := a(i);
            else 
                b(i) := a(i) xor b(i+1);
            end if;
        end loop;
        return b;
    end function;


    -- generate the address width according to the data width, for FIFO
    function GET_ADDR_WIDTH (dw : in integer) return integer is
        variable aw : integer;
    begin
        case dw is
            when 1 => aw := 14;
            when 2 => aw := 13;
            when 4 => aw := 12;
            when 8 => aw := 11;
            when 16=> aw := 10;
            when 32=> aw := 9;
            when 64=> aw := 9;
            when 128=> aw := 9;
            when others => assert false report "input is not acceptable." severity failure;
        end case;
        return aw;
    end function GET_ADDR_WIDTH;

    -- generate the major address width, for FIFO
    function GET_ADDR_MAJOR_WIDTH (a , b: in integer) return integer is
        variable result : integer;
    begin
        if a < b then  -- A's data width is shorter than B's data width
                         -- Then A's addr width is longer than B's addr width
                         -- The Major & Minor Addrs are positive. The major addr is equal to
                         -- B's address width
            result := GET_ADDR_WIDTH(b);
        else           -- otherwise, No minor addr exsits
            result := GET_ADDR_WIDTH(a);
        end if;
        return result;
    end function GET_ADDR_MAJOR_WIDTH;


    -- generate the minor address width, for  BRAM_FIFO
    function GET_ADDR_MINOR_WIDTH (a , b : in integer) return integer is
        variable result : integer;
    begin
        if a < b then  -- A's data width is shorter than B's data width
                         -- Then A's addr width is longer than B's addr width
                         -- The Major & Minor Addrs are positive. The minor addr is equal to
                         -- the differential value between A & B's address width
            if b > 32 then 
                if b = 64 then 
                    result := GET_ADDR_WIDTH(a)+1 - GET_ADDR_WIDTH(b);
                elsif b = 128 then
                    if a = 64 then
                        result := GET_ADDR_WIDTH(a)+1 - GET_ADDR_WIDTH(b);
                    else
                        result := GET_ADDR_WIDTH(a)+2 - GET_ADDR_WIDTH(b);
                    end if;
                end if;  
            else 
                result := GET_ADDR_WIDTH(a) - GET_ADDR_WIDTH(b);
            end if;
        elsif a > b then           -- otherwise, invert the result
                         -- It may be zero which means no minor address exsits.
            if a > 32 then
                if a = 64 then
                    result := GET_ADDR_WIDTH(b)+1 - GET_ADDR_WIDTH(a); 
                elsif a = 128 then
                    if b = 64 then 
                        result := GET_ADDR_WIDTH(b)+1 - GET_ADDR_WIDTH(a); 
                    else
                        result := GET_ADDR_WIDTH(b)+2 - GET_ADDR_WIDTH(a); 
                    end if;
                end if;   
            else
                result := GET_ADDR_WIDTH(b) - GET_ADDR_WIDTH(a);
            end if;
        else
            result := 1;
        end if;
        return result;
    end function GET_ADDR_MINOR_WIDTH;

      
    function GET_WIDTH (i, a, b, m, RorW : in integer) return integer is
    -- m: 1 get major address width; 2 get minor address width
    -- RorW: 0 : Rd  1: Wr
    -- a:  Rd data width ; b: Wr data width
        variable result : integer;
    begin                               
        if a < b then
            if m = 1 then               
               result := i;
            elsif m = 2 then            
                if RorW = 0 then
                    result := SQUARE2(b) - SQUARE2(a);
                else 
                    result := 1;
                end if;
            end if;
        else                      -- Rd > Wr
            if m = 1 then                       
                result := i;  
            elsif m = 2 then                    
                if RorW = 0 then  -- 
                    result := 1;
                else
                    result := SQUARE2(a) - SQUARE2(b);
                end if;
            end if;
        end if;
            
        if result = 0 then
            result := result + 1;
            return result;
        else
            return result;
        end if;
    end function GET_WIDTH;
     
    function GET_MAX_WIDTH(a, b: in integer) return integer is
        variable result: integer;
     begin
        if a < b then
            result := b;
        else
            result := a;
        end if;
        return result;
    end function GET_MAX_WIDTH;

    function GET_CTRL_WIDTH(ra,wa,rb,wb: integer) return integer is
        variable result: integer;
    begin
        if rb < wb then
            result := wa + 2;
        else
            result := ra + 2;
        end if;
        return result;
    end function GET_CTRL_WIDTH;
     
    function GET_HIGH_VALUE(ra,wa: integer) return integer is
        variable result: integer;
    begin
        if (wa > ra) then
            result := wa - ra;
        else 
            result := 1;
        end if;
            return result;
    end function GET_HIGH_VALUE;


    function GET_ADDR_FULL_B(ra, wa, RorW: integer) return integer is
        variable result : integer;
    begin       
        if (ra > wa) then
            if RorW = 0 then
                result := GET_ADDR_WIDTH(ra);
            elsif RorW = 1 then
                if ra > 36 then
                    if ra = 64 then
                        result := GET_ADDR_WIDTH(wa)+1;
                    elsif ra = 128 then
                        if wa = 64 then
                            result := GET_ADDR_WIDTH(wa) + 1;
                        else 
                            result := GET_ADDR_WIDTH(wa) + 2;
                        end if;
                    end if;
                else
                    result := GET_ADDR_WIDTH(wa);
                end if;
            end if;
        else
            if RorW = 0 then
                if wa > 36 then 
                    if wa = 64 then
                        result := GET_ADDR_WIDTH(ra)+1;
                    elsif wa = 128 then
                        if ra = 64 then
                            result := GET_ADDR_WIDTH(ra) + 1;
                        else
                            result := GET_ADDR_WIDTH(ra) + 2;
                        end if;
                    end if;
                else
                    result := GET_ADDR_WIDTH(ra); 
                end if;
            elsif RorW = 1 then
                result := GET_ADDR_WIDTH(wa);
            end if;
        end if;
        return result;
    end function GET_ADDR_FULL_B;
    
    function GET_ADDR_MAJOR_WIDTH(ra, wa, RorW: integer) return integer is
        variable result : integer;
    begin
        if ra > wa then
            if RorW = 0 then
                result := GET_ADDR_WIDTH(ra);
            elsif RorW = 1 then
                if ra > 36 then 
                    if ra = 64 then
                        result := GET_ADDR_WIDTH(wa) - GET_ADDR_MINOR_WIDTH (ra, wa) + 1;
                    elsif ra = 128 then
                        if wa = 64 then 
                            result := GET_ADDR_WIDTH(wa) - GET_ADDR_MINOR_WIDTH (ra, wa) + 1;
                        else
                            result := GET_ADDR_WIDTH(wa) - GET_ADDR_MINOR_WIDTH (ra, wa) + 2;
                        end if;
                    end if;
                else 
                    result := GET_ADDR_WIDTH(wa) - GET_ADDR_MINOR_WIDTH (ra, wa);        
                end if;
            end if;
        elsif ra < wa then
            if RorW = 0 then
                if wa > 36 then
                    if wa = 64 then
                        result := GET_ADDR_WIDTH(ra) - GET_ADDR_MINOR_WIDTH (ra, wa)+1;
                    elsif wa = 128 then
                        if ra = 64 then
                            result := GET_ADDR_WIDTH(ra) - GET_ADDR_MINOR_WIDTH (ra, wa)+1;
                        else
                            result := GET_ADDR_WIDTH(ra) - GET_ADDR_MINOR_WIDTH (ra, wa)+2;
                        end if;
                    end if;
                else
                    result := GET_ADDR_WIDTH(ra) - GET_ADDR_MINOR_WIDTH (ra, wa);
                end if;
            elsif RorW = 1 then
                result := GET_ADDR_WIDTH(wa);
            end if;
        else
            if RorW = 0 then
                result := GET_ADDR_WIDTH(ra);
            else
                result := GET_ADDR_WIDTH(wa);
            end if;
        end if;
        return result;
    end function GET_ADDR_MAJOR_WIDTH;
     
    function GET_REM_WIDTH(a: integer) return integer is
        variable result : integer;
    begin
        if a = 0 then
            result := 1;
        else
            result := a;
        end if;
        return result;
    end function GET_REM_WIDTH;
     
    function GET_PAR_WIDTH(a: integer) return integer is
        variable result : integer;
    begin
        case a is
            when 8 => result := 1;
            when 16 => result := 2;
            when 32 => result := 4;
            when 64 => result := 8;
            when 128 => result := 16;
            when others => NULL;
        end case;
        return result;
    end function GET_PAR_WIDTH;
       
    function GET_EOF_REM_WIDTH(ra, wa: integer) return integer is
        variable result : integer;
    begin
        if ra > wa then
            result := ra;
        else
            result := wa;
        end if;
        return result;
    end function GET_EOF_REM_WIDTH;
   
    function GET_RATIO(ra, wa, par: integer) return integer is
        variable result : integer;
    begin
        result := (par * ra) / wa;
        return result;
    end function GET_RATIO;   
       
    function GET_WR_SOF_EOF_WIDTH(ra, wa : integer) return integer is
        variable result : integer;
    begin
        if wa = 8 then
            case ra is
                when 8 => result := 2;
                when 16 => result := 2;
                when 32 => result := 2;
                when 64 => result := 2;  
                when 128 => result := 2; 
                when others => NULL;
            end case;
        elsif wa = 16 then
            case ra is
                when 8 => result := 4;
                when 16 => result := 2;  
                when 32 => result := 2;  
                when 64 => result := 2;  
                when 128 => result := 2;
                when others => NULL;     
            end case;
        elsif wa = 32 then
            case ra is
                when 8 => result := 8;   
                when 16 => result := 4;  
                when 32 => result := 4;  
                when 64 => result := 4;  
                when 128 => result := 2; 
                when others => NULL;     
            end case;
        elsif wa = 64 then
            case ra is
                when 8 => result := 16;  
                when 16 => result := 8;  
                when 32 => result := 8;  
                when 64 => result := 8;  
                when 128 => result := 8;
                when others => NULL;  
            end case;
        elsif wa = 128 then
            case ra is
                when 8 => result := 32; 
                when 16 => result := 32; 
                when 32 => result := 8;
                when 64 => result := 16;
                when 128 => result := 16;
                when others => NULL; 
            end case;
        end if;          
        return result;
    end function GET_WR_SOF_EOF_WIDTH;
    
    function GET_RD_SOF_EOF_WIDTH(ra, wa : integer) return integer is
        variable result : integer;
    begin
        if wa = 8 then
            case ra is
                when 8 => result := 2;
                when 16 => result := 2;
                when 32 => result := 2;
                when 64 => result := 2; 
                when 128 => result := 2;
                when others => NULL;
            end case;
        elsif wa = 16 then
            case ra is
                when 8 => result := 2;
                when 16 => result := 2; 
                when 32 => result := 4; 
                when 64 => result := 8; 
                when 128 => result := 2;
                when others => NULL;    
            end case;
        elsif wa = 32 then
            case ra is
                when 8 => result := 2;  
                when 16 => result := 2; 
                when 32 => result := 4; 
                when 64 => result := 8; 
                when 128 => result := 8;
                when others => NULL;     
            end case;
        elsif wa = 64 then
            case ra is
                when 8 => result := 2;   
                when 16 => result := 2;  
                when 32 => result := 4;  
                when 64 => result := 8;  
                when 128 => result := 16;
                when others => NULL;  
            end case;
        elsif wa = 128 then
            case ra is
                when 8 => result := 2; 
                when 16 => result := 2;
                when 32 => result := 2;
                when 64 => result := 2;
                when 128 => result := 16; 
                when others => NULL;       
            end case;
        end if;
        return result;
    end function GET_RD_SOF_EOF_WIDTH;

    function GET_WR_CTRL_REM_WIDTH(ra, wa : integer) return integer is
        variable result : integer;
    begin
        if wa = 8 then
            case ra is
                when 8 => result := 1;
                when 16 => result := 2; 
                when 32 => result := 1;
                when 64 => result := 3; 
                when 128 => result := 4;
                when others => NULL;
            end case;
        elsif wa = 16 then
            case ra is
                when 8 => result := 2;  
                when 16 => result := 1; 
                when 32 => result := 2; 
                when 64 => result := 4; 
                when 128 => result := 4;
                when others => NULL;      
            end case;
        elsif wa = 32 then
            case ra is
                when 8 => result := 2;
                when 16 => result := 2;  
                when 32 => result := 2;
                when 64 => result := 4;
                when 128 => result := 4;
                when others => NULL;     
            end case;
        elsif wa = 64 then
            case ra is
                when 8 => result := 16;
                when 16 => result := 4;
                when 32 => result := 4;
                when 64 => result := 2;
                when 128 => result := 2;
                when others => NULL;  
            end case;
        elsif wa = 128 then
            case ra is
                when 8 => result := 16;
                when 16 => result := 8;
                when 32 => result := 16;  
                when 64 => result := 2;
                when 128 => result := 2;
                when others => NULL;       
            end case;
        end if;
        return result;
    end function GET_WR_CTRL_REM_WIDTH;
           
    function GET_RD_CTRL_REM_WIDTH(ra, wa : integer) return integer is
        variable result : integer;
    begin
        if wa = 8 then
            case ra is
                when 8 => result := 1;
                when 16 => result := 2;  
                when 32 => result := 4;
                when 64 => result := 3; 
                when 128 => result := 4;
                when others => NULL;
            end case;
        elsif wa = 16 then
            case ra is
                when 8 => result := 4;  
                when 16 => result := 1; 
                when 32 => result := 2; 
                when 64 => result := 4; 
                when 128 => result := 4;
                when others => NULL;      
            end case;
        elsif wa = 32 then
            case ra is
                when 8 => result := 2;
                when 16 => result := 1;  
                when 32 => result := 2;
                when 64 => result := 4;
                when 128 => result := 16;
                when others => NULL;     
            end case;
        elsif wa = 64 then
            case ra is
                when 8 => result := 16;
                when 16 => result := 1;
                when 32 => result := 4;
                when 64 => result := 2;
                when 128 => result := 2;
                when others => NULL;  
            end case;
        elsif wa = 128 then
            case ra is
                when 8 => result := 16;
                when 16 => result := 1;
                when 32 => result := 4; 
                when 64 => result := 3;
                when 128 => result := 2;
                when others => NULL;       
            end case;
        end if;
        return result;
    end function GET_RD_CTRL_REM_WIDTH;
    
    
    function GET_C_WR_ADDR_WIDTH(ra, wa, mem_num: integer) return integer is
        variable result : integer;
    begin
        if wa = 8 then
            case ra is
                when 8 => 
                    if mem_num < 8 then
                        result := 13;  
                    elsif mem_num = 8 then
                        result := 14;
                    elsif mem_num = 16 then
                        result := 15;
                    else
                        result := 16;
                    end if;
                when 16 => result := 13;
                when 32 => result := 13;
            when 64 => 
                if mem_num <= 4 then   
                    result := 11;  
                elsif mem_num = 8 then
                    result := 12;
                elsif mem_num = 16 then
                    result := 13;
                else
                    result := 14;
                end if;
            when 128 => result := 11;
            when others => NULL;
        end case;
        elsif wa = 16 then
            case ra is
                when 8 => result := 12;
                when 16 => result := 14;  
                when 32 => result := 13;
                when 64 => 
                    if mem_num <= 8 then 
                        result := 12;  
                    else 
                        result := 13;
                    end if;
                when 128 => result := 11;
                when others => NULL;      
            end case;
        elsif wa = 32 then
            case ra is
                when 8 => result := 13;  
                when 16 => result := 13;  
                when 32 => result := 12;
                when 64 => 
                    if mem_num <= 8 then
                        result := 12;  
                    else
                        result := 13;
                    end if;           
                when 128 => result := 13;   
                when others => NULL;        
            end case;   
        elsif wa = 64 then   
            case ra is   
                when 8 => 
                    if mem_num <= 2 then
                        result := 10;
                    elsif mem_num = 4 then
                        result := 11;
                    elsif mem_num = 8 then
                        result := 12;
                    elsif mem_num = 16 then
                        result := 13;
                    else
                        result := 14;
                    end if;
                when 16 => 
                    if mem_num <= 8 then
                        result := 12;  
                    else
                        result := 13;
                    end if;
                when 32 => result := 12;  
                when 64 => result := 2;  
                when 128 => result := 2;   
                when others => NULL;     
            end case;   
        elsif wa = 128 then   
            case ra is   
                when 8 => result := 10; 
                when 16 => result := 8; 
                when 32 => result := 11; 
                when 64 => result := 2;   
                when 128 => result := 2;   
                when others => NULL;          
            end case;   
        end if;   
        return result;  
    end function GET_C_WR_ADDR_WIDTH;
    
    
    function GET_C_RD_ADDR_WIDTH(ra, wa, mem_num: integer) return integer is
        variable result : integer;
    begin
        if wa = 8 then
            case ra is
                when 8 => 
                    if mem_num < 8 then
                        result := 13;  
                    elsif mem_num = 8 then
                        result := 14;
                    elsif mem_num = 16 then
                        result := 15;
                    else 
                        result := 16;
                    end if;
                when 16 => result := 13;
                when 32 => result := 13;
                when 64 => 
                    if mem_num <= 4 then
                        result := 11;
                    elsif mem_num = 8 then
                        result := 12;
                    elsif mem_num = 16 then
                        result := 13;  
                    else
                        result := 14;
                    end if;
                when 128 => result := 11;
                when others => NULL;
            end case;
        elsif wa = 16 then
            case ra is
                when 8 => result := 13;
                when 16 => result := 14; 
                when 32 => result := 13;
                when 64 => 
                    if mem_num <= 8 then 
                        result := 12;  
                    else 
                        result := 13;
                    end if;
                when 128 => result := 11;
                when others => NULL;      
            end case;
        elsif wa = 32 then
            case ra is
                when 8 => result := 13; 
                when 16 => result := 14;
                when 32 => result := 12;
                when 64 => 
                    if mem_num <= 8 then
                        result := 12; 
                    else
                        result := 13;
                    end if;         
                when 128 => result := 13;
                when others => NULL;     
            end case;
        elsif wa = 64 then
            case ra is
                when 8 =>
                    if mem_num <= 2 then
                        result := 13;
                    elsif mem_num = 4 then
                        result := 14;
                    elsif mem_num = 8 then
                        result := 15;
                    elsif mem_num = 16 then
                        result := 16;
                    else
                        result := 17; 
                    end if;
                when 16 => 
                    if mem_num <= 8 then
                        result := 14; 
                    else
                        result := 15;
                    end if;
                when 32 => result := 12;  
                when 64 => result := 2;  
                when 128 => result := 2;
                when others => NULL;  
            end case;
        elsif wa = 128 then
            case ra is
                when 8 => result := 13;
                when 16 => result := 8;
                when 32 => result := 13;  
                when 64 => result := 2;
                when 128 => result := 2;
                when others => NULL;       
            end case;
        end if;
        return result;
    end function GET_C_RD_ADDR_WIDTH;
    
    function GET_C_RD_TEMP_WIDTH(ra, wa: integer) return integer is
        variable result : integer;
    begin
        if wa = 8 then
            case ra is
                when 64 => result := 8; 
                when 128 => result := 8;
                when others => result := 8;      
            end case;
        elsif wa = 16 then
            case ra is
                when 64 => result := 8;
                when 128 => result := 8;  
                when others => result := 8;       
            end case;
        elsif wa = 32 then
            case ra is 
                when 8 => result := 8;
                when 16 => result := 8;
                when 32 => result := 8;
                when others => result := 8;
            end case;
        elsif wa = 64 then
            case ra is
                when 16 => result := 8;
                when 8 => result := 8;
                when 128 => result := 16;
                when others => result := 8;
            end case;
        elsif wa = 128 then
            case ra is
                when 16 => result := 4;
                when 64 => result := 8;
                when others => result := 8;      
            end case;
        else
            result := 8;
        end if;
        return result;
    end function GET_C_RD_TEMP_WIDTH;
    
    
    function GET_C_WR_TEMP_WIDTH(ra, wa: integer) return integer is
        variable result : integer;
    begin
        if wa = 8 then
            case ra is
                when 64 => result := 8;
                when 128 => result := 8;
                when others => result := 8;      
            end case;
        elsif wa = 16 then
            case ra is
                when 64 => result := 8;
                when 128 => result := 8;
                when others => result := 8;       
            end case;
        elsif wa = 32 then
            case ra is 
                when 8 => result := 8;
                when 16 => result := 8;
                when 32 => result := 8;
                when others => result := 8;
            end case;
        elsif wa = 64 then
            case ra is
                when 16 => result := 8;
                when 8 => result := 8;
                when others => result := 8;
            end case;
        elsif wa = 128 then
            case ra is
                when 16 => result := 32;
                when 64 => result := 16;
                when others => result := 8;       
            end case;
        else
            result := 8;
        end if;
        return result;
    end function GET_C_WR_TEMP_WIDTH;
    
    function GET_WR_PAD_WIDTH(rd, wd, c_wa, waf, wa: integer) return integer is
        variable result: integer;
    begin
        if rd> wd then
            if c_wa - wa >= 0 then 
                result := c_wa - wa;
            else 
                result := 0;
            end if;
        else
            if c_wa - waf >= 0 then
                result := c_wa - waf;
            else
                result := 0;
            end if;
        end if;
        return result;
    end function GET_WR_PAD_WIDTH;
     
    function GET_RD_PAD_WIDTH(da, db: integer) return integer is
        variable result : integer;
    begin
        if da-db >= 0 then
            result := da - db;
        else 
            result := 0;
        end if;
        return result;
    end function GET_RD_PAD_WIDTH;

    function GET_NUM_DIV(ra, wa : integer) return integer is
        variable result : integer;
    begin
        if wa = 8 then
            case ra is
                when 16 => result := 8;
                when 64 => result := 2;
                when others => result := 1;      
            end case;
        elsif wa = 16 then
            case ra is 
                when 8 => result := 4;
                when others => result := 1;
            end case;
        elsif wa = 32 then
            case ra is 
                when 8 => result := 4;
                when others => result := 1;
            end case;
        elsif wa = 64 then
            case ra is
                when 8 => result := 2;
                when others => result := 1;
            end case;
        else
            result := 1;
        end if;
        return result;
    end function GET_NUM_DIV;

    function GET_WR_EN_FACTOR(NUM_DIV, MEM_NUM: integer) return integer is
        variable result : integer;
    begin
        if MEM_NUM < NUM_DIV then
            result :=1;
        else
            result := MEM_NUM/NUM_DIV;
        end if;
        return result;
    end function GET_WR_EN_FACTOR;
     
    function GET_RDDWdivWRDW(RD_DWIDTH, WR_DWIDTH : integer) return integer is
        variable result : integer;
    begin
        if RD_DWIDTH > WR_DWIDTH then
            result := RD_DWIDTH / WR_DWIDTH;
        else
            result := 1;
        end if;
        return result;
    end function GET_RDDWdivWRDW;

    function GET_WRDW_div_RDDW(RD_DWIDTH, WR_DWIDTH : integer) return integer is
        variable result : integer;
    begin
        if WR_DWIDTH > RD_DWIDTH then
            result := WR_DWIDTH / RD_DWIDTH;
        else
            result := 1;
        end if;
        return result;
    end function GET_WRDW_div_RDDW;
     
end fifo_u;
   