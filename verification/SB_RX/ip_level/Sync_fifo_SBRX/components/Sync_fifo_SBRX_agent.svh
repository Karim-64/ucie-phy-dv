`ifndef SYNC_FIFO_SBRX_AGENT_SVH
`define SYNC_FIFO_SBRX_AGENT_SVH

class Sync_fifo_SBRX_agent extends uvm_agent;
  `uvm_component_utils(Sync_fifo_SBRX_agent)

  Sync_fifo_SBRX_sequencer seqr;
  Sync_fifo_SBRX_driver drv;
  Sync_fifo_SBRX_monitor mon;

  Sync_fifo_SBRX_agt_cfg_obj cfg;
  Sync_fifo_SBRX_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(Sync_fifo_SBRX_sequence_item) agt_aport;

  function new(string name = "Sync_fifo_SBRX_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(Sync_fifo_SBRX_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("SYNC_FIFO_SBRX_AGENT", "Sync_fifo_SBRX_cfg_obj not found in config_db for Sync_fifo_SBRX_agent")

    drv_mon_cfg = Sync_fifo_SBRX_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.Sync_fifo_SBRX_vif = cfg.Sync_fifo_SBRX_vif;

    uvm_config_db#(Sync_fifo_SBRX_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = Sync_fifo_SBRX_sequencer::type_id::create("seqr", this);
      drv = Sync_fifo_SBRX_driver::type_id::create("drv", this);
    end

    mon = Sync_fifo_SBRX_monitor::type_id::create("mon", this);
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

`endif // SYNC_FIFO_SBRX_AGENT_SVH
