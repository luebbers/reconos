



































































































env /bfm_system/bfm_memory/bfm_memory/slave/slave/
force -deposit ssize_mode 2#110

force -deposit fixed_burst_mode  1

force -deposit pipeline_mode(0)  1

force -deposit pipeline_mode(1)  1

force -deposit pipeline_mode(1)  1

force -deposit burst_term_mode 0

env /bfm_system/bfm_memory/bfm_memory/slave/slave/read_req_cmd
change read_cmd(24:31)  2#00000001
env /bfm_system/bfm_memory/bfm_memory/slave/slave/write_req_cmd
change write_cmd(24:31)  2#00000001


env /bfm_system/bfm_memory/bfm_memory/slave/slave/slave_mem
change plb_slave_addr_array(0)  16#0000000010000001
change plb_slave_data_array(0)(0:127) 16#000102030405060708090a0b0c0d0e0f

change plb_slave_addr_array(1)  16#0000000010000011
change plb_slave_data_array(1)(0:127) 16#101112131415161718191a1b1c1d1e1f

change plb_slave_addr_array(2)  16#0000000010000021
change plb_slave_data_array(2)(0:127) 16#202122232425262728292a2b2c2d2e2f

change plb_slave_addr_array(3)  16#0000000010000031
change plb_slave_data_array(3)(0:127) 16#303132333435363738393a3b3c3d3e3f

change plb_slave_addr_array(4)  16#0000000010000041
change plb_slave_data_array(4)(0:127) 16#404142434445464748494a4b4c4d4e4f

change plb_slave_addr_array(5)  16#0000000010000051
change plb_slave_data_array(5)(0:127) 16#505152535455565758595a5b5c5d5e5f

change plb_slave_addr_array(6)  16#0000000010000061
change plb_slave_data_array(6)(0:127) 16#606162636465666768696a6b6c6d6e6f

change plb_slave_addr_array(7)  16#0000000010000071
change plb_slave_data_array(7)(0:127) 16#707172737475767778797a7b7c7d7e7f

change plb_slave_addr_array(8)  16#0000000010000081
change plb_slave_data_array(8)(0:127) 16#808182838485868788898a8b8c8d8e8f

change plb_slave_addr_array(9)  16#0000000010000091
change plb_slave_data_array(9)(0:127) 16#909192939495969798999a9b9c9d9e9f

change plb_slave_addr_array(10)  16#00000000100000A1
change plb_slave_data_array(10)(0:127) 16#a0a1a2a3a4a5a6a7a8a9aaabacadaeaf

change plb_slave_addr_array(11)  16#00000000100000B1
change plb_slave_data_array(11)(0:127) 16#b0b1b2b3b4b5b6b7b8b9babbbcbdbebf

change plb_slave_addr_array(12)  16#00000000100000C1
change plb_slave_data_array(12)(0:127) 16#c0c1c2c3c4c5c6c7c8c9cacbcccdcecf

change plb_slave_addr_array(13)  16#00000000100000D1
change plb_slave_data_array(13)(0:127) 16#d0d1d2d3d4d5d6d7d8d9dadbdcdddedf

change plb_slave_addr_array(14)  16#00000000100000E1
change plb_slave_data_array(14)(0:127) 16#e0e1e2e3e4e5e6e7e8e9eaebecedeeef

change plb_slave_addr_array(15)  16#00000000100000F1
change plb_slave_data_array(15)(0:127) 16#f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff

change plb_slave_addr_array(16)  16#0000000020000001
change plb_slave_data_array(16)(0:127) 16#deadbeefdeadbeefdeadbeefdeadbeef

change plb_slave_addr_array(17)  16#0000000020000011
change plb_slave_data_array(17)(0:127) 16#deadbeefdeadbeefdeadbeefdeadbeef

change plb_slave_addr_array(18)  16#0000000020000021
change plb_slave_data_array(18)(0:127) 16#deadbeefdeadbeefdeadbeefdeadbeef

change plb_slave_addr_array(19)  16#0000000020000031
change plb_slave_data_array(19)(0:127) 16#deadbeefdeadbeefdeadbeefdeadbeef

change plb_slave_addr_array(20)  16#0000000020000041
change plb_slave_data_array(20)(0:127) 16#deadbeefdeadbeefdeadbeefdeadbeef

