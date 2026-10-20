`ifndef DATA_MUX_ENVIRONMENT_SVH
`define DATA_MUX_ENVIRONMENT_SVH

class Data_MUX_environment extends uvm_env;
  `uvm_component_utils(Data_MUX_environment)

  Data_MUX_agent agt;
  Data_MUX_scoreboard sb;
  Data_MUX_subscriber sub;

  Data_MUX_env_cfg_obj cfg;
  Data_MUX_agt_cfg_obj agt_cfg;

  uvm_analysis_port#(Data_MUX_sequence_item) Data_MUX_env_aport;

  function new(string name = "Data_MUX_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    Data_MUX_env_aport = new("Data_MUX_env_aport", this);

    if (!uvm_config_db#(Data_MUX_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DATA_MUX_ENV", "Data_MUX_env_cfg_obj not found in config_db for Data_MUX_environment")

    if (cfg.Data_MUX_has_agent) begin
      agt_cfg = Data_MUX_agt_cfg_obj::type_id::create("agt_cfg");
      agt_cfg.Data_MUX_vif = cfg.Data_MUX_vif;
      agt_cfg.is_active = cfg.active_passive_agents["Data_MUX"];

      uvm_config_db#(Data_MUX_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
    end

    if (cfg.Data_MUX_has_agent)
      agt = Data_MUX_agent::type_id::create("agt", this);

    if (cfg.Data_MUX_has_scoreboard)
      sb = Data_MUX_scoreboard::type_id::create("sb", this);

    if (cfg.Data_MUX_has_subscriber)
      sub = Data_MUX_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.Data_MUX_has_agent) begin
      if (cfg.Data_MUX_has_scoreboard)
        agt.agt_aport.connect(sb.sb_aexp);

      if (cfg.Data_MUX_has_subscriber)
        agt.agt_aport.connect(sub.analysis_export);

      agt.agt_aport.connect(Data_MUX_env_aport);
    end
  endfunction
endclass

`endif // DATA_MUX_ENVIRONMENT_SVH
