vlib work

vlog ../RTL/*.sv +cover

# Compile UVM package, interface, and testbench
vlog +incdir+../ ../packages/Demux1x2_pkg.sv ../interfaces/Demux1x2_if.sv ../tb/Demux1x2_assertions.sv ../tb/tb_top.sv +cover -covercells

# Elaborate and run
vsim -voptargs=+acc -classdebug work.tb_top -cover -uvmcontrol=all +UVM_TESTNAME=Demux1x2_base_test

#coverage save Demux1x2_coverage.ucdb -onexit -du work.Demux1x2

run 0

do wave.do

run -all

coverage save demux_coverage.ucdb

echo "=================================================="
echo ">>> DUT CODE COVERAGE SUMMARY"
echo "=================================================="
coverage report -du=work.Demux1x2 -code bcesft -summary

echo "=================================================="
echo ">>> FUNCTIONAL COVERAGE (COVERGROUPS) SUMMARY"
echo "=================================================="
coverage report -cvg -summary

echo "=================================================="
echo ">>> ASSERTION COVERAGE SUMMARY"
echo "=================================================="
coverage report -assert -summary

# Detailed breakdown to file: DUT code coverage first, then covergroups appended
coverage report -output coverage_detailed_report.txt -details -du=work.Demux1x2 -code bcesft
coverage report -output coverage_detailed_report.txt -append -details -cvg
coverage report -output coverage_detailed_report.txt -append -details -assert

echo ">>> Detailed coverage written to coverage_detailed_report.txt"
