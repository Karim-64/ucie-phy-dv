`ifndef SYNC_FIFO_SBRX_ENV_CFG_OBJ_SVH
`define SYNC_FIFO_SBRX_ENV_CFG_OBJ_SVH

class Sync_fifo_SBRX_env_cfg_obj extends uvm_object;
  `uvm_object_utils(Sync_fifo_SBRX_env_cfg_obj);

  virtual Sync_fifo_SBRX_if#(DATA_WIDTH, FIFO_DEPTH) Sync_fifo_SBRX_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit Sync_fifo_SBRX_has_scoreboard;
  bit Sync_fifo_SBRX_has_subscriber;
  bit Sync_fifo_SBRX_has_agent;
  bit Sync_fifo_SBRX_has_monitor;

  function new(string name = "Sync_fifo_SBRX_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // SYNC_FIFO_SBRX_ENV_CFG_OBJ_SVH
