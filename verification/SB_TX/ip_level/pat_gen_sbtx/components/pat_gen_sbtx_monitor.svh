`ifndef PAT_GEN_SBTX_MONITOR_SVH
`define PAT_GEN_SBTX_MONITOR_SVH

class pat_gen_sbtx_monitor extends uvm_monitor;
  `uvm_component_utils(pat_gen_sbtx_monitor)

  pat_gen_sbtx_sequence_item seq_item;
  pat_gen_sbtx_sequence_item seqr_item;
  pat_gen_sbtx_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(pat_gen_sbtx_sequence_item, pat_gen_sbtx_monitor) mon_aimp;
  uvm_analysis_port#(pat_gen_sbtx_sequence_item) mon_aport;

  function new(string name = "pat_gen_sbtx_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pat_gen_sbtx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("PAT_GEN_SBTX_MON", "pat_gen_sbtx_cfg_obj not found in config_db for pat_gen_sbtx_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void write(pat_gen_sbtx_sequence_item t);
    seqr_item = pat_gen_sbtx_sequence_item::type_id::create("seqr_item");
    seqr_item.RST_n = t.RST_n;
    seqr_item.Patt_Gen_En = t.Patt_Gen_En;
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item = pat_gen_sbtx_sequence_item::type_id::create("seq_item");
      @(cfg.pat_gen_sbtx_vif.mon_cb);
      if (seqr_item) begin
        seq_item.RST_n <= seqr_item.RST_n;
        seq_item.Patt_Gen_En <= seqr_item.Patt_Gen_En;
      end
      seq_item.start_64 <= cfg.pat_gen_sbtx_vif.mon_cb.start_64;
      seq_item.SBTX_DATA <= cfg.pat_gen_sbtx_vif.mon_cb.SBTX_DATA;
      #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // PAT_GEN_SBTX_MONITOR_SVH
