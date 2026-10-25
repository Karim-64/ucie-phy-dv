`ifndef PAT_GEN_SBTX_AGENT_SVH
`define PAT_GEN_SBTX_AGENT_SVH

class pat_gen_sbtx_agent extends uvm_agent;
  `uvm_component_utils(pat_gen_sbtx_agent)

  pat_gen_sbtx_sequencer seqr;
  pat_gen_sbtx_driver drv;
  pat_gen_sbtx_monitor mon;

  pat_gen_sbtx_agt_cfg_obj cfg;
  pat_gen_sbtx_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(pat_gen_sbtx_sequence_item) agt_aport;

  function new(string name = "pat_gen_sbtx_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(pat_gen_sbtx_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("PAT_GEN_SBTX_AGENT", "pat_gen_sbtx_cfg_obj not found in config_db for pat_gen_sbtx_agent")

    drv_mon_cfg = pat_gen_sbtx_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.pat_gen_sbtx_vif = cfg.pat_gen_sbtx_vif;

    uvm_config_db#(pat_gen_sbtx_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = pat_gen_sbtx_sequencer::type_id::create("seqr", this);
      drv = pat_gen_sbtx_driver::type_id::create("drv", this);
    end

    mon = pat_gen_sbtx_monitor::type_id::create("mon", this);
    agt_aport = new("agt_aport", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.is_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
      seqr.seqr_aport.connect(mon.mon_aimp);
    end
    mon.mon_aport.connect(agt_aport);
  endfunction
endclass

`endif // PAT_GEN_SBTX_AGENT_SVH
