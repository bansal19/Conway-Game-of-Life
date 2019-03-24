vlib work

vlog -timescale 1ns/1ns part2.v

vsim -L altera_mf_ver try

log {/*}
add wave {/*}

force {clk} 0 0, 1 5 -r 10

force {go} 0 0, 1 10, 0 30
force {reset_n} 1 0

run 1000
