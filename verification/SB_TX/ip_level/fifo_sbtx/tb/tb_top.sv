`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import fifo_sbtx_pkg::*;

  bit clk;

  // Clock generator
  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  // Interface instantiation
  fifo_sbtx_if #(.FIFO_WIDTH(FIFO_WIDTH), .FIFO_DEPTH(FIFO_DEPTH))
      fifo_sbtx_if_inst (.clk(clk));

  // DUT instantiation
  FIFO_SBTX #(
    .FIFO_WIDTH(FIFO_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH)
  ) dut (
    .clk(clk),
    .rst_n(fifo_sbtx_if_inst.rst_n),
    .wr_en(fifo_sbtx_if_inst.wr_en),
    .rd_en(fifo_sbtx_if_inst.rd_en),
    .UIE(fifo_sbtx_if_inst.UIE),
    .data_in(fifo_sbtx_if_inst.data_in),
    .Data_Marker(fifo_sbtx_if_inst.Data_Marker),
    .Reg_Acc_Marker(fifo_sbtx_if_inst.Reg_Acc_Marker),
    .Reg_Acc_Data_Marker(fifo_sbtx_if_inst.Reg_Acc_Data_Marker),
    .Comp_Marker(fifo_sbtx_if_inst.Comp_Marker),
    .Req_Resp_Marker(fifo_sbtx_if_inst.Req_Resp_Marker),
    .data_out(fifo_sbtx_if_inst.data_out),
    .Data_Marker_Out(fifo_sbtx_if_inst.Data_Marker_Out),
    .Reg_Acc_Marker_Out(fifo_sbtx_if_inst.Reg_Acc_Marker_Out),
    .Reg_Acc_Data_Marker_Out(fifo_sbtx_if_inst.Reg_Acc_Data_Marker_Out),
    .Comp_Marker_Out(fifo_sbtx_if_inst.Comp_Marker_Out),
    .empty(fifo_sbtx_if_inst.empty),
    .rd_ack(fifo_sbtx_if_inst.rd_ack)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual fifo_sbtx_if#(FIFO_WIDTH, FIFO_DEPTH))::set(
        null, "uvm_test_top", "FIFO_SBTX_VIF", fifo_sbtx_if_inst);
    run_test();
  end
endmodule
