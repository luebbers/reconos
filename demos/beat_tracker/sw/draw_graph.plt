set xrange [14:49]
set yrange [0:2500]
set xzeroaxis
set yzeroaxis
set xlabel "sound frame"
set ylabel "thousand clock cycles/frame"
#set logscale y
set size 0.6,0.6

set terminal postscript eps color enhanced
#set terminal postscript
set output "measurements.eps"

set key 44, 2400

plot 'partitioning_sw.txt' using 1:($2/1000) title "sw" with lines lw 3, 'partitioning_hw_o.txt' using 1:($2/1000) title "hw_{o}" with lines lw 3, 'partitioning_hw_oo.txt' using 1:($2/1000) title "hw_{oo}" with lines lw 3, 'partitioning_hw_i.txt' using 1:($2/1000) title "hw_i" with lines lw 3, 'partitioning_hw_ii.txt' using 1:($2/1000) title "hw_{ii}" with lines lw 3, 'partitioning_hw_oi.txt' using 1:($2/1000) title "hw_{oi}" with lines lw 3, 'partitioning_hw_ooi.txt' using 1:($2/1000) title "hw_{ooi}" with lines lw 3, 'partitioning_hw_oii.txt' using 1:($2/1000) title "hw_{oii}" with lines lw 3, 'partitioning_hw_ooii.txt' using 1:($2/1000) title "hw_{ooii}" with lines lw 3

