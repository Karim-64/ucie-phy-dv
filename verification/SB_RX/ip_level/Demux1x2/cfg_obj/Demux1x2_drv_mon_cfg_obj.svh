`ifndef DEMUX1X2_DRV_MON_CFG_OBJ_SVH
`define DEMUX1X2_DRV_MON_CFG_OBJ_SVH

class Demux1x2_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(Demux1x2_drv_mon_cfg_obj)

  virtual Demux1x2_if #(DATA_WIDTH) Demux1x2_vif;

  function new(string name = "Demux1x2_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // DEMUX1X2_DRV_MON_CFG_OBJ_SVH
