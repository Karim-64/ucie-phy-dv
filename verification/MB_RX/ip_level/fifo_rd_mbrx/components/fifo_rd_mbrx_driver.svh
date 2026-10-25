`ifndef FIFO_RD_MBRX_DRIVER_SVH
`define FIFO_RD_MBRX_DRIVER_SVH

// fifo_rd_mbrx_driver.svh
// Driver for the fifo_rd_mbrx sub-environment.
// Drives stimulus on the fifo_rd_mbrx virtual interface using fifo_rd_mbrx_sequence_item.

class fifo_rd_mbrx_driver extends uvm_driver #(fifo_rd_mbrx_sequence_item);
  `uvm_component_utils(fifo_rd_mbrx_driver)

  fifo_rd_mbrx_sequence_item seq_item;
  fifo_rd_mbrx_drv_mon_cfg_obj cfg;

  function new(string name = "fifo_rd_mbrx_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(fifo_rd_mbrx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("FIFO_RD_MBRX_DRV", "fifo_rd_mbrx_drv_mon_cfg_obj not found in config_db for fifo_rd_mbrx_driver")
    seq_item = fifo_rd_mbrx_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.fifo_rd_mbrx_vif.drv_cb);
      cfg.fifo_rd_mbrx_vif.drv_cb.r_rstn <= seq_item.r_rstn;
      cfg.fifo_rd_mbrx_vif.drv_cb.r_inc <= seq_item.r_inc;
      cfg.fifo_rd_mbrx_vif.drv_cb.sync_wr_ptr <= seq_item.sync_wr_ptr;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // FIFO_RD_MBRX_DRIVER_SVH
