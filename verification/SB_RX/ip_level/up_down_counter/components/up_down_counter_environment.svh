`ifndef UP_DOWN_COUNTER_ENVIRONMENT_SVH
`define UP_DOWN_COUNTER_ENVIRONMENT_SVH

class up_down_counter_environment extends uvm_env;
  `uvm_component_utils(up_down_counter_environment)

  up_down_counter_agent agt;
  up_down_counter_scoreboard sb;
  up_down_counter_subscriber sub;

  up_down_counter_env_cfg_obj cfg;
  up_down_counter_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(up_down_counter_sequence_item) up_down_counter_env_aport;

  function new(string name = "up_down_counter_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    up_down_counter_env_aport = new("up_down_counter_env_aport", this);

    if (!uvm_config_db#(up_down_counter_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("UP_DOWN_COUNTER_ENV", "up_down_counter_env_cfg_obj not found in config_db for up_down_counter_environment")

    if (cfg.up_down_counter_has_agent) begin
      agt_cfg = up_down_counter_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.up_down_counter_vif = cfg.up_down_counter_vif;
      agt_cfg.is_active = cfg.active_passive_agents["up_down_counter"];

      uvm_config_db#(up_down_counter_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.up_down_counter_has_agent)
      agt = up_down_counter_agent::type_id::create("agt", this);

    if (cfg.up_down_counter_has_scoreboard)
      sb = up_down_counter_scoreboard::type_id::create("sb", this);

    if (cfg.up_down_counter_has_subscriber)
      sub = up_down_counter_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.up_down_counter_has_agent) begin
      if (cfg.up_down_counter_has_scoreboard)
        agt.agt_aport.connect(sb.exp);

      if (cfg.up_down_counter_has_subscriber)
        agt.agt_aport.connect(sub.exp);

      agt.agt_aport.connect(up_down_counter_env_aport);
    end
  endfunction
endclass

`endif // UP_DOWN_COUNTER_ENVIRONMENT_SVH
