`ifndef DESERIALIZER_SBRX_ENVIRONMENT_SVH
`define DESERIALIZER_SBRX_ENVIRONMENT_SVH

class Deserializer_SBRX_environment extends uvm_env;
  `uvm_component_utils(Deserializer_SBRX_environment)

  Deserializer_SBRX_agent agt;
  Deserializer_SBRX_agent2 agt2;
  Deserializer_SBRX_scoreboard sb;
  Deserializer_SBRX_subscriber sub;

  Deserializer_SBRX_env_cfg_obj cfg;
  Deserializer_SBRX_agt_cfg_obj agt_cfg;
  Deserializer_SBRX_agt_cfg_obj agt2_cfg;
  Deserializer_SBRX_Virtual_sequencer virt_seqr;

  uvm_analysis_port#(Deserializer_SBRX_sequence_item) Deserializer_SBRX_env_aport;

  function new(string name = "Deserializer_SBRX_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    Deserializer_SBRX_env_aport = new("Deserializer_SBRX_env_aport", this);

    if (!uvm_config_db#(Deserializer_SBRX_env_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DESERIALIZER_SBRX_ENV", "Deserializer_SBRX_env_cfg_obj not found in config_db for Deserializer_SBRX_environment")

    if (cfg.Deserializer_SBRX_has_agent) begin
      agt_cfg = Deserializer_SBRX_agt_cfg_obj::type_id::create("agt_cfg");
      agt2_cfg = Deserializer_SBRX_agt_cfg_obj::type_id::create("agt2_cfg");
      agt_cfg.Deserializer_SBRX_vif = cfg.Deserializer_SBRX_vif;
      agt2_cfg.Deserializer_SBRX_vif = cfg.Deserializer_SBRX_vif;
      agt_cfg.is_active = cfg.active_passive_agents["Deserializer_SBRX"];
      agt2_cfg.is_active = cfg.active_passive_agents["Deserializer_SBRX"];

      uvm_config_db#(Deserializer_SBRX_agt_cfg_obj)::set(this, "agt", "cfg", agt_cfg);
      uvm_config_db#(Deserializer_SBRX_agt_cfg_obj)::set(this, "agt2", "cfg2", agt2_cfg);
    end

    if (cfg.Deserializer_SBRX_has_agent) begin
      agt = Deserializer_SBRX_agent::type_id::create("agt", this);
      agt2 = Deserializer_SBRX_agent2::type_id::create("agt2", this);
    end

    if (cfg.Deserializer_SBRX_has_scoreboard)
      sb = Deserializer_SBRX_scoreboard::type_id::create("sb", this);

    if (cfg.Deserializer_SBRX_has_subscriber)
      sub = Deserializer_SBRX_subscriber::type_id::create("sub", this);

    virt_seqr = Deserializer_SBRX_Virtual_sequencer::type_id::create("virt_seqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (cfg.Deserializer_SBRX_has_agent) begin
      if (cfg.Deserializer_SBRX_has_scoreboard) begin
        agt.agt_aport.connect(sb.exp);
        agt2.agt_aport.connect(sb.exp2);
      end

      if (cfg.Deserializer_SBRX_has_subscriber) begin
        agt.agt_aport.connect(sub.exp);
        agt2.agt_aport.connect(sub.exp2);
      end

      agt.agt_aport.connect(Deserializer_SBRX_env_aport);

      virt_seqr.seqr = agt.seqr;
      virt_seqr.seqr2 = agt2.seqr;
    end
  endfunction
endclass

`endif // DESERIALIZER_SBRX_ENVIRONMENT_SVH
