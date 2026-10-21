vlib work

vlog ../RTL/*.sv +cover

# Compile UVM package, interface, and testbench
vlog +incdir+../ ../packages/Packet_buffer_SBRX_pkg.sv ../interfaces/Packet_buffer_SBRX_if.sv ../tb/tb_top.sv +cover -covercells

# Elaborate and run
vsim -voptargs=+acc -classdebug work.tb_top -cover -uvmcontrol=all +UVM_TESTNAME=Packet_buffer_SBRX_base_test

coverage save Packet_buffer_SBRX_coverage.ucdb -onexit -du work.Packet_buffer_SBRX

run 0

# do wave.do
add wave -position insertpoint sim:/tb_top/dut/*
add wave -position insertpoint  \
sim:/tb_top/dut/mem
run -all

# ---------------- Coverage ----------------
coverage save Packet_buffer_SBRX_coverage.ucdb
coverage report -du=work.Packet_buffer_SBRX -code bcesft -summary
coverage report -cvg -summary

coverage report -output coverage_detailed_report.txt -details -du=work.Packet_buffer_SBRX -code bcesft
coverage report -output coverage_detailed_report.txt -append -details -cvg
