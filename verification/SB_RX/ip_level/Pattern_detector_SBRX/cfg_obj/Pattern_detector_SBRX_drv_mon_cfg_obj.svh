`ifndef PATTERN_DETECTOR_SBRX_DRV_MON_CFG_OBJ_SVH
`define PATTERN_DETECTOR_SBRX_DRV_MON_CFG_OBJ_SVH

class Pattern_detector_SBRX_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(Pattern_detector_SBRX_drv_mon_cfg_obj)

  virtual Pattern_detector_SBRX_if #(DATA_WIDTH) Pattern_detector_SBRX_vif;

  function new(string name = "Pattern_detector_SBRX_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // PATTERN_DETECTOR_SBRX_DRV_MON_CFG_OBJ_SVH
