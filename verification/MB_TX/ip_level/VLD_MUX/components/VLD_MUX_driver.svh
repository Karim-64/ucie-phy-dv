`ifndef VLD_MUX_DRIVER_SVH
`define VLD_MUX_DRIVER_SVH

// VLD_MUX_driver.svh
// Driver for the VLD_MUX sub-environment.
// Drives stimulus on the VLD_MUX virtual interface using VLD_MUX_sequence_item.

class VLD_MUX_driver extends uvm_driver #(VLD_MUX_sequence_item);
  `uvm_component_utils(VLD_MUX_driver)

  VLD_MUX_sequence_item seq_item;
  VLD_MUX_drv_mon_cfg_obj cfg;

  function new(string name = "VLD_MUX_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(VLD_MUX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("VLD_MUX_DRV", "VLD_MUX_drv_mon_cfg_obj not found in config_db for VLD_MUX_driver")
    seq_item = VLD_MUX_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.VLD_MUX_vif.drv_cb);
      cfg.VLD_MUX_vif.drv_cb.IN_0 <= seq_item.IN_0;
      cfg.VLD_MUX_vif.drv_cb.IN_1 <= seq_item.IN_1;
      cfg.VLD_MUX_vif.drv_cb.IN_2 <= seq_item.IN_2;
      cfg.VLD_MUX_vif.drv_cb.IN_3 <= seq_item.IN_3;
      cfg.VLD_MUX_vif.drv_cb.SEL_1 <= seq_item.SEL_1;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // VLD_MUX_DRIVER_SVH
