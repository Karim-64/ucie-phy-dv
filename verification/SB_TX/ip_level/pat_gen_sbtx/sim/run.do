vlib work

# 1. Compile RTL with code coverage enabled
vlog ../RTL/*.sv +cover

# 2. Compile UVM package, interface, and testbench 
vlog +incdir+../ ../packages/pat_gen_sbtx_pkg.sv ../interfaces/pat_gen_sbtx_if.sv ../tb/tb_top.sv +cover -covercells

# 3. Elaborate and simulate
vsim -voptargs=+acc work.tb_top -cover -uvmcontrol=all -onfinish stop +UVM_TESTNAME=pat_gen_sbtx_base_test

run 0
# do wave.do
run -all

# ==============================================================================
# COVERAGE REPORTING (DUT ONLY, SUMMARY IN TERMINAL, DETAIL TO FILE)
# ==============================================================================
coverage save pat_gen_sbtx_coverage.ucdb

echo "=================================================="
echo ">>> DUT CODE COVERAGE SUMMARY"
echo "=================================================="
coverage report -du=work.Pattern_Generator_SBTX -code bcesft -summary

echo "=================================================="
echo ">>> FUNCTIONAL COVERAGE (COVERGROUPS) SUMMARY"
echo "=================================================="
coverage report -cvg -summary

# Detailed breakdown to file: DUT code coverage first, then covergroups appended
coverage report -output coverage_detailed_report.txt -details -du=work.Pattern_Generator_SBTX -code bcesft
coverage report -output coverage_detailed_report.txt -append -details -cvg

echo ">>> Detailed coverage written to coverage_detailed_report.txt"

# Uncomment for batch runs (vsim -c -do run.do) so the simulator closes when done
# quit -f