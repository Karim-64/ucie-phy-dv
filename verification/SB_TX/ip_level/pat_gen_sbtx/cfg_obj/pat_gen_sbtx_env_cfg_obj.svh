`ifndef PAT_GEN_SBTX_ENV_CFG_OBJ_SVH
`define PAT_GEN_SBTX_ENV_CFG_OBJ_SVH

class pat_gen_sbtx_env_cfg_obj extends uvm_object;
  `uvm_object_utils(pat_gen_sbtx_env_cfg_obj);

  virtual pat_gen_sbtx_if#() pat_gen_sbtx_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit pat_gen_sbtx_has_scoreboard;
  bit pat_gen_sbtx_has_subscriber;
  bit pat_gen_sbtx_has_agent;
  bit pat_gen_sbtx_has_monitor;

  function new(string name = "pat_gen_sbtx_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // PAT_GEN_SBTX_ENV_CFG_OBJ_SVH
