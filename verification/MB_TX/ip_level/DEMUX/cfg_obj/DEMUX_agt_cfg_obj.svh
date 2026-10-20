`ifndef DEMUX_AGT_CFG_OBJ_SVH
`define DEMUX_AGT_CFG_OBJ_SVH

class DEMUX_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(DEMUX_agt_cfg_obj);

  virtual DEMUX_if#() DEMUX_vif;
  uvm_active_passive_enum is_active;
  bit DEMUX_has_monitor;

  function new(string name = "DEMUX_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // DEMUX_AGT_CFG_OBJ_SVH
