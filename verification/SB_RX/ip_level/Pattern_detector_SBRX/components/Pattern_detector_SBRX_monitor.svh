`ifndef PATTERN_DETECTOR_SBRX_MONITOR_SVH
`define PATTERN_DETECTOR_SBRX_MONITOR_SVH

class Pattern_detector_SBRX_monitor extends uvm_monitor;
  `uvm_component_utils(Pattern_detector_SBRX_monitor)

  Pattern_detector_SBRX_sequence_item seq_item;
  Pattern_detector_SBRX_sequence_item seqr_item;
  Pattern_detector_SBRX_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(Pattern_detector_SBRX_sequence_item, Pattern_detector_SBRX_monitor) mon_aimp;
  uvm_analysis_port#(Pattern_detector_SBRX_sequence_item) mon_aport;

  function new(string name = "Pattern_detector_SBRX_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(Pattern_detector_SBRX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("PATTERN_DETECTOR_SBRX_MON", "Pattern_detector_SBRX_cfg_obj not found in config_db for Pattern_detector_SBRX_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(Pattern_detector_SBRX_sequence_item t);
    seqr_item = Pattern_detector_SBRX_sequence_item::type_id::create("seqr_item");
    seqr_item.sb_sys_rst = t.sb_sys_rst;
    seqr_item.pattern_data_in = t.pattern_data_in;
    seqr_item.data_valid = t.data_valid;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = Pattern_detector_SBRX_sequence_item::type_id::create("seq_item");
      @(cfg.Pattern_detector_SBRX_vif.mon_cb);
      if (seqr_item) begin
        seq_item.sb_sys_rst <= seqr_item.sb_sys_rst;
        seq_item.pattern_data_in <= seqr_item.pattern_data_in;
        seq_item.data_valid <= seqr_item.data_valid;
      end
      seq_item.pattern_detected <= cfg.Pattern_detector_SBRX_vif.mon_cb.pattern_detected;
      seq_item.sb_o_detected <= cfg.Pattern_detector_SBRX_vif.mon_cb.sb_o_detected;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // PATTERN_DETECTOR_SBRX_MONITOR_SVH
