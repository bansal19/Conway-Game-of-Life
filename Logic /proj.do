vlib work

vlog -timescale 1ns/1ns part2.v

vsim -L altera_mf_ver -L lpm_ver try

log {/*}
add wave {/*}

force {clk} 0 0, 1 5 -r 10

force {go} 0 0, 1 204600, 0 204800
force {stop} 0 0
force {reset_n} 1 0

force {glide} 1 0, 0 30 
force {explode} 0 0
force {tumble} 0 0
force {space} 0 0
force {gun} 0 0
force {clear} 0 0
force {x_mouse} 10#10 0
force {y_mouse} 10#5 0
force {mouse_click} 0 0, 0 30



run 3000000
