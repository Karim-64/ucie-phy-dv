interface fifo_sbtx_if #(
  parameter FIFO_WIDTH = 64,
  parameter FIFO_DEPTH = 64
) (input logic clk);
  wire logic rst_n;
  wire logic wr_en;
  wire logic rd_en;
  wire logic UIE;
  wire logic [FIFO_WIDTH-1:0] data_in;
  wire logic Data_Marker;
  wire logic Reg_Acc_Marker;
  wire logic Reg_Acc_Data_Marker;
  wire logic Comp_Marker;
  wire logic Req_Resp_Marker;

  wire logic [FIFO_WIDTH-1:0] data_out;
  wire logic Data_Marker_Out;
  wire logic Reg_Acc_Marker_Out;
  wire logic Reg_Acc_Data_Marker_Out;
  wire logic Comp_Marker_Out;
  wire logic empty;
  wire logic rd_ack;

  clocking drv_cb @(posedge clk);
    // signals driven by the driver
    output rst_n;
    output wr_en;
    output rd_en;
    output UIE;
    output data_in;
    output Data_Marker;
    output Reg_Acc_Marker;
    output Reg_Acc_Data_Marker;
    output Comp_Marker;
    output Req_Resp_Marker;
  endclocking

  clocking mon_cb @(posedge clk);
    // signals sampled by the monitor
    input data_out;
    input Data_Marker_Out;
    input Reg_Acc_Marker_Out;
    input Reg_Acc_Data_Marker_Out;
    input Comp_Marker_Out;
    input empty;
    input rd_ack;
  endclocking
endinterface