change plb_slave_addr_array(21)  16#0000000020000051
change plb_slave_data_array(21)(0:127) 16#deadbeefdeadbeefdeadbeefdeadbeef

change plb_slave_addr_array(22)  16#0000000020000061
change plb_slave_data_array(22)(0:127) 16#deadbeefdeadbeefdeadbeefdeadbeef

change plb_slave_addr_array(23)  16#0000000020000071
change plb_slave_data_array(23)(0:127) 16#deadbeefdeadbeefdeadbeefdeadbeef

change plb_slave_addr_array(24)  16#0000000020000081
change plb_slave_data_array(24)(0:127) 16#deadbeefdeadbeefdeadbeefdeadbeef

change plb_slave_addr_array(25)  16#0000000020000091
change plb_slave_data_array(25)(0:127) 16#deadbeefdeadbeefdeadbeefdeadbeef

change plb_slave_addr_array(26)  16#00000000200000A1
change plb_slave_data_array(26)(0:127) 16#deadbeefdeadbeefdeadbeefdeadbeef

change plb_slave_addr_array(27)  16#00000000200000B1
change plb_slave_data_array(27)(0:127) 16#deadbeefdeadbeefdeadbeefdeadbeef

change plb_slave_addr_array(28)  16#00000000200000C1
change plb_slave_data_array(28)(0:127) 16#deadbeefdeadbeefdeadbeefdeadbeef

change plb_slave_addr_array(29)  16#00000000200000D1
change plb_slave_data_array(29)(0:127) 16#deadbeefdeadbeefdeadbeefdeadbeef

change plb_slave_addr_array(30)  16#00000000200000E1
change plb_slave_data_array(30)(0:127) 16#deadbeefdeadbeefdeadbeefdeadbeef

change plb_slave_addr_array(31)  16#00000000200000F1
change plb_slave_data_array(31)(0:127) 16#deadbeefdeadbeefdeadbeefdeadbeef


env /bfm_system/bfm_processor/bfm_processor/master/master/
force -deposit msize_mode 2#110

env /bfm_system/bfm_processor/bfm_processor/master/master/decoder
change cmd0_array(0)(0:3) 2#0101
change addr_array(0)(33)  1

change cmd0_array(1)(0:3) 2#0110
change addr_array(1)  16#0000000020000000
change cmd1_array(1)(11:12)  2#11
change data_array(1)(0:63) 16#deadbeefdeadbeef
change be_array(1)(0:7)  2#11111111

change cmd0_array(2)(0:3) 2#0110
change addr_array(2)  16#0000000020000008
change cmd1_array(2)(11:12)  2#11
change data_array(2)(64:127) 16#deadbeefdeadbeef
change be_array(2)(8:15)  2#11111111

change cmd0_array(3)(0:3) 2#0110
change addr_array(3)  16#0000000020000010
change cmd1_array(3)(11:12)  2#11
change data_array(3)(0:63) 16#deadbeefdeadbeef
change be_array(3)(0:7)  2#11111111

change cmd0_array(4)(0:3) 2#0110
change addr_array(4)  16#0000000020000018
change cmd1_array(4)(11:12)  2#11
change data_array(4)(64:127) 16#deadbeefdeadbeef
change be_array(4)(8:15)  2#11111111

change cmd0_array(5)(0:3) 2#0110
change addr_array(5)  16#0000000020000020
change cmd1_array(5)(11:12)  2#11
change data_array(5)(0:63) 16#deadbeefdeadbeef
change be_array(5)(0:7)  2#11111111

change cmd0_array(6)(0:3) 2#0110
change addr_array(6)  16#0000000020000028
change cmd1_array(6)(11:12)  2#11
change data_array(6)(64:127) 16#deadbeefdeadbeef
change be_array(6)(8:15)  2#11111111

change cmd0_array(7)(0:3) 2#0110
change addr_array(7)  16#0000000020000030
change cmd1_array(7)(11:12)  2#11
change data_array(7)(0:63) 16#deadbeefdeadbeef
change be_array(7)(0:7)  2#11111111

