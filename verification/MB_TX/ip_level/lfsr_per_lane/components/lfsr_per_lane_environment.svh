`ifndef LFSR_PER_LANE_ENVIRONMENT_SVH
`define LFSR_PER_LANE_ENVIRONMENT_SVH

class lfsr_per_lane_environment extends uvm_env;
  `uvm_component_utils(lfsr_per_lane_environment)

  lfsr_per_lane_agent agt;
  lfsr_per_lane_scoreboard sb;
  lfsr_per_lane_subscriber sub;

  lfsr_per_lane_env_cfg_obj cfg;
  lfsr_per_lane_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(lfsr_per_lane_sequence_item) lfsr_per_lane_env_aport;

  function new(string name = "lfsr_per_lane_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    lfsr_per_lane_env_aport = new("lfsr_per_lane_env_aport", this);

    if (!uvm_config_db#(lfsr_per_lane_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("LFSR_PER_LANE_ENV", "lfsr_per_lane_env_cfg_obj not found in config_db for lfsr_per_lane_environment")

    if (cfg.lfsr_per_lane_has_agent) begin
      agt_cfg = lfsr_per_lane_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.lfsr_per_lane_vif = cfg.lfsr_per_lane_vif;
      agt_cfg.is_active = cfg.active_passive_agents["lfsr_per_lane"];

      uvm_config_db#(lfsr_per_lane_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.lfsr_per_lane_has_agent)
      agt = lfsr_per_lane_agent::type_id::create("agt", this);

    if (cfg.lfsr_per_lane_has_scoreboard)
      sb = lfsr_per_lane_scoreboard::type_id::create("sb", this);

    if (cfg.lfsr_per_lane_has_subscriber)
      sub = lfsr_per_lane_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.lfsr_per_lane_has_agent) begin
      if (cfg.lfsr_per_lane_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aimp);

      if (cfg.lfsr_per_lane_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(lfsr_per_lane_env_aport);
    end
  endfunction
endclass

`endif // LFSR_PER_LANE_ENVIRONMENT_SVH
