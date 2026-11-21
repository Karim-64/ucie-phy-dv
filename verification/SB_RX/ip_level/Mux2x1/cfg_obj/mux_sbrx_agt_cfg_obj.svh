`ifndef MUX_SBRX_AGT_CFG_OBJ_SVH
`define MUX_SBRX_AGT_CFG_OBJ_SVH

class mux_sbrx_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(mux_sbrx_agt_cfg_obj);

  virtual mux_sbrx_if#(INPUT_WIDTH) mux_sbrx_vif;
  uvm_active_passive_enum is_active;
  bit mux_sbrx_has_monitor;

  function new(string name = "mux_sbrx_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // MUX_SBRX_AGT_CFG_OBJ_SVH
