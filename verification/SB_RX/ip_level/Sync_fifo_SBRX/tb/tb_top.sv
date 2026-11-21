`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import Sync_fifo_SBRX_pkg::*;

  bit lclk;

  // Clock generator
  initial begin
    lclk = 0;
    forever begin
      #1 lclk = ~lclk;
    end
  end

  // Interface instantiation
  Sync_fifo_SBRX_if #(.DATA_WIDTH(DATA_WIDTH), .FIFO_DEPTH(FIFO_DEPTH))
      Sync_fifo_SBRX_if_inst (.lclk(lclk));

  // DUT instantiation
  Sync_fifo_SBRX #(
    .DATA_WIDTH(DATA_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
  ) dut (
    .lclk(lclk),
    .sys_rst(Sync_fifo_SBRX_if_inst.sys_rst),
    .wr_en(Sync_fifo_SBRX_if_inst.wr_en),
    .rd_en(Sync_fifo_SBRX_if_inst.rd_en),
    .wr_data(Sync_fifo_SBRX_if_inst.wr_data),
    .rd_data(Sync_fifo_SBRX_if_inst.rd_data),
    .full(Sync_fifo_SBRX_if_inst.full),
    .empty(Sync_fifo_SBRX_if_inst.empty)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual Sync_fifo_SBRX_if#(DATA_WIDTH, FIFO_DEPTH))::set(
        null, "uvm_test_top", "SYNC_FIFO_SBRX_VIF", Sync_fifo_SBRX_if_inst);
    run_test("Sync_fifo_SBRX_base_test");
  end
endmodule
