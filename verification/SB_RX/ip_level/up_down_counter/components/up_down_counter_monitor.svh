`ifndef UP_DOWN_COUNTER_MONITOR_SVH
`define UP_DOWN_COUNTER_MONITOR_SVH

class up_down_counter_monitor extends uvm_monitor;
  `uvm_component_utils(up_down_counter_monitor)

  up_down_counter_sequence_item seq_item;
  up_down_counter_sequence_item seqr_item;
  up_down_counter_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(up_down_counter_sequence_item, up_down_counter_monitor) mon_aimp;
  uvm_analysis_port#(up_down_counter_sequence_item) mon_aport;

  function new(string name = "up_down_counter_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(up_down_counter_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("UP_DOWN_COUNTER_MON", "up_down_counter_cfg_obj not found in config_db for up_down_counter_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(up_down_counter_sequence_item t);
    seqr_item = up_down_counter_sequence_item::type_id::create("seqr_item");
    seqr_item.sys_rst      = t.sys_rst;
    seqr_item.up           = t.up;
    seqr_item.down         = t.down;
    seqr_item.scenario_mode = t.scenario_mode; // propagate test scenario for coverage
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = up_down_counter_sequence_item::type_id::create("seq_item");
        @(cfg.up_down_counter_vif.mon_cb);

      if (seqr_item) begin
        seq_item.sys_rst       <= seqr_item.sys_rst;
        seq_item.up            <= seqr_item.up;
        seq_item.down          <= seqr_item.down;
        seq_item.scenario_mode <= seqr_item.scenario_mode;
      end
      seq_item.count <= cfg.up_down_counter_vif.mon_cb.count;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // UP_DOWN_COUNTER_MONITOR_SVH