change cmd0_array(8)(0:3) 2#0110
change addr_array(8)  16#0000000020000038
change cmd1_array(8)(11:12)  2#11
change data_array(8)(64:127) 16#deadbeefdeadbeef
change be_array(8)(8:15)  2#11111111

change cmd0_array(9)(0:3) 2#0110
change addr_array(9)  16#0000000020000040
change cmd1_array(9)(11:12)  2#11
change data_array(9)(0:63) 16#deadbeefdeadbeef
change be_array(9)(0:7)  2#11111111

change cmd0_array(10)(0:3) 2#0110
change addr_array(10)  16#0000000020000048
change cmd1_array(10)(11:12)  2#11
change data_array(10)(64:127) 16#deadbeefdeadbeef
change be_array(10)(8:15)  2#11111111

change cmd0_array(11)(0:3) 2#0110
change addr_array(11)  16#0000000020000050
change cmd1_array(11)(11:12)  2#11
change data_array(11)(0:63) 16#deadbeefdeadbeef
change be_array(11)(0:7)  2#11111111

change cmd0_array(12)(0:3) 2#0110
change addr_array(12)  16#0000000020000058
change cmd1_array(12)(11:12)  2#11
change data_array(12)(64:127) 16#deadbeefdeadbeef
change be_array(12)(8:15)  2#11111111

change cmd0_array(13)(0:3) 2#0110
change addr_array(13)  16#0000000020000060
change cmd1_array(13)(11:12)  2#11
change data_array(13)(0:63) 16#deadbeefdeadbeef
change be_array(13)(0:7)  2#11111111

change cmd0_array(14)(0:3) 2#0110
change addr_array(14)  16#0000000020000068
change cmd1_array(14)(11:12)  2#11
change data_array(14)(64:127) 16#deadbeefdeadbeef
change be_array(14)(8:15)  2#11111111

change cmd0_array(15)(0:3) 2#0110
change addr_array(15)  16#0000000020000070
change cmd1_array(15)(11:12)  2#11
change data_array(15)(0:63) 16#deadbeefdeadbeef
change be_array(15)(0:7)  2#11111111

change cmd0_array(16)(0:3) 2#0110
change addr_array(16)  16#0000000020000078
change cmd1_array(16)(11:12)  2#11
change data_array(16)(64:127) 16#deadbeefdeadbeef
change be_array(16)(8:15)  2#11111111

change cmd0_array(17)(0:3) 2#0001
change addr_array(17)  16#0000000020000000
change cmd0_array(17)(4:7)  2#0000
change be_array(17)(0:15)  2#1111111100000000

change cmd0_array(18)(0:3) 2#0001
change addr_array(18)  16#0000000020000008
change cmd0_array(18)(4:7)  2#0000
change be_array(18)(0:15)  2#0000000011111111

change cmd0_array(19)(0:3) 2#0001
change addr_array(19)  16#0000000020000010
change cmd0_array(19)(4:7)  2#0000
change be_array(19)(0:15)  2#1111111100000000

change cmd0_array(20)(0:3) 2#0001
change addr_array(20)  16#0000000020000018
change cmd0_array(20)(4:7)  2#0000
change be_array(20)(0:15)  2#0000000011111111

change cmd0_array(21)(0:3) 2#0001
change addr_array(21)  16#0000000020000020
change cmd0_array(21)(4:7)  2#0000
change be_array(21)(0:15)  2#1111111100000000

change cmd0_array(22)(0:3) 2#0001
change addr_array(22)  16#0000000020000028
change cmd0_array(22)(4:7)  2#0000
change be_array(22)(0:15)  2#0000000011111111

change cmd0_array(23)(0:3) 2#0001
change addr_array(23)  16#0000000020000030
change cmd0_array(23)(4:7)  2#0000
change be_array(23)(0:15)  2#1111111100000000

change cmd0_array(24)(0:3) 2#0001
change addr_array(24)  16#0000000020000038
change cmd0_array(24)(4:7)  2#0000
change be_array(24)(0:15)  2#0000000011111111

change cmd0_array(25)(0:3) 2#0001
change addr_array(25)  16#0000000020000040
change cmd0_array(25)(4:7)  2#0000
change be_array(25)(0:15)  2#1111111100000000

