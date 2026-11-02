`ifndef PATTERN_DETECTOR_SBRX_ENVIRONMENT_SVH
`define PATTERN_DETECTOR_SBRX_ENVIRONMENT_SVH

class Pattern_detector_SBRX_environment extends uvm_env;
  `uvm_component_utils(Pattern_detector_SBRX_environment)

  Pattern_detector_SBRX_agent agt;
  Pattern_detector_SBRX_scoreboard sb;
  Pattern_detector_SBRX_subscriber sub;

  Pattern_detector_SBRX_env_cfg_obj cfg;
  Pattern_detector_SBRX_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(Pattern_detector_SBRX_sequence_item) Pattern_detector_SBRX_env_aport;

  function new(string name = "Pattern_detector_SBRX_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    Pattern_detector_SBRX_env_aport = new("Pattern_detector_SBRX_env_aport", this);

    if (!uvm_config_db#(Pattern_detector_SBRX_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("PATTERN_DETECTOR_SBRX_ENV", "Pattern_detector_SBRX_env_cfg_obj not found in config_db for Pattern_detector_SBRX_environment")

    if (cfg.Pattern_detector_SBRX_has_agent) begin
      agt_cfg = Pattern_detector_SBRX_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.Pattern_detector_SBRX_vif = cfg.Pattern_detector_SBRX_vif;
      agt_cfg.is_active = cfg.active_passive_agents["Pattern_detector_SBRX"];

      uvm_config_db#(Pattern_detector_SBRX_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.Pattern_detector_SBRX_has_agent)
      agt = Pattern_detector_SBRX_agent::type_id::create("agt", this);

    if (cfg.Pattern_detector_SBRX_has_scoreboard)
      sb = Pattern_detector_SBRX_scoreboard::type_id::create("sb", this);

    if (cfg.Pattern_detector_SBRX_has_subscriber)
      sub = Pattern_detector_SBRX_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.Pattern_detector_SBRX_has_agent) begin
      if (cfg.Pattern_detector_SBRX_has_scoreboard)
        agt.agt_aport.connect(sb.exp);

      if (cfg.Pattern_detector_SBRX_has_subscriber)
        agt.agt_aport.connect(sub.exp);

      agt.agt_aport.connect(Pattern_detector_SBRX_env_aport);
    end
  endfunction
endclass

`endif // PATTERN_DETECTOR_SBRX_ENVIRONMENT_SVH
