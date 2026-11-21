`ifndef PAT_GEN_SBTX_DRV_MON_CFG_OBJ_SVH
`define PAT_GEN_SBTX_DRV_MON_CFG_OBJ_SVH

class pat_gen_sbtx_drv_mon_cfg_obj extends uvm_object;
  `uvm_object_utils(pat_gen_sbtx_drv_mon_cfg_obj)

  virtual pat_gen_sbtx_if #() pat_gen_sbtx_vif;

  function new(string name = "pat_gen_sbtx_drv_mon_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // PAT_GEN_SBTX_DRV_MON_CFG_OBJ_SVH
