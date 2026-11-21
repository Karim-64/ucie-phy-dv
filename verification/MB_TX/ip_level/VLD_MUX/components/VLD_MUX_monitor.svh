`ifndef VLD_MUX_MONITOR_SVH
`define VLD_MUX_MONITOR_SVH

class VLD_MUX_monitor extends uvm_monitor;
  `uvm_component_utils(VLD_MUX_monitor)

  VLD_MUX_sequence_item seq_item;
  VLD_MUX_sequence_item seqr_item;
  VLD_MUX_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(VLD_MUX_sequence_item, VLD_MUX_monitor) mon_aimp;
  uvm_analysis_port#(VLD_MUX_sequence_item) mon_aport;

  function new(string name = "VLD_MUX_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(VLD_MUX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("VLD_MUX_MON", "VLD_MUX_cfg_obj not found in config_db for VLD_MUX_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(VLD_MUX_sequence_item t);
    seqr_item = VLD_MUX_sequence_item::type_id::create("seqr_item");
    seqr_item.IN_0 = t.IN_0;
    seqr_item.IN_1 = t.IN_1;
    seqr_item.IN_2 = t.IN_2;
    seqr_item.IN_3 = t.IN_3;
    seqr_item.SEL_1 = t.SEL_1;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = VLD_MUX_sequence_item::type_id::create("seq_item");
      @(cfg.VLD_MUX_vif.mon_cb);
      if (seqr_item) begin
        seq_item.IN_0 <= seqr_item.IN_0;
        seq_item.IN_1 <= seqr_item.IN_1;
        seq_item.IN_2 <= seqr_item.IN_2;
        seq_item.IN_3 <= seqr_item.IN_3;
        seq_item.SEL_1 <= seqr_item.SEL_1;
      end
      seq_item.OUT <= cfg.VLD_MUX_vif.mon_cb.OUT;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // VLD_MUX_MONITOR_SVH
