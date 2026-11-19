`ifndef CREDITS_HANDLER_SBTX_DRIVER_SVH
`define CREDITS_HANDLER_SBTX_DRIVER_SVH

// Credits_Handler_SBTX_driver.svh
// Driver for the Credits_Handler_SBTX sub-environment.
// Drives stimulus on the Credits_Handler_SBTX virtual interface using Credits_Handler_SBTX_sequence_item.

class Credits_Handler_SBTX_driver extends uvm_driver #(Credits_Handler_SBTX_sequence_item);
  `uvm_component_utils(Credits_Handler_SBTX_driver)

  Credits_Handler_SBTX_sequence_item seq_item;
  Credits_Handler_SBTX_drv_mon_cfg_obj cfg;

  function new(string name = "Credits_Handler_SBTX_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(Credits_Handler_SBTX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("CREDITS_HANDLER_SBTX_DRV", "Credits_Handler_SBTX_drv_mon_cfg_obj not found in config_db for Credits_Handler_SBTX_driver")
    seq_item = Credits_Handler_SBTX_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.Credits_Handler_SBTX_vif.drv_cb);
      cfg.Credits_Handler_SBTX_vif.drv_cb.rst_n <= seq_item.rst_n;
      cfg.Credits_Handler_SBTX_vif.drv_cb.comp_sent <= seq_item.comp_sent;
      cfg.Credits_Handler_SBTX_vif.drv_cb.UIE <= seq_item.UIE;
      cfg.Credits_Handler_SBTX_vif.drv_cb.credit <= seq_item.credit;
      cfg.Credits_Handler_SBTX_vif.drv_cb.D2D_phy_marker <= seq_item.D2D_phy_marker;
      cfg.Credits_Handler_SBTX_vif.drv_cb.data_marker <= seq_item.data_marker;
      cfg.Credits_Handler_SBTX_vif.drv_cb.comp_marker <= seq_item.comp_marker;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // CREDITS_HANDLER_SBTX_DRIVER_SVH
