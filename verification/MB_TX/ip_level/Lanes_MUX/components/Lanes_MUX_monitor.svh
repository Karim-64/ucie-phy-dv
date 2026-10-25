`ifndef LANES_MUX_MONITOR_SVH
`define LANES_MUX_MONITOR_SVH

class Lanes_MUX_monitor extends uvm_monitor;
  `uvm_component_utils(Lanes_MUX_monitor)

  Lanes_MUX_sequence_item seq_item;
  Lanes_MUX_sequence_item seqr_item;
  Lanes_MUX_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(Lanes_MUX_sequence_item, Lanes_MUX_monitor) mon_aimp;
  uvm_analysis_port#(Lanes_MUX_sequence_item) mon_aport;

  function new(string name = "Lanes_MUX_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(Lanes_MUX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("LANES_MUX_MON", "Lanes_MUX_cfg_obj not found in config_db for Lanes_MUX_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(Lanes_MUX_sequence_item t);
    seqr_item = Lanes_MUX_sequence_item::type_id::create("seqr_item");
    seqr_item.IN_0 = t.IN_0;
    seqr_item.IN_1 = t.IN_1;
    seqr_item.SEL_2 = t.SEL_2;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = Lanes_MUX_sequence_item::type_id::create("seq_item");
      @(cfg.Lanes_MUX_vif.mon_cb);
      if (seqr_item) begin
        seq_item.IN_0 <= seqr_item.IN_0;
        seq_item.IN_1 <= seqr_item.IN_1;
        seq_item.SEL_2 <= seqr_item.SEL_2;
      end
      seq_item.OUT <= cfg.Lanes_MUX_vif.mon_cb.OUT;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // LANES_MUX_MONITOR_SVH
