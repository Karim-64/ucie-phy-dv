vlib work

# 1. Compile RTL with code coverage enabled
vlog ../RTL/Universal_pkg.sv ../RTL/Priority_Encoder_SBTX.sv +cover

# 2. Compile UVM package, interface, and testbench 
vlog +incdir+../ ../interfaces/pe_sbtx_in_if.sv ../interfaces/pe_sbtx_out_if.sv ../packages/pe_sbtx_pkg.sv ../tb/tb_top.sv +cover -covercells

# 3. Elaborate and simulate (with Visualizer qwave.db & design.bin dump for batch mode)
#    -onfinish stop: UVM ends the test with $finish. By default vsim then exits (batch mode)
#    or asks for confirmation (GUI), so everything after "run -all" never executes and no
#    coverage report is produced. With "stop" the simulator stays loaded after $finish and
#    this script continues on to the coverage commands below.
    vsim -voptargs="+acc -designfile design.bin" work.tb_top -cover -uvmcontrol=all -qwavedb=+signal=wave_signals.txt+wavefile=qwave.db -onfinish stop +UVM_TESTNAME=pe_sbtx_base_test

# vsim -voptargs=+acc work.tb_top -cover -uvmcontrol=all -onfinish stop +UVM_TESTNAME=pe_sbtx_base_test


run 0
do wave.do
run -all

# ==============================================================================
# COVERAGE REPORTING (DUT ONLY, SUMMARY IN TERMINAL, DETAIL TO FILE)
# ==============================================================================
coverage save pe_sbtx_coverage.ucdb

echo "=================================================="
echo ">>> DUT CODE COVERAGE SUMMARY"
echo "=================================================="
coverage report -du=work.Priority_Encoder_SBTX -code bcesft -summary

echo "=================================================="
echo ">>> FUNCTIONAL COVERAGE (COVERGROUPS) SUMMARY"
echo "=================================================="
coverage report -cvg -summary

# Detailed breakdown to file: DUT code coverage first, then covergroups appended
coverage report -output coverage_detailed_report.txt -details -du=work.Priority_Encoder_SBTX -code bcesft
coverage report -output coverage_detailed_report.txt -append -details -cvg

echo ">>> Detailed coverage written to coverage_detailed_report.txt"

# visualizer -designfile design.bin -wavefile qwave.db