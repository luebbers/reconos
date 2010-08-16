






























































































































env /bfm_system/bfm_memory/bfm_memory/slave/slave/
force -deposit ssize_mode 2#101

env /bfm_system/bfm_memory/bfm_memory/slave/slave/slave_mem
change plb_slave_addr_array(0)  16#0000000010000001
change plb_slave_data_array(0)(0:31) 16#00010203

change plb_slave_addr_array(0)  16#0000000010000001
change plb_slave_data_array(0)(32:63) 16#04050607

change plb_slave_addr_array(0)  16#0000000010000001
change plb_slave_data_array(0)(64:95) 16#08090a0b

change plb_slave_addr_array(0)  16#0000000010000001
change plb_slave_data_array(0)(96:127) 16#0c0d0e0f

change plb_slave_addr_array(1)  16#0000000010000011
change plb_slave_data_array(1)(0:31) 16#10111213

change plb_slave_addr_array(1)  16#0000000010000011
change plb_slave_data_array(1)(32:63) 16#14151617

change plb_slave_addr_array(1)  16#0000000010000011
change plb_slave_data_array(1)(64:95) 16#18191a1b

change plb_slave_addr_array(1)  16#0000000010000011
change plb_slave_data_array(1)(96:127) 16#1c1d1e1f

change plb_slave_addr_array(2)  16#0000000010000021
change plb_slave_data_array(2)(0:31) 16#20212223

change plb_slave_addr_array(2)  16#0000000010000021
change plb_slave_data_array(2)(32:63) 16#24252627

change plb_slave_addr_array(2)  16#0000000010000021
change plb_slave_data_array(2)(64:95) 16#28292a2b

change plb_slave_addr_array(2)  16#0000000010000021
change plb_slave_data_array(2)(96:127) 16#2c2d2e2f

change plb_slave_addr_array(3)  16#0000000010000031
change plb_slave_data_array(3)(0:31) 16#30313233

change plb_slave_addr_array(3)  16#0000000010000031
change plb_slave_data_array(3)(32:63) 16#34353637

change plb_slave_addr_array(3)  16#0000000010000031
change plb_slave_data_array(3)(64:95) 16#38393a3b

change plb_slave_addr_array(3)  16#0000000010000031
change plb_slave_data_array(3)(96:127) 16#3c3d3e3f

change plb_slave_addr_array(4)  16#0000000010000041
change plb_slave_data_array(4)(0:31) 16#40414243

change plb_slave_addr_array(4)  16#0000000010000041
change plb_slave_data_array(4)(32:63) 16#44454647

change plb_slave_addr_array(4)  16#0000000010000041
change plb_slave_data_array(4)(64:95) 16#48494a4b

change plb_slave_addr_array(4)  16#0000000010000041
change plb_slave_data_array(4)(96:127) 16#4c4d4e4f

change plb_slave_addr_array(5)  16#0000000010000051
change plb_slave_data_array(5)(0:31) 16#50515253

change plb_slave_addr_array(5)  16#0000000010000051
change plb_slave_data_array(5)(32:63) 16#54555657

change plb_slave_addr_array(5)  16#0000000010000051
change plb_slave_data_array(5)(64:95) 16#58595a5b

change plb_slave_addr_array(5)  16#0000000010000051
change plb_slave_data_array(5)(96:127) 16#5c5d5e5f

change plb_slave_addr_array(6)  16#0000000010000061
change plb_slave_data_array(6)(0:31) 16#60616263

change plb_slave_addr_array(6)  16#0000000010000061
change plb_slave_data_array(6)(32:63) 16#64656667

change plb_slave_addr_array(6)  16#0000000010000061
change plb_slave_data_array(6)(64:95) 16#68696a6b

change plb_slave_addr_array(6)  16#0000000010000061
change plb_slave_data_array(6)(96:127) 16#6c6d6e6f

change plb_slave_addr_array(7)  16#0000000010000071
change plb_slave_data_array(7)(0:31) 16#70717273

change plb_slave_addr_array(7)  16#0000000010000071
change plb_slave_data_array(7)(32:63) 16#74757677

change plb_slave_addr_array(7)  16#0000000010000071
change plb_slave_data_array(7)(64:95) 16#78797a7b

change plb_slave_addr_array(7)  16#0000000010000071
change plb_slave_data_array(7)(96:127) 16#7c7d7e7f

change plb_slave_addr_array(8)  16#0000000010000081
change plb_slave_data_array(8)(0:31) 16#80818283

change plb_slave_addr_array(8)  16#0000000010000081
change plb_slave_data_array(8)(32:63) 16#84858687

change plb_slave_addr_array(8)  16#0000000010000081
change plb_slave_data_array(8)(64:95) 16#88898a8b

