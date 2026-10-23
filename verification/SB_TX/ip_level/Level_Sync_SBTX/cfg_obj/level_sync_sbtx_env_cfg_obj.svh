`ifndef LEVEL_SYNC_SBTX_ENV_CFG_OBJ_SVH
`define LEVEL_SYNC_SBTX_ENV_CFG_OBJ_SVH

class level_sync_sbtx_env_cfg_obj extends uvm_object;
  `uvm_object_utils(level_sync_sbtx_env_cfg_obj);

  virtual level_sync_sbtx_if#() level_sync_sbtx_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit level_sync_sbtx_has_scoreboard;
  bit level_sync_sbtx_has_subscriber;
  bit level_sync_sbtx_has_agent;

  function new(string name = "level_sync_sbtx_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // LEVEL_SYNC_SBTX_ENV_CFG_OBJ_SVH
