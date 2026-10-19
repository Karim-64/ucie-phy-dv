`ifndef MUX_SBTX_AGT_CFG_OBJ_SVH
`define MUX_SBTX_AGT_CFG_OBJ_SVH

class mux_sbtx_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(mux_sbtx_agt_cfg_obj);

  virtual mux_sbtx_if#(INPUT_WIDTH) mux_sbtx_vif;
  uvm_active_passive_enum is_active;
  bit mux_sbtx_has_monitor;

  function new(string name = "mux_sbtx_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // MUX_SBTX_AGT_CFG_OBJ_SVH
