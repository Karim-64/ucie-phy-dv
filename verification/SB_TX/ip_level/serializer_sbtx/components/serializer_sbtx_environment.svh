`ifndef SERIALIZER_SBTX_ENVIRONMENT_SVH
`define SERIALIZER_SBTX_ENVIRONMENT_SVH

class serializer_sbtx_environment extends uvm_env;
  `uvm_component_utils(serializer_sbtx_environment)

  serializer_sbtx_agent agt;
  serializer_sbtx_scoreboard sb;
  serializer_sbtx_subscriber sub;

  serializer_sbtx_env_cfg_obj cfg;
  serializer_sbtx_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(serializer_sbtx_sequence_item) serializer_sbtx_env_aport;

  function new(string name = "serializer_sbtx_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    serializer_sbtx_env_aport = new("serializer_sbtx_env_aport", this);

    if (!uvm_config_db#(serializer_sbtx_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("SERIALIZER_SBTX_ENV", "serializer_sbtx_env_cfg_obj not found in config_db for serializer_sbtx_environment")

    if (cfg.serializer_sbtx_has_agent) begin
      agt_cfg = serializer_sbtx_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.serializer_sbtx_vif = cfg.serializer_sbtx_vif;
      agt_cfg.is_active = cfg.active_passive_agents["serializer_sbtx"];

      uvm_config_db#(serializer_sbtx_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.serializer_sbtx_has_agent)
      agt = serializer_sbtx_agent::type_id::create("agt", this);

    if (cfg.serializer_sbtx_has_scoreboard)
      sb = serializer_sbtx_scoreboard::type_id::create("sb", this);

    if (cfg.serializer_sbtx_has_subscriber)
      sub = serializer_sbtx_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.serializer_sbtx_has_agent) begin
      if (cfg.serializer_sbtx_has_scoreboard)
        agt.agt_aport.connect(sb.sb_fifo.analysis_export);

      if (cfg.serializer_sbtx_has_subscriber)
        agt.agt_aport.connect(sub.sub_fifo.analysis_export);

      agt.agt_aport.connect(serializer_sbtx_env_aport);
    end
  endfunction
endclass

`endif // SERIALIZER_SBTX_ENVIRONMENT_SVH
