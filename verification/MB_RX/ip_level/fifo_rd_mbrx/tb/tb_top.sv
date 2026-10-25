`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import fifo_rd_mbrx_pkg::*;

  bit r_clk;

  // Clock generator
  initial begin
    r_clk = 0;
    forever begin
      #1 r_clk = ~r_clk;
    end
  end

  // Interface instantiation
  fifo_rd_mbrx_if #(.P_SIZE(P_SIZE))
      fifo_rd_mbrx_if_inst (.r_clk(r_clk));

  // DUT instantiation
  fifo_rd_MBRX #(
    .P_SIZE(P_SIZE)
  ) dut (
    .r_clk(r_clk),
    .r_rstn(fifo_rd_mbrx_if_inst.r_rstn),
    .r_inc(fifo_rd_mbrx_if_inst.r_inc),
    .sync_wr_ptr(fifo_rd_mbrx_if_inst.sync_wr_ptr),
    .rd_addr(fifo_rd_mbrx_if_inst.rd_addr),
    .empty(fifo_rd_mbrx_if_inst.empty),
    .gray_rd_ptr(fifo_rd_mbrx_if_inst.gray_rd_ptr)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual fifo_rd_mbrx_if#(P_SIZE))::set(
        null, "uvm_test_top", "FIFO_RD_MBRX_VIF", fifo_rd_mbrx_if_inst);
    run_test();
  end
endmodule
