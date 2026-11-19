vlib work

# 1. Compile RTL with code coverage enabled
vlog ../RTL/*.sv +cover

# 2. Compile UVM package, interface, and testbench 
vlog +incdir+../ ../packages/Credits_Handler_SBTX_pkg.sv ../interfaces/Credits_Handler_SBTX_if.sv ../tb/tb_top.sv +cover -covercells

# 3. Elaborate and simulate
#    -onfinish stop: UVM ends the test with $finish. By default vsim then exits (batch mode)
#    or asks for confirmation (GUI), so everything after "run -all" never executes and no
#    coverage report is produced. With "stop" the simulator stays loaded after $finish and
#    this script continues on to the coverage commands below.
vsim -voptargs=+acc -classdebug work.tb_top -cover -uvmcontrol=all -onfinish stop +UVM_TESTNAME=Credits_Handler_SBTX_base_test

run 0
# do wave.do
run -all

# ==============================================================================
# COVERAGE REPORTING (DUT ONLY, SUMMARY IN TERMINAL, DETAIL TO FILE)
# ==============================================================================
coverage save Credits_Handler_SBTX_coverage.ucdb

echo "=================================================="
echo ">>> DUT CODE COVERAGE SUMMARY"
echo "=================================================="
coverage report -du=work.Credits_Handler_SBTX -code bcesft 

echo "=================================================="
echo ">>> FUNCTIONAL COVERAGE (COVERGROUPS) SUMMARY"
echo "=================================================="
coverage report -cvg -summary

# Detailed breakdown to file: DUT code coverage first, then covergroups appended
coverage report -output coverage_detailed_report.txt -details -du=work.Credits_Handler_SBTX -code bcesft
coverage report -output coverage_detailed_report.txt -append -details -cvg

echo ">>> Detailed coverage written to coverage_detailed_report.txt"

# Uncomment for batch runs (vsim -c -do run.do) so the simulator closes when done
# quit -f
