

vsim work.ac97_timing

add wave *

# Add clock (40.69ns low, 40.69 ns high)
force Bit_Clk 0
force Bit_Clk 1 40.69 ns, 0 {81.38 ns} -r 81.38ns