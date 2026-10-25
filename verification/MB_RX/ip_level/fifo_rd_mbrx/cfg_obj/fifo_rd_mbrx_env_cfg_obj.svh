`ifndef FIFO_RD_MBRX_ENV_CFG_OBJ_SVH
`define FIFO_RD_MBRX_ENV_CFG_OBJ_SVH

class fifo_rd_mbrx_env_cfg_obj extends uvm_object;
  `uvm_object_utils(fifo_rd_mbrx_env_cfg_obj);

  virtual fifo_rd_mbrx_if#(P_SIZE) fifo_rd_mbrx_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit fifo_rd_mbrx_has_scoreboard;
  bit fifo_rd_mbrx_has_subscriber;
  bit fifo_rd_mbrx_has_agent;
  bit fifo_rd_mbrx_has_monitor;

  function new(string name = "fifo_rd_mbrx_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // FIFO_RD_MBRX_ENV_CFG_OBJ_SVH
