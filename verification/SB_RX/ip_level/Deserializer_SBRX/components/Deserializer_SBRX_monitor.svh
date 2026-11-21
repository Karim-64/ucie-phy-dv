`ifndef DESERIALIZER_SBRX_MONITOR_SVH
`define DESERIALIZER_SBRX_MONITOR_SVH

class Deserializer_SBRX_monitor extends uvm_monitor;
  `uvm_component_utils(Deserializer_SBRX_monitor)

  Deserializer_SBRX_sequence_item seq_item;
  Deserializer_SBRX_sequence_item seqr_item;
  Deserializer_SBRX_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(Deserializer_SBRX_sequence_item, Deserializer_SBRX_monitor) mon_aimp;
  uvm_analysis_port#(Deserializer_SBRX_sequence_item) mon_aport;

  function new(string name = "Deserializer_SBRX_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(Deserializer_SBRX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DESERIALIZER_SBRX_MON", "Deserializer_SBRX_cfg_obj not found in config_db for Deserializer_SBRX_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(Deserializer_SBRX_sequence_item t);
    seqr_item = Deserializer_SBRX_sequence_item::type_id::create("seqr_item");
    seqr_item.sb_sys_rst = t.sb_sys_rst;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = Deserializer_SBRX_sequence_item::type_id::create("seq_item");
      @(cfg.Deserializer_SBRX_vif.mon_cb);
      if (seqr_item) begin
        seq_item.sb_sys_rst <= seqr_item.sb_sys_rst;
      end
      seq_item.deser_data_out <= cfg.Deserializer_SBRX_vif.mon_cb.deser_data_out;
      seq_item.data_valid <= cfg.Deserializer_SBRX_vif.mon_cb.data_valid;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // DESERIALIZER_SBRX_MONITOR_SVH
