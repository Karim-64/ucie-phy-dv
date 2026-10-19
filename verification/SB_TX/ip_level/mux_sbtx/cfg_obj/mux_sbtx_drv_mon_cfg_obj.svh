`ifndef MUX_SBTX_DRV_MON_CFG_OBJ_SVH
`define MUX_SBTX_DRV_MON_CFG_OBJ_SVH

class mux_sbtx_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(mux_sbtx_drv_mon_cfg_obj)

  virtual mux_sbtx_if #(INPUT_WIDTH) mux_sbtx_vif;

  function new(string name = "mux_sbtx_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // MUX_SBTX_DRV_MON_CFG_OBJ_SVH
