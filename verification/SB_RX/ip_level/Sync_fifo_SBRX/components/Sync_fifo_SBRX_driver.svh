`ifndef SYNC_FIFO_SBRX_DRIVER_SVH
`define SYNC_FIFO_SBRX_DRIVER_SVH

// Sync_fifo_SBRX_driver.svh
// Driver for the Sync_fifo_SBRX sub-environment.
// Drives stimulus on the Sync_fifo_SBRX virtual interface using Sync_fifo_SBRX_sequence_item.

class Sync_fifo_SBRX_driver extends uvm_driver #(Sync_fifo_SBRX_sequence_item);
  `uvm_component_utils(Sync_fifo_SBRX_driver)

  Sync_fifo_SBRX_sequence_item seq_item;
  Sync_fifo_SBRX_drv_mon_cfg_obj cfg;

  function new(string name = "Sync_fifo_SBRX_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(Sync_fifo_SBRX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("SYNC_FIFO_SBRX_DRV", "Sync_fifo_SBRX_drv_mon_cfg_obj not found in config_db for Sync_fifo_SBRX_driver")
    seq_item = Sync_fifo_SBRX_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.Sync_fifo_SBRX_vif.drv_cb);
      cfg.Sync_fifo_SBRX_vif.drv_cb.sys_rst <= seq_item.sys_rst;
      cfg.Sync_fifo_SBRX_vif.drv_cb.wr_en <= seq_item.wr_en;
      cfg.Sync_fifo_SBRX_vif.drv_cb.rd_en <= seq_item.rd_en;
      cfg.Sync_fifo_SBRX_vif.drv_cb.wr_data <= seq_item.wr_data;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // SYNC_FIFO_SBRX_DRIVER_SVH
