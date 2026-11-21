`ifndef PAT_GEN_SBTX_AGT_CFG_OBJ_SVH
`define PAT_GEN_SBTX_AGT_CFG_OBJ_SVH

class pat_gen_sbtx_agt_cfg_obj extends uvm_object;
  `uvm_object_utils(pat_gen_sbtx_agt_cfg_obj);

  virtual pat_gen_sbtx_if#() pat_gen_sbtx_vif;
  uvm_active_passive_enum is_active;
  bit pat_gen_sbtx_has_monitor;

  function new(string name = "pat_gen_sbtx_agt_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // PAT_GEN_SBTX_AGT_CFG_OBJ_SVH
