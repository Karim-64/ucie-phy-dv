`ifndef SERIALIZER_AGENT_SVH
`define SERIALIZER_AGENT_SVH

class Serializer_agent extends uvm_agent;
  `uvm_component_utils(Serializer_agent)

  Serializer_sequencer seqr;
  Serializer_driver drv;
  Serializer_monitor mon;

  Serializer_agt_cfg_obj cfg;
  Serializer_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(Serializer_sequence_item) agt_aport;

  function new(string name = "Serializer_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(Serializer_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("SERIALIZER_AGENT", "Serializer_cfg_obj not found in config_db for Serializer_agent")

    drv_mon_cfg = Serializer_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.Serializer_vif = cfg.Serializer_vif;

    uvm_config_db#(Serializer_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = Serializer_sequencer::type_id::create("seqr", this);
      drv = Serializer_driver::type_id::create("drv", this);
    end

    mon = Serializer_monitor::type_id::create("mon", this);
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

`endif // SERIALIZER_AGENT_SVH
