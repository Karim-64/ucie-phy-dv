`ifndef UP_DOWN_COUNTER_DRIVER_SVH
`define UP_DOWN_COUNTER_DRIVER_SVH

// up_down_counter_driver.svh
// Driver for the up_down_counter sub-environment.
// Drives stimulus on the up_down_counter virtual interface using up_down_counter_sequence_item.

class up_down_counter_driver extends uvm_driver #(up_down_counter_sequence_item);
  `uvm_component_utils(up_down_counter_driver)

  up_down_counter_sequence_item seq_item;
  up_down_counter_drv_mon_cfg_obj cfg;

  function new(string name = "up_down_counter_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(up_down_counter_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("UP_DOWN_COUNTER_DRV", "up_down_counter_drv_mon_cfg_obj not found in config_db for up_down_counter_driver")
    seq_item = up_down_counter_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);
      
        @(cfg.up_down_counter_vif.drv_cb);

      cfg.up_down_counter_vif.drv_cb.sys_rst <= seq_item.sys_rst;
      cfg.up_down_counter_vif.drv_cb.up <= seq_item.up;
      cfg.up_down_counter_vif.drv_cb.down <= seq_item.down;
      
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // UP_DOWN_COUNTER_DRIVER_SVH
