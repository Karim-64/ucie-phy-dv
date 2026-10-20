vlib work

# 1. Compile RTL with code coverage enabled
vlog ../RTL/*.sv +cover

# 2. Compile UVM package, interface, and testbench 
vlog +incdir+../ ../packages/Data_MUX_pkg.sv ../interfaces/Data_MUX_if.sv ../tb/tb_top.sv

# 3. Elaborate and simulate
vsim -voptargs=+acc -classdebug work.tb_top -cover -uvmcontrol=all +UVM_TESTNAME=Data_MUX_base_test -onfinish stop

run 0
# do wave.do
run -all

# ==============================================================================
# COVERAGE REPORTING (DUT ONLY, SUMMARY IN TERMINAL, DETAIL TO FILE)
# ==============================================================================
coverage save Data_MUX_coverage.ucdb

echo "=================================================="
echo ">>> DUT CODE COVERAGE SUMMARY"
echo "=================================================="
coverage report -du=work.Data_MUX -code bcesft -summary

echo "=================================================="
echo ">>> FUNCTIONAL COVERAGE (COVERGROUPS) SUMMARY"
echo "=================================================="
coverage report -cvg -summary

# Detailed breakdown to file: DUT code coverage first, then covergroups appended
coverage report -output coverage_detailed_report.txt -details -du=work.Data_MUX -code bcesft
coverage report -output coverage_detailed_report.txt -append -details -cvg

echo ">>> Detailed coverage written to coverage_detailed_report.txt"

# quit -f