catch {vdel -all -lib work}
vlib work
vmap work work

# Compile RTL with all code coverage enabled (Branch, Condition, Expression, Statement, Toggle)
vlog ../RTL/*.sv +cover=bcesft

# Compile UVM package, interface, and testbench
vlog +incdir+../ ../packages/Synchronizer_pkg.sv ../interfaces/Synchronizer_if.sv ../tb/tb_top.sv +cover -covercells

# Elaborate and run with coverage enabled
vsim -voptargs=+acc -classdebug work.tb_top -coverage -uvmcontrol=all +UVM_TESTNAME=Synchronizer_base_test

coverage save Synchronizer_coverage.ucdb -onexit

run 0

# do wave.do

run -all

# -----------------------------------------------------------------------------
# Code Coverage Reports
# -----------------------------------------------------------------------------
# 1. Save final UCDB database
coverage save Synchronizer_coverage.ucdb

# 2. Save detailed Code Coverage report to a text file
coverage report -detail -codeAll -output Synchronizer_code_coverage_report.txt

# 3. Generate interactive HTML coverage report
catch {vcover report -html -htmldir covhtmlreport -details Synchronizer_coverage.ucdb}
