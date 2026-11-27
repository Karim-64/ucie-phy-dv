`ifndef LFSR_PER_LANE_AGENT_SVH
`define LFSR_PER_LANE_AGENT_SVH

class lfsr_per_lane_agent extends uvm_agent;
  `uvm_component_utils(lfsr_per_lane_agent)

  lfsr_per_lane_sequencer seqr;
  lfsr_per_lane_driver drv;
  lfsr_per_lane_monitor mon;

  lfsr_per_lane_agt_cfg_obj cfg;
  lfsr_per_lane_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(lfsr_per_lane_sequence_item) agt_aport;

  function new(string name = "lfsr_per_lane_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(lfsr_per_lane_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("LFSR_PER_LANE_AGENT", "lfsr_per_lane_cfg_obj not found in config_db for lfsr_per_lane_agent")

    drv_mon_cfg = lfsr_per_lane_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.lfsr_per_lane_vif = cfg.lfsr_per_lane_vif;

    uvm_config_db#(lfsr_per_lane_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = lfsr_per_lane_sequencer::type_id::create("seqr", this);
      drv = lfsr_per_lane_driver::type_id::create("drv", this);
    end

    mon = lfsr_per_lane_monitor::type_id::create("mon", this);
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

`endif // LFSR_PER_LANE_AGENT_SVH