change cmd0_array(26)(0:3) 2#0001
change addr_array(26)  16#0000000020000048
change cmd0_array(26)(4:7)  2#0000
change be_array(26)(0:15)  2#0000000011111111

change cmd0_array(27)(0:3) 2#0001
change addr_array(27)  16#0000000020000050
change cmd0_array(27)(4:7)  2#0000
change be_array(27)(0:15)  2#1111111100000000

change cmd0_array(28)(0:3) 2#0001
change addr_array(28)  16#0000000020000058
change cmd0_array(28)(4:7)  2#0000
change be_array(28)(0:15)  2#0000000011111111

change cmd0_array(29)(0:3) 2#0001
change addr_array(29)  16#0000000020000060
change cmd0_array(29)(4:7)  2#0000
change be_array(29)(0:15)  2#1111111100000000

change cmd0_array(30)(0:3) 2#0001
change addr_array(30)  16#0000000020000068
change cmd0_array(30)(4:7)  2#0000
change be_array(30)(0:15)  2#0000000011111111

change cmd0_array(31)(0:3) 2#0001
change addr_array(31)  16#0000000020000070
change cmd0_array(31)(4:7)  2#0000
change be_array(31)(0:15)  2#1111111100000000

change cmd0_array(32)(0:3) 2#0001
change addr_array(32)  16#0000000020000078
change cmd0_array(32)(4:7)  2#0000
change be_array(32)(0:15)  2#0000000011111111

change cmd0_array(33)(0:3) 2#0110
change addr_array(33)  16#0000000030000000
change cmd1_array(33)(11:12)  2#11
change data_array(33)(0:31) 16#90000000
change be_array(33)(0:3)  2#1111

change cmd0_array(34)(0:3) 2#0010
change addr_array(34)  16#0000000030000000
change cmd0_array(34)(4:7)  2#0000
change be_array(34)(0:15)  2#1000000000000000

change cmd0_array(35)(0:3) 2#0110
change addr_array(35)  16#0000000030000004
change cmd1_array(35)(11:12)  2#11
change data_array(35)(32:63) 16#10000000
change be_array(35)(4:7)  2#1111

change cmd0_array(36)(0:3) 2#0010
change addr_array(36)  16#0000000030000004
change cmd0_array(36)(4:7)  2#0000
change be_array(36)(0:15)  2#0000111100000000

change cmd0_array(37)(0:3) 2#0110
change addr_array(37)  16#0000000030000008
change cmd1_array(37)(11:12)  2#11
change data_array(37)(64:95) 16#ffff0000
change be_array(37)(8:11)  2#1111

change cmd0_array(38)(0:3) 2#0010
change addr_array(38)  16#0000000030000008
change cmd0_array(38)(4:7)  2#0000
change be_array(38)(0:15)  2#0000000011110000

change cmd0_array(39)(0:3) 2#0110
change addr_array(39)  16#000000003000000c
change cmd1_array(39)(11:12)  2#11
change data_array(39)(96:127) 16#01000000
change be_array(39)(12:15)  2#1111

change cmd0_array(40)(0:3) 2#0010
change addr_array(40)  16#000000003000000c
change cmd0_array(40)(4:7)  2#0000
change be_array(40)(0:15)  2#0000000000001100

change cmd0_array(41)(0:3) 2#0110
change addr_array(41)  16#000000003000000c
change cmd1_array(41)(11:12)  2#11
change data_array(41)(96:127) 16#0000000a
change be_array(41)(12:15)  2#1111

change cmd0_array(42)(0:3) 2#0010
change addr_array(42)  16#000000003000000f
change cmd0_array(42)(4:7)  2#0000
change be_array(42)(0:15)  2#0000000000000001

change cmd0_array(43)(0:3) 2#0110
change addr_array(43)  16#0000000030000000
change cmd1_array(43)(11:12)  2#11
change data_array(43)(0:31) 16#00400000
change be_array(43)(0:3)  2#1111

change cmd0_array(44)(0:3) 2#0001
change addr_array(44)  16#0000000030000001
change cmd0_array(44)(4:7)  2#0000
change be_array(44)(0:15)  2#0100000000000000

change cmd0_array(45)(0:3) 2#0100
change addr_array(45)(36)  1

change cmd0_array(46)(0:3) 2#0101
change addr_array(46)(35)  1

