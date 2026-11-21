`ifndef GRAY_SYNCHRONIZER_SBTX_ENV_CFG_OBJ_SVH
`define GRAY_SYNCHRONIZER_SBTX_ENV_CFG_OBJ_SVH

class gray_synchronizer_sbtx_env_cfg_obj extends uvm_object;
  `uvm_object_utils(gray_synchronizer_sbtx_env_cfg_obj);

  virtual gray_synchronizer_sbtx_if#(DATA_SIZE) gray_synchronizer_sbtx_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit gray_synchronizer_sbtx_has_scoreboard;
  bit gray_synchronizer_sbtx_has_subscriber;
  bit gray_synchronizer_sbtx_has_agent;
  bit gray_synchronizer_sbtx_has_monitor;

  function new(string name = "gray_synchronizer_sbtx_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // GRAY_SYNCHRONIZER_SBTX_ENV_CFG_OBJ_SVH
