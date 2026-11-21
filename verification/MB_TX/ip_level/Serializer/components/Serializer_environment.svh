`ifndef SERIALIZER_ENVIRONMENT_SVH
`define SERIALIZER_ENVIRONMENT_SVH

class Serializer_environment extends uvm_env;
  `uvm_component_utils(Serializer_environment)

  Serializer_agent agt;
  Serializer_scoreboard sb;
  Serializer_subscriber sub;

  Serializer_env_cfg_obj cfg;
  Serializer_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(Serializer_sequence_item) Serializer_env_aport;

  function new(string name = "Serializer_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    Serializer_env_aport = new("Serializer_env_aport", this);

    if (!uvm_config_db#(Serializer_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("SERIALIZER_ENV", "Serializer_env_cfg_obj not found in config_db for Serializer_environment")

    if (cfg.Serializer_has_agent) begin
      agt_cfg = Serializer_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.Serializer_vif = cfg.Serializer_vif;
      agt_cfg.is_active = cfg.active_passive_agents["Serializer"];

      uvm_config_db#(Serializer_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.Serializer_has_agent)
      agt = Serializer_agent::type_id::create("agt", this);

    if (cfg.Serializer_has_scoreboard)
      sb = Serializer_scoreboard::type_id::create("sb", this);

    if (cfg.Serializer_has_subscriber)
      sub = Serializer_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.Serializer_has_agent) begin
      if (cfg.Serializer_has_scoreboard)
        agt.agt_aport.connect(sb.serializer_analysis_export);

      if (cfg.Serializer_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(Serializer_env_aport);
    end
  endfunction
endclass

`endif // SERIALIZER_ENVIRONMENT_SVH