change cmd0_array(47)(0:3) 2#0110
change addr_array(47)  16#0000000030000000
change cmd1_array(47)(11:12)  2#11
change data_array(47)(0:31) 16#00800000
change be_array(47)(0:3)  2#1111

change cmd0_array(48)(0:3) 2#0001
change addr_array(48)  16#0000000030000001
change cmd0_array(48)(4:7)  2#0000
change be_array(48)(0:15)  2#0100000000000000

change cmd0_array(49)(0:3) 2#0110
change addr_array(49)  16#0000000030000000
change cmd1_array(49)(11:12)  2#11
change data_array(49)(0:31) 16#00000000
change be_array(49)(0:3)  2#1111

change cmd0_array(50)(0:3) 2#0010
change addr_array(50)  16#0000000030000001
change cmd0_array(50)(4:7)  2#0000
change be_array(50)(0:15)  2#0100000000000000

change cmd0_array(51)(0:3) 2#0001
change addr_array(51)  16#0000000030000001
change cmd0_array(51)(4:7)  2#0000
change be_array(51)(0:15)  2#0100000000000000

change cmd0_array(52)(0:3) 2#0110
change addr_array(52)  16#0000000030000000
change cmd1_array(52)(11:12)  2#11
change data_array(52)(0:31) 16#50000000
change be_array(52)(0:3)  2#1111

change cmd0_array(53)(0:3) 2#0010
change addr_array(53)  16#0000000030000000
change cmd0_array(53)(4:7)  2#0000
change be_array(53)(0:15)  2#1000000000000000

change cmd0_array(54)(0:3) 2#0110
change addr_array(54)  16#0000000030000004
change cmd1_array(54)(11:12)  2#11
change data_array(54)(32:63) 16#20000000
change be_array(54)(4:7)  2#1111

change cmd0_array(55)(0:3) 2#0010
change addr_array(55)  16#0000000030000004
change cmd0_array(55)(4:7)  2#0000
change be_array(55)(0:15)  2#0000111100000000

change cmd0_array(56)(0:3) 2#0110
change addr_array(56)  16#0000000030000008
change cmd1_array(56)(11:12)  2#11
change data_array(56)(64:95) 16#ffff0000
change be_array(56)(8:11)  2#1111

change cmd0_array(57)(0:3) 2#0010
change addr_array(57)  16#0000000030000008
change cmd0_array(57)(4:7)  2#0000
change be_array(57)(0:15)  2#0000000011110000

change cmd0_array(58)(0:3) 2#0110
change addr_array(58)  16#000000003000000c
change cmd1_array(58)(11:12)  2#11
change data_array(58)(96:127) 16#01000000
change be_array(58)(12:15)  2#1111

change cmd0_array(59)(0:3) 2#0010
change addr_array(59)  16#000000003000000c
change cmd0_array(59)(4:7)  2#0000
change be_array(59)(0:15)  2#0000000000001100

change cmd0_array(60)(0:3) 2#0110
change addr_array(60)  16#000000003000000c
change cmd1_array(60)(11:12)  2#11
change data_array(60)(96:127) 16#0000000a
change be_array(60)(12:15)  2#1111

change cmd0_array(61)(0:3) 2#0010
change addr_array(61)  16#000000003000000f
change cmd0_array(61)(4:7)  2#0000
change be_array(61)(0:15)  2#0000000000000001

change cmd0_array(62)(0:3) 2#0110
change addr_array(62)  16#0000000030000000
change cmd1_array(62)(11:12)  2#11
change data_array(62)(0:31) 16#00400000
change be_array(62)(0:3)  2#1111

change cmd0_array(63)(0:3) 2#0001
change addr_array(63)  16#0000000030000001
change cmd0_array(63)(4:7)  2#0000
change be_array(63)(0:15)  2#0100000000000000

change cmd0_array(64)(0:3) 2#0100
change addr_array(64)(36)  1

change cmd0_array(65)(0:3) 2#0101
change addr_array(65)(35)  1

change cmd0_array(66)(0:3) 2#0110
change addr_array(66)  16#0000000030000000
change cmd1_array(66)(11:12)  2#11
change data_array(66)(0:31) 16#00800000
change be_array(66)(0:3)  2#1111

