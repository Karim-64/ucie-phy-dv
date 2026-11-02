vlib work

vlog ../RTL/*.sv +cover

# Compile UVM package, interface, and testbench
vlog +incdir+../ ../packages/Enable_Generator_MBRX_pkg.sv ../interfaces/Enable_Generator_MBRX_if.sv ../tb/tb_top.sv +cover -covercells

# Elaborate and run
vsim -voptargs=+acc -classdebug work.tb_top -cover -uvmcontrol=all +UVM_TESTNAME=Enable_Generator_MBRX_base_test

run 0
do wave.do
run -all


coverage save Enable_Generator_MBRX_coverage.ucdb

echo "=================================================="
echo ">>> DUT CODE COVERAGE SUMMARY"
echo "=================================================="
coverage exclude -du Enable_Generator_MBRX -togglenode LTSM_State
coverage exclude -du Enable_Generator_MBRX -togglenode LTSM_State_old

coverage report -du=work.Enable_Generator_MBRX -code bcesft -summary

echo "=================================================="
echo ">>> FUNCTIONAL COVERAGE (COVERGROUPS) SUMMARY"
echo "=================================================="
coverage report -cvg -summary

# Detailed breakdown to file: DUT code coverage first, then covergroups appended
coverage report -output coverage_detailed_report.txt -details -du=work.Enable_Generator_MBRX -code bcesft
coverage report -output coverage_detailed_report.txt -append -details -cvg


echo ">>> Detailed coverage written to coverage_detailed_report.txt"
