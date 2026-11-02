`ifndef ENABLE_GENERATOR_MBRX_DRIVER_SVH
`define ENABLE_GENERATOR_MBRX_DRIVER_SVH

// Enable_Generator_MBRX_driver.svh
// Driver for the Enable_Generator_MBRX sub-environment.
// Drives stimulus on the Enable_Generator_MBRX virtual interface using Enable_Generator_MBRX_sequence_item.

class Enable_Generator_MBRX_driver extends uvm_driver #(Enable_Generator_MBRX_sequence_item);
  `uvm_component_utils(Enable_Generator_MBRX_driver)

  Enable_Generator_MBRX_sequence_item seq_item;
  Enable_Generator_MBRX_drv_mon_cfg_obj cfg;

  function new(string name = "Enable_Generator_MBRX_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(Enable_Generator_MBRX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("ENABLE_GENERATOR_MBRX_DRV", "Enable_Generator_MBRX_drv_mon_cfg_obj not found in config_db for Enable_Generator_MBRX_driver")
    seq_item = Enable_Generator_MBRX_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.Enable_Generator_MBRX_vif.drv_cb);
      cfg.Enable_Generator_MBRX_vif.drv_cb.RST_n            <= seq_item.RST_n;
      cfg.Enable_Generator_MBRX_vif.drv_cb.LTSM_State       <= seq_item.LTSM_State;
      cfg.Enable_Generator_MBRX_vif.drv_cb.Width_Degrade    <= seq_item.Width_Degrade;
      cfg.Enable_Generator_MBRX_vif.drv_cb.Valid            <= seq_item.Valid;
      cfg.Enable_Generator_MBRX_vif.drv_cb.Comparison_Done  <= seq_item.Comparison_Done;
      cfg.Enable_Generator_MBRX_vif.drv_cb.Valid_Frame_Error<= seq_item.Valid_Frame_Error;
      cfg.Enable_Generator_MBRX_vif.drv_cb.Detec_succ       <= seq_item.Detec_succ;
      cfg.Enable_Generator_MBRX_vif.drv_cb.Test_Resp        <= seq_item.Test_Resp;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // ENABLE_GENERATOR_MBRX_DRIVER_SVH
