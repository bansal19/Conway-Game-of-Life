vlib work

vlog -timescale 1ns/1ns part2.v

vsim -L altera_mf_ver -L lpm_ver try

log {/*}
add wave {/*}

force {clk} 0 0, 1 5 -r 10

force {go} 0 0
force {reset_n} 1 0

force {glide} 1 0, 0 30 
force {explode} 0 0
force {tumble} 0 0
force {space} 0 0
force {gun} 0 0
force {clear} 0 0

run 300000
