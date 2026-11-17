`ifndef LFSR_PER_LANE_DRV_MON_CFG_OBJ_SVH
`define LFSR_PER_LANE_DRV_MON_CFG_OBJ_SVH

class lfsr_per_lane_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(lfsr_per_lane_drv_mon_cfg_obj)

  virtual lfsr_per_lane_if #(WIDTH, Seed) lfsr_per_lane_vif;

  function new(string name = "lfsr_per_lane_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // LFSR_PER_LANE_DRV_MON_CFG_OBJ_SVH
