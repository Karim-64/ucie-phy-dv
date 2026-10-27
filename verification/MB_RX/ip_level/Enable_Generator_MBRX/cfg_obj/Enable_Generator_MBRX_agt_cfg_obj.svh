`ifndef ENABLE_GENERATOR_MBRX_AGT_CFG_OBJ_SVH
`define ENABLE_GENERATOR_MBRX_AGT_CFG_OBJ_SVH

class Enable_Generator_MBRX_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(Enable_Generator_MBRX_agt_cfg_obj);

  virtual Enable_Generator_MBRX_if#(NUM_LANES, FRAME_LENGTH) Enable_Generator_MBRX_vif;
  uvm_active_passive_enum is_active;
  bit Enable_Generator_MBRX_has_monitor;

  function new(string name = "Enable_Generator_MBRX_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // ENABLE_GENERATOR_MBRX_AGT_CFG_OBJ_SVH
