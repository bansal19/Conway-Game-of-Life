vlib work

vlog -timescale 1ns/1ns datapath.v

vsim datapath

log {/*}
add wave {/*}

force {enable} 1 0
force {clk} 0 0, 1 5 -r 10
force {reset_n} 1 0, 0 220, 1 240
force {ld_x} 1 5, 0 15
force {ld_y} 1 5, 0 15
force {ld_c} 1 5

# 
force {register} 00001 0
force {addr} 000001 0
force {data} 10#21 0


run 260
