`ifndef SERIALIZER_SBTX_MONITOR_SVH
`define SERIALIZER_SBTX_MONITOR_SVH

class serializer_sbtx_monitor extends uvm_monitor;
  `uvm_component_utils(serializer_sbtx_monitor)

  serializer_sbtx_sequence_item seq_item;
  serializer_sbtx_sequence_item seqr_item;
  serializer_sbtx_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(serializer_sbtx_sequence_item, serializer_sbtx_monitor) mon_aimp;
  uvm_analysis_port#(serializer_sbtx_sequence_item) mon_aport;

  function new(string name = "serializer_sbtx_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(serializer_sbtx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("SERIALIZER_SBTX_MON", "serializer_sbtx_cfg_obj not found in config_db for serializer_sbtx_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(serializer_sbtx_sequence_item t);
    seqr_item = serializer_sbtx_sequence_item::type_id::create("seqr_item");
    seqr_item.rst_n = t.rst_n;
    seqr_item.load = t.load;
    seqr_item.Enable = t.Enable;
    seqr_item.data_in = t.data_in;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = serializer_sbtx_sequence_item::type_id::create("seq_item");
      @(cfg.serializer_sbtx_vif.mon_cb);
      if (seqr_item) begin
        seq_item.rst_n <= seqr_item.rst_n;
        seq_item.load <= seqr_item.load;
        seq_item.Enable <= seqr_item.Enable;
        seq_item.data_in <= seqr_item.data_in;
      end
      seq_item.data_out <= cfg.serializer_sbtx_vif.mon_cb.data_out;
      seq_item.start_64 <= cfg.serializer_sbtx_vif.mon_cb.start_64;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // SERIALIZER_SBTX_MONITOR_SVH
