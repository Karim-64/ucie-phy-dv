vlib work

vlog ../RTL/*.sv +cover

# Compile UVM package, interface, and testbench
vlog +incdir+../ ../packages/demux_SBTX_pkg.sv ../interfaces/demux_SBTX_if.sv ../tb/tb_top.sv +cover -covercells

# Elaborate and run
vsim -voptargs=+acc -classdebug work.tb_top -cover -uvmcontrol=all +UVM_TESTNAME=demux_SBTX_base_test

coverage save demux_SBTX_coverage.ucdb -onexit -du work.demux_SBTX

run 0

# do wave.do
add wave -position insertpoint sim:/tb_top/dut/*
run -all

# ---------------- Coverage ----------------
coverage save demux_SBTX_coverage.ucdb
coverage report -du=work.demux_SBTX -code bcesft -summary
coverage report -cvg -summary

coverage report -output coverage_detailed_report.txt -details -du=work.demux_SBTX -code bcesft
coverage report -output coverage_detailed_report.txt -append -details -cvg
