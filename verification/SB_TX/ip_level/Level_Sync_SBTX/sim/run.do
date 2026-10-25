vlib work

vlog ../RTL/*.sv +cover

# Compile UVM package, interface, and testbench
vlog +incdir+../ ../packages/level_sync_sbtx_pkg.sv ../interfaces/level_sync_sbtx_if.sv ../tb/tb_top.sv +cover -covercells

# Elaborate and run
vsim -voptargs=+acc -classdebug work.tb_top -cover -uvmcontrol=all +UVM_TESTNAME=level_sync_sbtx_base_test

coverage save level_sync_sbtx_coverage.ucdb -onexit -du work.Level_Sync_SBTX

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