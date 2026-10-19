`ifndef MUX_SBTX_ENV_CFG_OBJ_SVH
`define MUX_SBTX_ENV_CFG_OBJ_SVH

class mux_sbtx_env_cfg_obj extends uvm_object;
  `uvm_object_utils(mux_sbtx_env_cfg_obj);

  virtual mux_sbtx_if#(INPUT_WIDTH) mux_sbtx_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit mux_sbtx_has_scoreboard;
  bit mux_sbtx_has_subscriber;
  bit mux_sbtx_has_agent;
  bit mux_sbtx_has_monitor;

  function new(string name = "mux_sbtx_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // MUX_SBTX_ENV_CFG_OBJ_SVH
