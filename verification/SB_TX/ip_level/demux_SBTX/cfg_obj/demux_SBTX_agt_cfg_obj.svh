`ifndef DEMUX_SBTX_AGT_CFG_OBJ_SVH
`define DEMUX_SBTX_AGT_CFG_OBJ_SVH

class demux_SBTX_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(demux_SBTX_agt_cfg_obj);

  virtual demux_SBTX_if#(DATA_WIDTH) demux_SBTX_vif;
  uvm_active_passive_enum is_active;
  bit demux_SBTX_has_monitor;

  function new(string name = "demux_SBTX_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // DEMUX_SBTX_AGT_CFG_OBJ_SVH
