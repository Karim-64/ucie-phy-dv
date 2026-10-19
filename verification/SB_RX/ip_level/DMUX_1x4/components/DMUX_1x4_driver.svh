`ifndef DMUX_1X4_DRIVER_SVH
`define DMUX_1X4_DRIVER_SVH

// DMUX_1x4_driver.svh
// Driver for the DMUX_1x4 sub-environment.
// Drives stimulus on the DMUX_1x4 virtual interface using DMUX_1x4_sequence_item.

class DMUX_1x4_driver extends uvm_driver #(DMUX_1x4_sequence_item);
  `uvm_component_utils(DMUX_1x4_driver)

  DMUX_1x4_sequence_item seq_item;
  DMUX_1x4_drv_mon_cfg_obj cfg;

  function new(string name = "DMUX_1x4_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(DMUX_1x4_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DMUX_1X4_DRV", "DMUX_1x4_drv_mon_cfg_obj not found in config_db for DMUX_1x4_driver")
    seq_item = DMUX_1x4_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.DMUX_1x4_vif.drv_cb);
      cfg.DMUX_1x4_vif.drv_cb.din <= seq_item.din;
      cfg.DMUX_1x4_vif.drv_cb.sel <= seq_item.sel;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // DMUX_1X4_DRIVER_SVH
