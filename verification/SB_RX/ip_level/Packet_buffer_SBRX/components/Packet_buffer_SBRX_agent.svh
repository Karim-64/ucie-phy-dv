`ifndef PACKET_BUFFER_SBRX_AGENT_SVH
`define PACKET_BUFFER_SBRX_AGENT_SVH

class Packet_buffer_SBRX_agent extends uvm_agent;
  `uvm_component_utils(Packet_buffer_SBRX_agent)

  Packet_buffer_SBRX_sequencer seqr;
  Packet_buffer_SBRX_driver drv;
  Packet_buffer_SBRX_monitor mon;

  Packet_buffer_SBRX_agt_cfg_obj cfg;
  Packet_buffer_SBRX_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(Packet_buffer_SBRX_sequence_item) agt_aport;

  function new(string name = "Packet_buffer_SBRX_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(Packet_buffer_SBRX_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("PACKET_BUFFER_SBRX_AGENT", "Packet_buffer_SBRX_cfg_obj not found in config_db for Packet_buffer_SBRX_agent")

    drv_mon_cfg = Packet_buffer_SBRX_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.Packet_buffer_SBRX_vif = cfg.Packet_buffer_SBRX_vif;

    uvm_config_db#(Packet_buffer_SBRX_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = Packet_buffer_SBRX_sequencer::type_id::create("seqr", this);
      drv = Packet_buffer_SBRX_driver::type_id::create("drv", this);
    end

    mon = Packet_buffer_SBRX_monitor::type_id::create("mon", this);
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

`endif // PACKET_BUFFER_SBRX_AGENT_SVH
