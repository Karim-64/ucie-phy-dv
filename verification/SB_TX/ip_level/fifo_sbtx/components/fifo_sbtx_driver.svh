`ifndef FIFO_SBTX_DRIVER_SVH
`define FIFO_SBTX_DRIVER_SVH

// fifo_sbtx_driver.svh
// Driver for the fifo_sbtx sub-environment.
// Drives stimulus on the fifo_sbtx virtual interface using fifo_sbtx_sequence_item.

class fifo_sbtx_driver extends uvm_driver #(fifo_sbtx_sequence_item);
  `uvm_component_utils(fifo_sbtx_driver)

  fifo_sbtx_sequence_item seq_item;
  fifo_sbtx_drv_mon_cfg_obj cfg;

  function new(string name = "fifo_sbtx_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(fifo_sbtx_drv_mon_cfg_obj)::get(this, "", "cfg", cfg))
      `uvm_fatal("FIFO_SBTX_DRV", "fifo_sbtx_drv_mon_cfg_obj not found in config_db for fifo_sbtx_driver")
    seq_item = fifo_sbtx_sequence_item::type_id::create("seq_item");
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      seq_item_port.get_next_item(seq_item);

      @(cfg.fifo_sbtx_vif.drv_cb);
      cfg.fifo_sbtx_vif.drv_cb.rst_n <= seq_item.rst_n;
      cfg.fifo_sbtx_vif.drv_cb.wr_en <= seq_item.wr_en;
      cfg.fifo_sbtx_vif.drv_cb.rd_en <= seq_item.rd_en;
      cfg.fifo_sbtx_vif.drv_cb.UIE <= seq_item.UIE;
      cfg.fifo_sbtx_vif.drv_cb.data_in <= seq_item.data_in;
      cfg.fifo_sbtx_vif.drv_cb.Data_Marker <= seq_item.Data_Marker;
      cfg.fifo_sbtx_vif.drv_cb.Reg_Acc_Marker <= seq_item.Reg_Acc_Marker;
      cfg.fifo_sbtx_vif.drv_cb.Reg_Acc_Data_Marker <= seq_item.Reg_Acc_Data_Marker;
      cfg.fifo_sbtx_vif.drv_cb.Comp_Marker <= seq_item.Comp_Marker;
      cfg.fifo_sbtx_vif.drv_cb.Req_Resp_Marker <= seq_item.Req_Resp_Marker;
      seq_item_port.item_done();
    end
  endtask
endclass

`endif // FIFO_SBTX_DRIVER_SVH
