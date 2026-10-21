`ifndef UP_DOWN_COUNTER_AGENT_SVH
`define UP_DOWN_COUNTER_AGENT_SVH

class up_down_counter_agent extends uvm_agent;
  `uvm_component_utils(up_down_counter_agent)

  up_down_counter_sequencer seqr;
  up_down_counter_driver drv;
  up_down_counter_monitor mon;

  up_down_counter_agt_cfg_obj cfg;
  up_down_counter_drv_mon_cfg_obj drv_mon_cfg;
  uvm_analysis_port#(up_down_counter_sequence_item) agt_aport;

  function new(string name = "up_down_counter_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(up_down_counter_agt_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("UP_DOWN_COUNTER_AGENT", "up_down_counter_cfg_obj not found in config_db for up_down_counter_agent")

    drv_mon_cfg = up_down_counter_drv_mon_cfg_obj::type_id::create("drv_mon_cfg");
    drv_mon_cfg.up_down_counter_vif = cfg.up_down_counter_vif;

    uvm_config_db#(up_down_counter_drv_mon_cfg_obj)::set(this, "*", "cfg", drv_mon_cfg);

    if (cfg.is_active == UVM_ACTIVE) begin
      seqr = up_down_counter_sequencer::type_id::create("seqr", this);
      drv = up_down_counter_driver::type_id::create("drv", this);
    end

    mon = up_down_counter_monitor::type_id::create("mon", this);
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

`endif // UP_DOWN_COUNTER_AGENT_SVH
