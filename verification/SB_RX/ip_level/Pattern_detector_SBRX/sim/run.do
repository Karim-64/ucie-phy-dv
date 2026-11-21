vlib work

# 1. Compile RTL with code coverage enabled
vlog ../RTL/*.sv +cover

# 2. Compile UVM package, interface, SVA module, and testbench 
vlog +incdir+../ ../packages/Pattern_detector_SBRX_pkg.sv ../interfaces/Pattern_detector_SBRX_if.sv ../interfaces/Pattern_detector_SBRX_sva.sv ../tb/tb_top.sv +cover -covercells

# 3. Elaborate and simulate
vsim -voptargs=+acc -classdebug work.tb_top -cover -uvmcontrol=all +UVM_TESTNAME=Pattern_detector_SBRX_base_test

run 0
# do wave.do
run -all

# ==============================================================================
# COVERAGE REPORTING (DUT ONLY, SUMMARY IN TERMINAL, DETAIL TO FILE)
# ==============================================================================
coverage save Pattern_detector_SBRX_coverage.ucdb

echo "=================================================="
echo ">>> DUT CODE COVERAGE SUMMARY"
echo "=================================================="
coverage report -du=work.Pattern_detector_SBRX -code bcesft -summary

echo "=================================================="
echo ">>> FUNCTIONAL COVERAGE (COVERGROUPS) SUMMARY"
echo "=================================================="
coverage report -cvg -summary

echo "=================================================="
echo ">>> VPLAN TEST OCCURRENCE (SVA DIRECTIVES) SUMMARY"
echo "=================================================="
coverage report -directive -summary

# Detailed breakdown to file: DUT code coverage, covergroups, and SVA test occurrence directives
coverage report -output coverage_detailed_report.txt -details -du=work.Pattern_detector_SBRX -code bcesft
coverage report -output coverage_detailed_report.txt -append -details -cvg
coverage report -output coverage_detailed_report.txt -append -details -directive

echo ">>> Detailed coverage written to coverage_detailed_report.txt"

# quit -f
