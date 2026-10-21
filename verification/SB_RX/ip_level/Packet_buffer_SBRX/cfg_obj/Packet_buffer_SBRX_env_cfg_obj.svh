`ifndef PACKET_BUFFER_SBRX_ENV_CFG_OBJ_SVH
`define PACKET_BUFFER_SBRX_ENV_CFG_OBJ_SVH

class Packet_buffer_SBRX_env_cfg_obj extends uvm_object;
  `uvm_object_utils(Packet_buffer_SBRX_env_cfg_obj);

  virtual Packet_buffer_SBRX_if#(DATA_WIDTH, DEPTH) Packet_buffer_SBRX_vif;
  uvm_active_passive_enum active_passive_agents [string];
  bit Packet_buffer_SBRX_has_scoreboard;
  bit Packet_buffer_SBRX_has_subscriber;
  bit Packet_buffer_SBRX_has_agent;
  bit Packet_buffer_SBRX_has_monitor;

  function new(string name = "Packet_buffer_SBRX_env_cfg_obj");
    super.new(name);
  endfunction
endclass

`endif // PACKET_BUFFER_SBRX_ENV_CFG_OBJ_SVH
