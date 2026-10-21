`ifndef DEMUX_SBTX_DRIVER_SVH
`define DEMUX_SBTX_DRIVER_SVH

// demux_SBTX_driver.svh
// Driver for the demux_SBTX sub-environment.
// Drives stimulus on the demux_SBTX virtual interface using demux_SBTX_sequence_item.

class demux_SBTX_driver extends uvm_driver #(demux_SBTX_sequence_item);
  `uvm_component_utils(demux_SBTX_driver)

  demux_SBTX_sequence_item seq_item;
  demux_SBTX_drv_mon_cfg_obj cfg;

  function new(string name = "demux_SBTX_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(demux_SBTX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DEMUX_SBTX_DRV", "demux_SBTX_drv_mon_cfg_obj not found in config_db for demux_SBTX_driver")
    seq_item = demux_SBTX_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.demux_SBTX_vif.drv_cb);
      cfg.demux_SBTX_vif.drv_cb.din <= seq_item.din;
      cfg.demux_SBTX_vif.drv_cb.sel <= seq_item.sel;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // DEMUX_SBTX_DRIVER_SVH
