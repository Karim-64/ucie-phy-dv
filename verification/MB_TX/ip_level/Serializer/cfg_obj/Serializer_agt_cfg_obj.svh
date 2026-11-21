`ifndef SERIALIZER_AGT_CFG_OBJ_SVH
`define SERIALIZER_AGT_CFG_OBJ_SVH

class Serializer_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(Serializer_agt_cfg_obj);

  virtual Serializer_if#() Serializer_vif;
  uvm_active_passive_enum is_active;
  bit Serializer_has_monitor;

  function new(string name = "Serializer_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // SERIALIZER_AGT_CFG_OBJ_SVH
