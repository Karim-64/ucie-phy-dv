# QuestaSim Compilation File List (compile.f)
# Paths are relative to sim/ (cwd of vlog in regress.py)

+incdir+..
+incdir+../RTL

# 1. RTL Packages & Modules
../RTL/OPCODE_pkg.sv
../RTL/Universal_pkg.sv
../RTL/WR_Control_SBTX.sv

# 2. Verification Packages
../packages/packets_pkg.sv
../packages/wr_control_sbtx_pkg.sv

# 3. Interfaces & Assertions
../interfaces/wr_control_sbtx_if.sv
../tb/wr_control_sbtx_sva.sv

# 4. Top-Level Testbench
../tb/tb_top.sv
