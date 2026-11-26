`ifndef WR_CONTROL_SBTX_ENV_CFG_OBJ_SVH
`define WR_CONTROL_SBTX_ENV_CFG_OBJ_SVH

class wr_control_sbtx_env_cfg_obj extends uvm_object;
  `uvm_object_utils(wr_control_sbtx_env_cfg_obj);

  virtual wr_control_sbtx_if#(NC) wr_control_sbtx_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit wr_control_sbtx_has_scoreboard;
  bit wr_control_sbtx_has_subscriber;
  bit wr_control_sbtx_has_agent;
  bit wr_control_sbtx_has_monitor;

  function new(string name = "wr_control_sbtx_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // WR_CONTROL_SBTX_ENV_CFG_OBJ_SVH
