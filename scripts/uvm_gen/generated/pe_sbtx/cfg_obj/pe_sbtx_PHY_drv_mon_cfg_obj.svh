`ifndef PE_SBTX_PHY_DRV_MON_CFG_OBJ_SVH
`define PE_SBTX_PHY_DRV_MON_CFG_OBJ_SVH

class pe_sbtx_PHY_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(pe_sbtx_PHY_drv_mon_cfg_obj)

  virtual pe_sbtx_in_if#(DATA_WIDTH) pe_sbtx_vif;

  function new(string name = "pe_sbtx_PHY_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // PE_SBTX_PHY_DRV_MON_CFG_OBJ_SVH