change plb_slave_addr_array(8)  16#0000000010000081
change plb_slave_data_array(8)(96:127) 16#8c8d8e8f

change plb_slave_addr_array(9)  16#0000000020000001
change plb_slave_data_array(9)(0:31) 16#deadbeef

change plb_slave_addr_array(9)  16#0000000020000001
change plb_slave_data_array(9)(32:63) 16#deadbeef

change plb_slave_addr_array(9)  16#0000000020000001
change plb_slave_data_array(9)(64:95) 16#deadbeef

change plb_slave_addr_array(9)  16#0000000020000001
change plb_slave_data_array(9)(96:127) 16#deadbeef

change plb_slave_addr_array(10)  16#0000000020000011
change plb_slave_data_array(10)(0:31) 16#deadbeef

change plb_slave_addr_array(10)  16#0000000020000011
change plb_slave_data_array(10)(32:63) 16#deadbeef

change plb_slave_addr_array(10)  16#0000000020000011
change plb_slave_data_array(10)(64:95) 16#deadbeef

change plb_slave_addr_array(10)  16#0000000020000011
change plb_slave_data_array(10)(96:127) 16#deadbeef

change plb_slave_addr_array(11)  16#0000000020000021
change plb_slave_data_array(11)(0:31) 16#deadbeef

change plb_slave_addr_array(11)  16#0000000020000021
change plb_slave_data_array(11)(32:63) 16#deadbeef

change plb_slave_addr_array(11)  16#0000000020000021
change plb_slave_data_array(11)(64:95) 16#deadbeef

change plb_slave_addr_array(11)  16#0000000020000021
change plb_slave_data_array(11)(96:127) 16#deadbeef

change plb_slave_addr_array(12)  16#0000000020000031
change plb_slave_data_array(12)(0:31) 16#deadbeef

change plb_slave_addr_array(12)  16#0000000020000031
change plb_slave_data_array(12)(32:63) 16#deadbeef

change plb_slave_addr_array(12)  16#0000000020000031
change plb_slave_data_array(12)(64:95) 16#deadbeef

change plb_slave_addr_array(12)  16#0000000020000031
change plb_slave_data_array(12)(96:127) 16#deadbeef

change plb_slave_addr_array(13)  16#0000000020000041
change plb_slave_data_array(13)(0:31) 16#deadbeef

change plb_slave_addr_array(13)  16#0000000020000041
change plb_slave_data_array(13)(32:63) 16#deadbeef

change plb_slave_addr_array(13)  16#0000000020000041
change plb_slave_data_array(13)(64:95) 16#deadbeef

change plb_slave_addr_array(13)  16#0000000020000041
change plb_slave_data_array(13)(96:127) 16#deadbeef

change plb_slave_addr_array(14)  16#0000000020000051
change plb_slave_data_array(14)(0:31) 16#deadbeef

change plb_slave_addr_array(14)  16#0000000020000051
change plb_slave_data_array(14)(32:63) 16#deadbeef

change plb_slave_addr_array(14)  16#0000000020000051
change plb_slave_data_array(14)(64:95) 16#deadbeef

change plb_slave_addr_array(14)  16#0000000020000051
change plb_slave_data_array(14)(96:127) 16#deadbeef

change plb_slave_addr_array(15)  16#0000000020000061
change plb_slave_data_array(15)(0:31) 16#deadbeef

change plb_slave_addr_array(15)  16#0000000020000061
change plb_slave_data_array(15)(32:63) 16#deadbeef

change plb_slave_addr_array(15)  16#0000000020000061
change plb_slave_data_array(15)(64:95) 16#deadbeef

change plb_slave_addr_array(15)  16#0000000020000061
change plb_slave_data_array(15)(96:127) 16#deadbeef

change plb_slave_addr_array(16)  16#0000000020000071
change plb_slave_data_array(16)(0:31) 16#deadbeef

change plb_slave_addr_array(16)  16#0000000020000071
change plb_slave_data_array(16)(32:63) 16#deadbeef

change plb_slave_addr_array(16)  16#0000000020000071
change plb_slave_data_array(16)(64:95) 16#deadbeef

change plb_slave_addr_array(16)  16#0000000020000071
change plb_slave_data_array(16)(96:127) 16#deadbeef


env /bfm_system/bfm_processor/bfm_processor/master/master/
force -deposit msize_mode 2#101

env /bfm_system/bfm_processor/bfm_processor/master/master/decoder
change cmd0_array(0)(0:3) 2#0101
change addr_array(0)(33)  1

change cmd0_array(1)(0:3) 2#0100
change addr_array(1)(34)  1

env /
