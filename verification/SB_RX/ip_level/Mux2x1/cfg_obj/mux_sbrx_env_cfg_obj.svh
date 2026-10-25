`ifndef MUX_SBRX_ENV_CFG_OBJ_SVH
`define MUX_SBRX_ENV_CFG_OBJ_SVH

class mux_sbrx_env_cfg_obj extends uvm_object;
  `uvm_object_utils(mux_sbrx_env_cfg_obj);

  virtual mux_sbrx_if#(INPUT_WIDTH) mux_sbrx_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit mux_sbrx_has_scoreboard;
  bit mux_sbrx_has_subscriber;
  bit mux_sbrx_has_agent;
  bit mux_sbrx_has_monitor;

  function new(string name = "mux_sbrx_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // MUX_SBRX_ENV_CFG_OBJ_SVH
