vlib work

vlog -timescale 1ns/1ns datapath.v

vsim datapath

log {/*}
add wave {/*}

force {enable} 1 0
force {clk} 0 0, 1 5 -r 10
force {reset_n} 1 0

force {ld_x} 0 0, 1 5, 0 15
force {ld_y} 0 0, 1 5, 0 15
force {ld_c} 0 0, 1 5

# 
force {register} 00000 0
force {addr} 000000 0
force {data} 1000000000000000000000000000000000000000 0


run 5000
