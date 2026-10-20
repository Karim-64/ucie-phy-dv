`ifndef DATA_MUX_MONITOR_SVH
`define DATA_MUX_MONITOR_SVH

class Data_MUX_monitor extends uvm_monitor;
  `uvm_component_utils(Data_MUX_monitor)

  Data_MUX_sequence_item seq_item;
  Data_MUX_sequence_item seqr_item;
  Data_MUX_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(Data_MUX_sequence_item, Data_MUX_monitor) mon_aimp;
  uvm_analysis_port#(Data_MUX_sequence_item) mon_aport;

  function new(string name = "Data_MUX_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(Data_MUX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DATA_MUX_MON", "Data_MUX_cfg_obj not found in config_db for Data_MUX_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(Data_MUX_sequence_item t);
    seqr_item = Data_MUX_sequence_item::type_id::create("seqr_item");
    seqr_item.IN_0 = t.IN_0;
    seqr_item.IN_1 = t.IN_1;
    seqr_item.SEL_5 = t.SEL_5;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = Data_MUX_sequence_item::type_id::create("seq_item");
      @(cfg.Data_MUX_vif.mon_cb);
      if (seqr_item) begin
        seq_item.IN_0 <= seqr_item.IN_0;
        seq_item.IN_1 <= seqr_item.IN_1;
        seq_item.SEL_5 <= seqr_item.SEL_5;
      end
      seq_item.OUT <= cfg.Data_MUX_vif.mon_cb.OUT;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // DATA_MUX_MONITOR_SVH
