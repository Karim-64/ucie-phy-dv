`ifndef LANES_MUX_DRIVER_SVH
`define LANES_MUX_DRIVER_SVH

// Lanes_MUX_driver.svh
// Driver for the Lanes_MUX sub-environment.
// Drives stimulus on the Lanes_MUX virtual interface using Lanes_MUX_sequence_item.

class Lanes_MUX_driver extends uvm_driver #(Lanes_MUX_sequence_item);
  `uvm_component_utils(Lanes_MUX_driver)

  Lanes_MUX_sequence_item seq_item;
  Lanes_MUX_drv_mon_cfg_obj cfg;

  function new(string name = "Lanes_MUX_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(Lanes_MUX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("LANES_MUX_DRV", "Lanes_MUX_drv_mon_cfg_obj not found in config_db for Lanes_MUX_driver")
    seq_item = Lanes_MUX_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.Lanes_MUX_vif.drv_cb);
      cfg.Lanes_MUX_vif.drv_cb.IN_0 <= seq_item.IN_0;
      cfg.Lanes_MUX_vif.drv_cb.IN_1 <= seq_item.IN_1;
      cfg.Lanes_MUX_vif.drv_cb.SEL_2 <= seq_item.SEL_2;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // LANES_MUX_DRIVER_SVH
