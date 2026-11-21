`ifndef SERIALIZER_ENV_CFG_OBJ_SVH
`define SERIALIZER_ENV_CFG_OBJ_SVH

class Serializer_env_cfg_obj extends uvm_object;
  `uvm_object_utils(Serializer_env_cfg_obj);

  virtual Serializer_if#() Serializer_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit Serializer_has_scoreboard;
  bit Serializer_has_subscriber;
  bit Serializer_has_agent;
  bit Serializer_has_monitor;

  function new(string name = "Serializer_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // SERIALIZER_ENV_CFG_OBJ_SVH
