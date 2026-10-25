`ifndef CLK_GATE_SBTX_AGT_CFG_OBJ_SVH
`define CLK_GATE_SBTX_AGT_CFG_OBJ_SVH

class clk_gate_sbtx_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(clk_gate_sbtx_agt_cfg_obj);

  virtual clk_gate_sbtx_if#(PULSE_WIDTH) clk_gate_sbtx_vif;
  uvm_active_passive_enum is_active;
  bit clk_gate_sbtx_has_monitor;

  function new(string name = "clk_gate_sbtx_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // CLK_GATE_SBTX_AGT_CFG_OBJ_SVH