change cmd0_array(67)(0:3) 2#0001
change addr_array(67)  16#0000000030000001
change cmd0_array(67)(4:7)  2#0000
change be_array(67)(0:15)  2#0100000000000000

change cmd0_array(68)(0:3) 2#0110
change addr_array(68)  16#0000000030000000
change cmd1_array(68)(11:12)  2#11
change data_array(68)(0:31) 16#00000000
change be_array(68)(0:3)  2#1111

change cmd0_array(69)(0:3) 2#0010
change addr_array(69)  16#0000000030000001
change cmd0_array(69)(4:7)  2#0000
change be_array(69)(0:15)  2#0100000000000000

change cmd0_array(70)(0:3) 2#0001
change addr_array(70)  16#0000000030000001
change cmd0_array(70)(4:7)  2#0000
change be_array(70)(0:15)  2#0100000000000000

change cmd0_array(71)(0:3) 2#0110
change addr_array(71)  16#0000000020000000
change cmd1_array(71)(11:12)  2#11
change data_array(71)(0:63) 16#0001020304050607
change be_array(71)(0:7)  2#11111111

change cmd0_array(72)(0:3) 2#0110
change addr_array(72)  16#0000000020000008
change cmd1_array(72)(11:12)  2#11
change data_array(72)(64:127) 16#08090a0b0c0d0e0f
change be_array(72)(8:15)  2#11111111

change cmd0_array(73)(0:3) 2#0110
change addr_array(73)  16#0000000020000010
change cmd1_array(73)(11:12)  2#11
change data_array(73)(0:63) 16#1011121314151617
change be_array(73)(0:7)  2#11111111

change cmd0_array(74)(0:3) 2#0110
change addr_array(74)  16#0000000020000018
change cmd1_array(74)(11:12)  2#11
change data_array(74)(64:127) 16#18191a1b1c1d1e1f
change be_array(74)(8:15)  2#11111111

change cmd0_array(75)(0:3) 2#0110
change addr_array(75)  16#0000000020000020
change cmd1_array(75)(11:12)  2#11
change data_array(75)(0:63) 16#2021222324252627
change be_array(75)(0:7)  2#11111111

change cmd0_array(76)(0:3) 2#0110
change addr_array(76)  16#0000000020000028
change cmd1_array(76)(11:12)  2#11
change data_array(76)(64:127) 16#28292a2b2c2d2e2f
change be_array(76)(8:15)  2#11111111

change cmd0_array(77)(0:3) 2#0110
change addr_array(77)  16#0000000020000030
change cmd1_array(77)(11:12)  2#11
change data_array(77)(0:63) 16#3031323334353637
change be_array(77)(0:7)  2#11111111

change cmd0_array(78)(0:3) 2#0110
change addr_array(78)  16#0000000020000038
change cmd1_array(78)(11:12)  2#11
change data_array(78)(64:127) 16#38393a3b3c3d3e3f
change be_array(78)(8:15)  2#11111111

change cmd0_array(79)(0:3) 2#0110
change addr_array(79)  16#0000000020000040
change cmd1_array(79)(11:12)  2#11
change data_array(79)(0:63) 16#4041424344454647
change be_array(79)(0:7)  2#11111111

change cmd0_array(80)(0:3) 2#0110
change addr_array(80)  16#0000000020000048
change cmd1_array(80)(11:12)  2#11
change data_array(80)(64:127) 16#48494a4b4c4d4e4f
change be_array(80)(8:15)  2#11111111

change cmd0_array(81)(0:3) 2#0110
change addr_array(81)  16#0000000020000050
change cmd1_array(81)(11:12)  2#11
change data_array(81)(0:63) 16#5051525354555657
change be_array(81)(0:7)  2#11111111

change cmd0_array(82)(0:3) 2#0110
change addr_array(82)  16#0000000020000058
change cmd1_array(82)(11:12)  2#11
change data_array(82)(64:127) 16#58595a5b5c5d5e5f
change be_array(82)(8:15)  2#11111111

change cmd0_array(83)(0:3) 2#0110
change addr_array(83)  16#0000000020000060
change cmd1_array(83)(11:12)  2#11
change data_array(83)(0:63) 16#6061626364656667
change be_array(83)(0:7)  2#11111111

