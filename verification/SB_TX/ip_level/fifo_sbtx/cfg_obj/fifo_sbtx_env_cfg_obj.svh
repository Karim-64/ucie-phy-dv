`ifndef FIFO_SBTX_ENV_CFG_OBJ_SVH
`define FIFO_SBTX_ENV_CFG_OBJ_SVH

class fifo_sbtx_env_cfg_obj extends uvm_object;
  `uvm_object_utils(fifo_sbtx_env_cfg_obj);

  virtual fifo_sbtx_if#(FIFO_WIDTH, FIFO_DEPTH) fifo_sbtx_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit fifo_sbtx_has_scoreboard;
  bit fifo_sbtx_has_subscriber;
  bit fifo_sbtx_has_agent;
  bit fifo_sbtx_has_monitor;

  function new(string name = "fifo_sbtx_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // FIFO_SBTX_ENV_CFG_OBJ_SVH
