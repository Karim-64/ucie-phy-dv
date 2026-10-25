`ifndef FIFO_RD_MBRX_AGENT_SVH
`define FIFO_RD_MBRX_AGENT_SVH

class fifo_rd_mbrx_agent extends uvm_agent;
  `uvm_component_utils(fifo_rd_mbrx_agent)

  fifo_rd_mbrx_sequencer seqr;
  fifo_rd_mbrx_driver drv;
  fifo_rd_mbrx_monitor mon;

  fifo_rd_mbrx_agt_cfg_obj cfg;
  fifo_rd_mbrx_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(fifo_rd_mbrx_sequence_item) agt_aport;

  function new(string name = "fifo_rd_mbrx_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(fifo_rd_mbrx_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("FIFO_RD_MBRX_AGENT", "fifo_rd_mbrx_cfg_obj not found in config_db for fifo_rd_mbrx_agent")

    drv_mon_cfg = fifo_rd_mbrx_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.fifo_rd_mbrx_vif = cfg.fifo_rd_mbrx_vif;

    uvm_config_db#(fifo_rd_mbrx_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = fifo_rd_mbrx_sequencer::type_id::create("seqr", this);
      drv = fifo_rd_mbrx_driver::type_id::create("drv", this);
    end

    mon = fifo_rd_mbrx_monitor::type_id::create("mon", this);
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

`endif // FIFO_RD_MBRX_AGENT_SVH
