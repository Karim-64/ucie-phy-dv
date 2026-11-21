vlib work

vlog ../RTL/*.sv +cover

# Compile UVM package, interface, and testbench
vlog +incdir+.. ../packages/Serializer_pkg.sv ../interfaces/Serializer_if.sv ../tb/serializer_assertions.sv ../tb/tb_top.sv +cover -covercells

# Elaborate and run
vsim -voptargs=+acc -classdebug work.tb_top -cover -uvmcontrol=all +UVM_TESTNAME=Serializer_base_test

coverage save Serializer_coverage.ucdb -onexit -du work.Serializer

run 0

do wave.do

run -all

coverage save Serializer_coverage.ucdb

echo "=================================================="
echo ">>> DUT CODE COVERAGE SUMMARY"
echo "=================================================="
coverage exclude -src ../RTL/Serializer.sv -line 30 -code c
coverage report -du=work.Serializer -code bcesft -summary

echo "=================================================="
echo ">>> FUNCTIONAL COVERAGE (COVERGROUPS) SUMMARY"
echo "=================================================="
coverage report -cvg -summary

echo "=================================================="
echo ">>> ASSERTION COVERAGE SUMMARY"
echo "=================================================="
coverage report -assert -summary

# Detailed breakdown to file: DUT code coverage first, then covergroups appended
coverage report -output coverage_detailed_report.txt -details -du=work.Serializer -code bcesft
coverage report -output coverage_detailed_report.txt -append -details -cvg
coverage report -output coverage_detailed_report.txt -append -details -assert

echo ">>> Detailed coverage written to coverage_detailed_report.txt"
