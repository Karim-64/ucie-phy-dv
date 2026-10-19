`ifndef DEMUX_AGT_CFG_OBJ_SVH
`define DEMUX_AGT_CFG_OBJ_SVH

class demux_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(demux_agt_cfg_obj);

  virtual demux_if#() demux_vif;
  uvm_active_passive_enum is_active;
  bit demux_has_monitor;

  function new(string name = "demux_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // DEMUX_AGT_CFG_OBJ_SVH
