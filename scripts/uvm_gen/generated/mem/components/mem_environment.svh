`ifndef MEM_ENVIRONMENT_SVH
`define MEM_ENVIRONMENT_SVH

class mem_environment extends uvm_env;
  `uvm_component_utils(mem_environment)

  mem_agent agt;
  mem_scoreboard sb;
  mem_subscriber sub;

  mem_env_cfg_obj cfg;
  mem_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(mem_sequence_item) mem_env_aport;

  function new(string name = "mem_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    mem_env_aport = new("mem_env_aport", this);

    if (!uvm_config_db#(mem_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("MEM_ENV", "mem_env_cfg_obj not found in config_db for mem_environment")

    if (cfg.mem_has_agent) begin
      agt_cfg = mem_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.mem_vif = cfg.mem_vif;
      agt_cfg.is_active = cfg.active_passive_agents["mem"];

      uvm_config_db#(mem_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.mem_has_agent)
      agt = mem_agent::type_id::create("agt", this);

    if (cfg.mem_has_scoreboard)
      sb = mem_scoreboard::type_id::create("sb", this);

    if (cfg.mem_has_subscriber)
      sub = mem_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.mem_has_agent) begin
      if (cfg.mem_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aimp);

      if (cfg.mem_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(mem_env_aport);
    end
  endfunction
endclass

`endif // MEM_ENVIRONMENT_SVH
