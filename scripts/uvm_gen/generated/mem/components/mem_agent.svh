`ifndef MEM_AGENT_SVH
`define MEM_AGENT_SVH

class mem_agent extends uvm_agent;
  `uvm_component_utils(mem_agent)

  mem_sequencer seqr;
  mem_driver drv;
  mem_monitor mon;

  mem_agt_cfg_obj cfg;
  mem_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(mem_sequence_item) agt_aport;

  function new(string name = "mem_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(mem_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("MEM_AGENT", "mem_cfg_obj not found in config_db for mem_agent")

    drv_mon_cfg = mem_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.mem_vif = cfg.mem_vif;

    uvm_config_db#(mem_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = mem_sequencer::type_id::create("seqr", this);
      drv = mem_driver::type_id::create("drv", this);
    end

    mon = mem_monitor::type_id::create("mon", this);
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

`endif // MEM_AGENT_SVH
