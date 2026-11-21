vlib work


vlog ../RTL/*.sv +cover

# Compile UVM package, interface, and testbench
vlog +incdir+.. ../packages/Synchronizer_SBRX_pkg.sv ../interfaces/Synchronizer_SBRX_if.sv ../tb/Synchronizer_SBRX_assertions.sv ../tb/tb_top.sv +cover -covercells

# Elaborate and run
vsim -voptargs=+acc -classdebug work.tb_top -cover -uvmcontrol=all +UVM_TESTNAME=Synchronizer_SBRX_base_test

run 0

# do wave.do

run -all


coverage save Synchronizer_SBRX_coverage.ucdb

echo "=================================================="
echo ">>> DUT CODE COVERAGE SUMMARY"
echo "=================================================="
coverage report -du=work.Synchronizer_SBRX -code bcesft -summary

echo "=================================================="
echo ">>> FUNCTIONAL COVERAGE (COVERGROUPS) SUMMARY"
echo "=================================================="
coverage report -cvg -summary

echo "=================================================="
echo ">>> ASSERTION COVERAGE SUMMARY"
echo "=================================================="
coverage report -assert -summary

# Detailed breakdown to file: DUT code coverage first, then covergroups appended
coverage report -output coverage_detailed_report.txt -details -du=work.Synchronizer_SBRX -code bcesft
coverage report -output coverage_detailed_report.txt -append -details -cvg
coverage report -output coverage_detailed_report.txt -append -details -assert

echo ">>> Detailed coverage written to coverage_detailed_report.txt"