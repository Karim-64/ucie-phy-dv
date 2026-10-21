`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import Packet_buffer_SBRX_pkg::*;

  bit lclk;

  // Clock generator
  initial begin
    lclk = 0;
    forever begin
      #1 lclk = ~lclk;
    end
  end

  // Interface instantiation
  Packet_buffer_SBRX_if #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH))
      Packet_buffer_SBRX_if_inst (.lclk(lclk));

  // DUT instantiation
  Packet_buffer_SBRX #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH)
  ) dut (
    .lclk(lclk),
    .sys_rst(Packet_buffer_SBRX_if_inst.sys_rst),
    .wr_en(Packet_buffer_SBRX_if_inst.wr_en),
    .rd_en(Packet_buffer_SBRX_if_inst.rd_en),
    .wr_data(Packet_buffer_SBRX_if_inst.wr_data),
    .rd_data(Packet_buffer_SBRX_if_inst.rd_data),
    .full(Packet_buffer_SBRX_if_inst.full),
    .empty(Packet_buffer_SBRX_if_inst.empty)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual Packet_buffer_SBRX_if#(DATA_WIDTH, DEPTH))::set(
        null, "uvm_test_top", "PACKET_BUFFER_SBRX_VIF", Packet_buffer_SBRX_if_inst);
    run_test();
  end
endmodule