change cmd0_array(84)(0:3) 2#0110
change addr_array(84)  16#0000000020000068
change cmd1_array(84)(11:12)  2#11
change data_array(84)(64:127) 16#68696a6b6c6d6e6f
change be_array(84)(8:15)  2#11111111

change cmd0_array(85)(0:3) 2#0110
change addr_array(85)  16#0000000020000070
change cmd1_array(85)(11:12)  2#11
change data_array(85)(0:63) 16#7071727374757677
change be_array(85)(0:7)  2#11111111

change cmd0_array(86)(0:3) 2#0110
change addr_array(86)  16#0000000020000078
change cmd1_array(86)(11:12)  2#11
change data_array(86)(64:127) 16#78797a7b7c7d7e7f
change be_array(86)(8:15)  2#11111111

change cmd0_array(87)(0:3) 2#0001
change addr_array(87)  16#0000000020000000
change cmd0_array(87)(4:7)  2#0000
change be_array(87)(0:15)  2#1111111100000000

change cmd0_array(88)(0:3) 2#0001
change addr_array(88)  16#0000000020000008
change cmd0_array(88)(4:7)  2#0000
change be_array(88)(0:15)  2#0000000011111111

change cmd0_array(89)(0:3) 2#0001
change addr_array(89)  16#0000000020000010
change cmd0_array(89)(4:7)  2#0000
change be_array(89)(0:15)  2#1111111100000000

change cmd0_array(90)(0:3) 2#0001
change addr_array(90)  16#0000000020000018
change cmd0_array(90)(4:7)  2#0000
change be_array(90)(0:15)  2#0000000011111111

change cmd0_array(91)(0:3) 2#0001
change addr_array(91)  16#0000000020000020
change cmd0_array(91)(4:7)  2#0000
change be_array(91)(0:15)  2#1111111100000000

change cmd0_array(92)(0:3) 2#0001
change addr_array(92)  16#0000000020000028
change cmd0_array(92)(4:7)  2#0000
change be_array(92)(0:15)  2#0000000011111111

change cmd0_array(93)(0:3) 2#0001
change addr_array(93)  16#0000000020000030
change cmd0_array(93)(4:7)  2#0000
change be_array(93)(0:15)  2#1111111100000000

change cmd0_array(94)(0:3) 2#0001
change addr_array(94)  16#0000000020000038
change cmd0_array(94)(4:7)  2#0000
change be_array(94)(0:15)  2#0000000011111111

change cmd0_array(95)(0:3) 2#0001
change addr_array(95)  16#0000000020000040
change cmd0_array(95)(4:7)  2#0000
change be_array(95)(0:15)  2#1111111100000000

change cmd0_array(96)(0:3) 2#0001
change addr_array(96)  16#0000000020000048
change cmd0_array(96)(4:7)  2#0000
change be_array(96)(0:15)  2#0000000011111111

change cmd0_array(97)(0:3) 2#0001
change addr_array(97)  16#0000000020000050
change cmd0_array(97)(4:7)  2#0000
change be_array(97)(0:15)  2#1111111100000000

change cmd0_array(98)(0:3) 2#0001
change addr_array(98)  16#0000000020000058
change cmd0_array(98)(4:7)  2#0000
change be_array(98)(0:15)  2#0000000011111111

change cmd0_array(99)(0:3) 2#0001
change addr_array(99)  16#0000000020000060
change cmd0_array(99)(4:7)  2#0000
change be_array(99)(0:15)  2#1111111100000000

change cmd0_array(100)(0:3) 2#0001
change addr_array(100)  16#0000000020000068
change cmd0_array(100)(4:7)  2#0000
change be_array(100)(0:15)  2#0000000011111111

change cmd0_array(101)(0:3) 2#0001
change addr_array(101)  16#0000000020000070
change cmd0_array(101)(4:7)  2#0000
change be_array(101)(0:15)  2#1111111100000000

change cmd0_array(102)(0:3) 2#0001
change addr_array(102)  16#0000000020000078
change cmd0_array(102)(4:7)  2#0000
change be_array(102)(0:15)  2#0000000011111111

change cmd0_array(103)(0:3) 2#0100
change addr_array(103)(34)  1

env /
