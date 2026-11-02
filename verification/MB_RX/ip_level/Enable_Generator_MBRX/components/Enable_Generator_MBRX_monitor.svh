`ifndef ENABLE_GENERATOR_MBRX_MONITOR_SVH
`define ENABLE_GENERATOR_MBRX_MONITOR_SVH

class Enable_Generator_MBRX_monitor extends uvm_monitor;
  `uvm_component_utils(Enable_Generator_MBRX_monitor)


  Enable_Generator_MBRX_sequence_item seq_item;
  Enable_Generator_MBRX_sequence_item seqr_item;
  Enable_Generator_MBRX_drv_mon_cfg_obj cfg;
  uvm_analysis_imp#(Enable_Generator_MBRX_sequence_item, Enable_Generator_MBRX_monitor) mon_aimp;
  uvm_analysis_port#(Enable_Generator_MBRX_sequence_item) mon_aport;

  function new(string name = "Enable_Generator_MBRX_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if (!uvm_config_db#(Enable_Generator_MBRX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("ENABLE_GENERATOR_MBRX_MON", "Enable_Generator_MBRX_cfg_obj not found in config_db for Enable_Generator_MBRX_monitor")
    mon_aport = new("mon_aport", this);
    mon_aimp = new("mon_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

    function void write(Enable_Generator_MBRX_sequence_item t);
    seqr_item = Enable_Generator_MBRX_sequence_item::type_id::create("seqr_item");
    seqr_item.RST_n = t.RST_n;
    seqr_item.LTSM_State = t.LTSM_State;
    seqr_item.Width_Degrade = t.Width_Degrade;
    seqr_item.Valid = t.Valid;
    seqr_item.Comparison_Done = t.Comparison_Done;
    seqr_item.Valid_Frame_Error = t.Valid_Frame_Error;
    seqr_item.Detec_succ = t.Detec_succ;
    seqr_item.Test_Resp = t.Test_Resp;
  endfunction


  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      
      @(cfg.Enable_Generator_MBRX_vif.mon_cb);
      seq_item = Enable_Generator_MBRX_sequence_item::type_id::create("seq_item");
        if (seqr_item) begin
          seq_item.RST_n            <= seqr_item.RST_n;
          seq_item.LTSM_State       <= seqr_item.LTSM_State;
          seq_item.Width_Degrade    <= seqr_item.Width_Degrade;
          seq_item.Valid            <= seqr_item.Valid;
          seq_item.Comparison_Done  <= seqr_item.Comparison_Done;
          seq_item.Valid_Frame_Error<= seqr_item.Valid_Frame_Error;
          seq_item.Detec_succ       <= seqr_item.Detec_succ;
          seq_item.Test_Resp        <= seqr_item.Test_Resp;
        end
          seq_item.Vchk_EN            <= cfg.Enable_Generator_MBRX_vif.mon_cb.Vchk_EN;
          seq_item.Descr_EN           <= cfg.Enable_Generator_MBRX_vif.mon_cb.Descr_EN;
          seq_item.Deserializer_EN1   <= cfg.Enable_Generator_MBRX_vif.mon_cb.Deserializer_EN1;
          seq_item.Deserializer_EN2   <= cfg.Enable_Generator_MBRX_vif.mon_cb.Deserializer_EN2;
          seq_item.Data_Comparator_EN <= cfg.Enable_Generator_MBRX_vif.mon_cb.Data_Comparator_EN;
          seq_item.Valid_Detected     <= cfg.Enable_Generator_MBRX_vif.mon_cb.Valid_Detected;
          seq_item.Comparison_Type    <= cfg.Enable_Generator_MBRX_vif.mon_cb.Comparison_Type;
          seq_item.LFSR_SEL           <= cfg.Enable_Generator_MBRX_vif.mon_cb.LFSR_SEL;
          #1step mon_aport.write(seq_item);
    end
  endtask
endclass

`endif // ENABLE_GENERATOR_MBRX_MONITOR_SVH
