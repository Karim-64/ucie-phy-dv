catch {vdel -all -lib work}
vlib work
vmap work work

# Compile RTL with all code coverage enabled (Branch, Condition, Expression, Statement, Toggle)
vlog ../RTL/*.sv +cover=bcesft


# Compile UVM package, interface, and testbench
vlog +incdir+../ ../packages/up_down_counter_pkg.sv ../interfaces/up_down_counter_if.sv ../tb/tb_top.sv +cover -covercells

# Elaborate and run
vsim -voptargs=+acc -classdebug work.tb_top -cover -uvmcontrol=all +UVM_TESTNAME=up_down_counter_base_test

coverage save up_down_counter_coverage.ucdb -onexit -du work.up_down_counter

run 0

# do wave.do

run -all

# -----------------------------------------------------------------------------
# Code Coverage Reports
# -----------------------------------------------------------------------------
# 1. Save final UCDB database
coverage save up_down_counter_coverage.ucdb

# 2. Save detailed Code Coverage report to a text file
coverage report -detail -codeAll -output up_down_counter_code_coverage_report.txt

# 3. Generate interactive HTML coverage report
catch {vcover report -html -htmldir covhtmlreport -details up_down_counter_coverage.ucdb}