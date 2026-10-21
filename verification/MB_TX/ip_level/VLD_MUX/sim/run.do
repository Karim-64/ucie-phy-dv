vlib work

vlog ../RTL/*.sv +cover

# Compile UVM package, interface, and testbench
vlog +incdir+../ ../packages/VLD_MUX_pkg.sv ../interfaces/VLD_MUX_if.sv ../tb/tb_top.sv +cover -covercells

# Elaborate and run
vsim -voptargs=+acc -classdebug work.tb_top -cover -uvmcontrol=all +UVM_TESTNAME=VLD_MUX_base_test

coverage save VLD_MUX_coverage.ucdb -onexit -du work.VLD_MUX

run 0

# do wave.do
add wave -position insertpoint sim:/tb_top/dut/*
run -all

# ---------------- Coverage ----------------
coverage save VLD_MUX_coverage.ucdb
coverage report -du=work.VLD_MUX -code bcesft -summary
coverage report -cvg -summary

coverage report -output coverage_detailed_report.txt -details -du=work.VLD_MUX -code bcesft
coverage report -output coverage_detailed_report.txt -append -details -cvg
