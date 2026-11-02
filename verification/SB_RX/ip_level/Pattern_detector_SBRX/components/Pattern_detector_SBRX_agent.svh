`ifndef PATTERN_DETECTOR_SBRX_AGENT_SVH
`define PATTERN_DETECTOR_SBRX_AGENT_SVH

class Pattern_detector_SBRX_agent extends uvm_agent;
  `uvm_component_utils(Pattern_detector_SBRX_agent)

  Pattern_detector_SBRX_sequencer seqr;
  Pattern_detector_SBRX_driver drv;
  Pattern_detector_SBRX_monitor mon;

  Pattern_detector_SBRX_agt_cfg_obj cfg;
  Pattern_detector_SBRX_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(Pattern_detector_SBRX_sequence_item) agt_aport;

  function new(string name = "Pattern_detector_SBRX_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(Pattern_detector_SBRX_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("PATTERN_DETECTOR_SBRX_AGENT", "Pattern_detector_SBRX_cfg_obj not found in config_db for Pattern_detector_SBRX_agent")

    drv_mon_cfg = Pattern_detector_SBRX_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.Pattern_detector_SBRX_vif = cfg.Pattern_detector_SBRX_vif;

    uvm_config_db#(Pattern_detector_SBRX_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = Pattern_detector_SBRX_sequencer::type_id::create("seqr", this);
      drv = Pattern_detector_SBRX_driver::type_id::create("drv", this);
    end

    mon = Pattern_detector_SBRX_monitor::type_id::create("mon", this);
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

`endif // PATTERN_DETECTOR_SBRX_AGENT_SVH
