# QuestaSim Compilation File List (compile.f)
# Rule: Include directories first, then packages, then interfaces, RTL, and top TB.

+incdir+tb
+incdir+rtl

# 1. Packages (must compile before modules that import them)
# tb/my_uvm_pkg.sv

# 2. Interfaces
# tb/rdi_if.sv

# 3. RTL Files
# rtl/d2d_data_integrity.sv

# 4. Top-Level Testbench
# tb/top_tb.sv
