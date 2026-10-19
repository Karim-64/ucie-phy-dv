`ifndef SYNCHRONIZER_AGENT_SVH
`define SYNCHRONIZER_AGENT_SVH

class Synchronizer_agent extends uvm_agent;
  `uvm_component_utils(Synchronizer_agent)

  Synchronizer_sequencer seqr;
  Synchronizer_driver drv;
  Synchronizer_monitor mon;

  Synchronizer_agt_cfg_obj cfg;
  Synchronizer_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(Synchronizer_sequence_item) agt_aport;

  function new(string name = "Synchronizer_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(Synchronizer_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("SYNCHRONIZER_AGENT", "Synchronizer_cfg_obj not found in config_db for Synchronizer_agent")

    drv_mon_cfg = Synchronizer_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.Synchronizer_vif = cfg.Synchronizer_vif;

    uvm_config_db#(Synchronizer_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = Synchronizer_sequencer::type_id::create("seqr", this);
      drv = Synchronizer_driver::type_id::create("drv", this);
    end

    mon = Synchronizer_monitor::type_id::create("mon", this);
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

`endif // SYNCHRONIZER_AGENT_SVH
