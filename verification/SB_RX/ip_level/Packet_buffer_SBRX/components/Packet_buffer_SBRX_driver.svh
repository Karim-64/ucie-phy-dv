`ifndef PACKET_BUFFER_SBRX_DRIVER_SVH
`define PACKET_BUFFER_SBRX_DRIVER_SVH

// Packet_buffer_SBRX_driver.svh
// Driver for the Packet_buffer_SBRX sub-environment.
// Drives stimulus on the Packet_buffer_SBRX virtual interface using Packet_buffer_SBRX_sequence_item.

class Packet_buffer_SBRX_driver extends uvm_driver #(Packet_buffer_SBRX_sequence_item);
  `uvm_component_utils(Packet_buffer_SBRX_driver)

  Packet_buffer_SBRX_sequence_item seq_item;
  Packet_buffer_SBRX_drv_mon_cfg_obj cfg;

  function new(string name = "Packet_buffer_SBRX_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(Packet_buffer_SBRX_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("PACKET_BUFFER_SBRX_DRV", "Packet_buffer_SBRX_drv_mon_cfg_obj not found in config_db for Packet_buffer_SBRX_driver")
    seq_item = Packet_buffer_SBRX_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.Packet_buffer_SBRX_vif.drv_cb);
      cfg.Packet_buffer_SBRX_vif.drv_cb.sys_rst <= seq_item.sys_rst;
      cfg.Packet_buffer_SBRX_vif.drv_cb.wr_en <= seq_item.wr_en;
      cfg.Packet_buffer_SBRX_vif.drv_cb.rd_en <= seq_item.rd_en;
      cfg.Packet_buffer_SBRX_vif.drv_cb.wr_data <= seq_item.wr_data;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // PACKET_BUFFER_SBRX_DRIVER_SVH
