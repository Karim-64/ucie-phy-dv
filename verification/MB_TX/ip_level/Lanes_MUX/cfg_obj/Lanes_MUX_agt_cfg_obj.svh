`ifndef LANES_MUX_AGT_CFG_OBJ_SVH
`define LANES_MUX_AGT_CFG_OBJ_SVH

class Lanes_MUX_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(Lanes_MUX_agt_cfg_obj);

  virtual Lanes_MUX_if#() Lanes_MUX_vif;
  uvm_active_passive_enum is_active;
  bit Lanes_MUX_has_monitor;

  function new(string name = "Lanes_MUX_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // LANES_MUX_AGT_CFG_OBJ_SVH
