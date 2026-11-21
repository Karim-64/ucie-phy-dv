`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import pe_sbtx_pkg::*;

  bit CLK;

  // Clock generator
  initial begin
    CLK = 0;
    forever begin
      #1 CLK = ~CLK;
    end
  end

  // Interface instantiations (one per agent)
  pe_sbtx_in_if #(.DATA_WIDTH(DATA_WIDTH)) d2d_if (.CLK(CLK));
  pe_sbtx_in_if #(.DATA_WIDTH(DATA_WIDTH)) phy_if (.CLK(CLK));
  pe_sbtx_out_if #(.DATA_WIDTH(DATA_WIDTH)) fifo_if (.CLK(CLK));

  // DUT instantiation
  Priority_Encoder_SBTX #(
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .CLK(CLK),
    .RST_n(phy_if.rst_n),
    .PHY_En(phy_if.en),
    .D2D_En(d2d_if.en),
    .Data_Marker_D2D(d2d_if.data_marker),
    .Data_Marker_PHY(phy_if.data_marker),
    .Comp_Marker_D2D(d2d_if.comp_marker),
    .PHY_Data(phy_if.data),
    .D2D_Data(d2d_if.data),
    .FIFO_WR(fifo_if.fifo_wr),
    .FIFO_Data(fifo_if.fifo_data),
    .Data_Marker(fifo_if.data_marker),
    .D2D_PHY_Marker(fifo_if.d2d_phy_marker),
    .Comp_Marker(fifo_if.comp_marker),
    .D2D_Resend_Req(d2d_if.resend_req),
    .PHY_Resend_Req(phy_if.resend_req)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual pe_sbtx_in_if#(DATA_WIDTH))::set(
        null, "uvm_test_top", "PE_SBTX_D2D_VIF", d2d_if);
    uvm_config_db#(virtual pe_sbtx_in_if#(DATA_WIDTH))::set(
        null, "uvm_test_top", "PE_SBTX_PHY_VIF", phy_if);
    uvm_config_db#(virtual pe_sbtx_out_if#(DATA_WIDTH))::set(
        null, "uvm_test_top", "PE_SBTX_FIFO_VIF", fifo_if);
    run_test();
  end
endmodule
