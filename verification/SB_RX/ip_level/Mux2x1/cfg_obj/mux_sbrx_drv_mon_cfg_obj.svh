`ifndef MUX_SBRX_DRV_MON_CFG_OBJ_SVH
`define MUX_SBRX_DRV_MON_CFG_OBJ_SVH

class mux_sbrx_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(mux_sbrx_drv_mon_cfg_obj)

  virtual mux_sbrx_if #(INPUT_WIDTH) mux_sbrx_vif;

  function new(string name = "mux_sbrx_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // MUX_SBRX_DRV_MON_CFG_OBJ_SVH
