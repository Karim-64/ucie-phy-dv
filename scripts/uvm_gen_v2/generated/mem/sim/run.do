vlib work

vlog ../RTL/*.sv +cover

# Compile UVM package, interface, and testbench
vlog +incdir+../ ../packages/mem_pkg.sv ../interfaces/mem_if.sv ../tb/tb_top.sv +cover -covercells

# Elaborate and run
vsim -voptargs=+acc -classdebug work.tb_top -cover -uvmcontrol=all +UVM_TESTNAME=mem_base_test

coverage save mem_coverage.ucdb -onexit -du work.Memory

run 0

# do wave.do

run -all
