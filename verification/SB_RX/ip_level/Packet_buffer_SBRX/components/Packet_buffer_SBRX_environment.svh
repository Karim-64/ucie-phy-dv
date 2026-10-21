`ifndef PACKET_BUFFER_SBRX_ENVIRONMENT_SVH
`define PACKET_BUFFER_SBRX_ENVIRONMENT_SVH

class Packet_buffer_SBRX_environment extends uvm_env;
  `uvm_component_utils(Packet_buffer_SBRX_environment)

  Packet_buffer_SBRX_agent agt;
  Packet_buffer_SBRX_scoreboard sb;
  Packet_buffer_SBRX_subscriber sub;

  Packet_buffer_SBRX_env_cfg_obj cfg;
  Packet_buffer_SBRX_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(Packet_buffer_SBRX_sequence_item) Packet_buffer_SBRX_env_aport;

  function new(string name = "Packet_buffer_SBRX_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    Packet_buffer_SBRX_env_aport = new("Packet_buffer_SBRX_env_aport", this);

    if (!uvm_config_db#(Packet_buffer_SBRX_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("PACKET_BUFFER_SBRX_ENV", "Packet_buffer_SBRX_env_cfg_obj not found in config_db for Packet_buffer_SBRX_environment")

    if (cfg.Packet_buffer_SBRX_has_agent) begin
      agt_cfg = Packet_buffer_SBRX_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.Packet_buffer_SBRX_vif = cfg.Packet_buffer_SBRX_vif;
      agt_cfg.is_active = cfg.active_passive_agents["Packet_buffer_SBRX"];

      uvm_config_db#(Packet_buffer_SBRX_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.Packet_buffer_SBRX_has_agent)
      agt = Packet_buffer_SBRX_agent::type_id::create("agt", this);

    if (cfg.Packet_buffer_SBRX_has_scoreboard)
      sb = Packet_buffer_SBRX_scoreboard::type_id::create("sb", this);

    if (cfg.Packet_buffer_SBRX_has_subscriber)
      sub = Packet_buffer_SBRX_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.Packet_buffer_SBRX_has_agent) begin
      if (cfg.Packet_buffer_SBRX_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aimp);

      if (cfg.Packet_buffer_SBRX_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(Packet_buffer_SBRX_env_aport);
    end
  endfunction
endclass

`endif // PACKET_BUFFER_SBRX_ENVIRONMENT_SVH
