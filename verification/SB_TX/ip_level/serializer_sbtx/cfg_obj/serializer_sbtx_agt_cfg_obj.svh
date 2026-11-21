`ifndef SERIALIZER_SBTX_AGT_CFG_OBJ_SVH
`define SERIALIZER_SBTX_AGT_CFG_OBJ_SVH

class serializer_sbtx_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(serializer_sbtx_agt_cfg_obj);

  virtual serializer_sbtx_if#(DATA_WIDTH) serializer_sbtx_vif;
  uvm_active_passive_enum is_active;
  bit serializer_sbtx_has_monitor;

  function new(string name = "serializer_sbtx_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // SERIALIZER_SBTX_AGT_CFG_OBJ_SVH
