`ifndef MEM_DRIVER_SVH
`define MEM_DRIVER_SVH

// mem_driver.svh
// Driver for the mem sub-environment.
// Drives stimulus on the mem virtual interface using mem_sequence_item.

class mem_driver extends uvm_driver #(mem_sequence_item);
  `uvm_component_utils(mem_driver)

  mem_sequence_item seq_item;
  mem_drv_mon_cfg_obj cfg;

  function new(string name = "mem_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(mem_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("MEM_DRV", "mem_drv_mon_cfg_obj not found in config_db for mem_driver")
    seq_item = mem_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.mem_vif.drv_cb);
      cfg.mem_vif.drv_cb.rst <= seq_item.rst;
      cfg.mem_vif.drv_cb.cs <= seq_item.cs;
      cfg.mem_vif.drv_cb.we <= seq_item.we;
      cfg.mem_vif.drv_cb.addr <= seq_item.addr;
      cfg.mem_vif.drv_cb.data_in <= seq_item.data_in;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // MEM_DRIVER_SVH
