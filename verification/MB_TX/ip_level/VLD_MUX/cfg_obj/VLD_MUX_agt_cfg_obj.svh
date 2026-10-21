`ifndef VLD_MUX_AGT_CFG_OBJ_SVH
`define VLD_MUX_AGT_CFG_OBJ_SVH

class VLD_MUX_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(VLD_MUX_agt_cfg_obj);

  virtual VLD_MUX_if#() VLD_MUX_vif;
  uvm_active_passive_enum is_active;
  bit VLD_MUX_has_monitor;

  function new(string name = "VLD_MUX_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // VLD_MUX_AGT_CFG_OBJ_SVH
