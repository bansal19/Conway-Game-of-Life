vlib work

vlog -timescale 1ns/1ns control.v

vsim -L altera_mf_ver control

log {/*}
add wave {/*}

force {clk} 0 0, 1 5 -r 10

force {go} 0 0, 1 340, 0 360
force {reset_n} 1 0

force {glide} 0 0, 1 10, 0 30
force {explode} 0 0
force {tumble} 0 0
force {space} 0 0
force {gun} 0 0
force {clear} 0 0



run 10000
