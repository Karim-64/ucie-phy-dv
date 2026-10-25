`ifndef DESERIALIZER_SBRX_ENV_CFG_OBJ_SVH
`define DESERIALIZER_SBRX_ENV_CFG_OBJ_SVH

class Deserializer_SBRX_env_cfg_obj extends uvm_object;
  `uvm_object_utils(Deserializer_SBRX_env_cfg_obj);

  virtual Deserializer_SBRX_if#(DATA_WIDTH) Deserializer_SBRX_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit Deserializer_SBRX_has_scoreboard;
  bit Deserializer_SBRX_has_subscriber;
  bit Deserializer_SBRX_has_agent;
  bit Deserializer_SBRX_has_monitor;

  function new(string name = "Deserializer_SBRX_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // DESERIALIZER_SBRX_ENV_CFG_OBJ_SVH
