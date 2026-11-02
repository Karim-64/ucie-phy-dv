`ifndef SERIALIZER_MONITOR_SVH
`define SERIALIZER_MONITOR_SVH

class Serializer_monitor extends uvm_monitor;
  `uvm_component_utils(Serializer_monitor)

  Serializer_sequence_item seq_item;
  Serializer_sequence_item seqr_item;
  Serializer_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(Serializer_sequence_item, Serializer_monitor) mon_aimp;
  uvm_analysis_port#(Serializer_sequence_item) mon_aport;

  function new(string name = "Serializer_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(Serializer_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("SERIALIZER_MON", "Serializer_cfg_obj not found in config_db for Serializer_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(Serializer_sequence_item t);
    seqr_item = Serializer_sequence_item::type_id::create("seqr_item");
    seqr_item.SER_EN = t.SER_EN;
    seqr_item.DATA = t.DATA;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = Serializer_sequence_item::type_id::create("seq_item");
      @(cfg.Serializer_vif.mon_cb);
      if (seqr_item) begin
        seq_item.SER_EN <= seqr_item.SER_EN;
        seq_item.DATA <= seqr_item.DATA;
      end
      seq_item.SER_OUT <= cfg.Serializer_vif.mon_cb.SER_OUT;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // SERIALIZER_MONITOR_SVH
