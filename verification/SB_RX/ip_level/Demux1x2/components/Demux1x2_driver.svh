`ifndef DEMUX1X2_DRIVER_SVH
`define DEMUX1X2_DRIVER_SVH

// Demux1x2_driver.svh
// Driver for the Demux1x2 sub-environment.
// Drives stimulus on the Demux1x2 virtual interface using Demux1x2_sequence_item.

class Demux1x2_driver extends uvm_driver #(Demux1x2_sequence_item);
  `uvm_component_utils(Demux1x2_driver)

  Demux1x2_sequence_item seq_item;
  Demux1x2_drv_mon_cfg_obj cfg;

  function new(string name = "Demux1x2_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(Demux1x2_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("DEMUX1X2_DRV", "Demux1x2_drv_mon_cfg_obj not found in config_db for Demux1x2_driver")
    seq_item = Demux1x2_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.Demux1x2_vif.drv_cb);
      cfg.Demux1x2_vif.drv_cb.data_in <= seq_item.data_in;
      cfg.Demux1x2_vif.drv_cb.sel <= seq_item.sel;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // DEMUX1X2_DRIVER_SVH
