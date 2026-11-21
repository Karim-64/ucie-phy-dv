`ifndef PATTERN_DETECTOR_SBRX_AGT_CFG_OBJ_SVH
`define PATTERN_DETECTOR_SBRX_AGT_CFG_OBJ_SVH

class Pattern_detector_SBRX_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(Pattern_detector_SBRX_agt_cfg_obj);

  virtual Pattern_detector_SBRX_if#(DATA_WIDTH) Pattern_detector_SBRX_vif;
  uvm_active_passive_enum is_active;
  bit Pattern_detector_SBRX_has_monitor;

  function new(string name = "Pattern_detector_SBRX_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // PATTERN_DETECTOR_SBRX_AGT_CFG_OBJ_SVH
