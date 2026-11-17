interface lfsr_per_lane_if #(
  parameter WIDTH = 23,
  parameter Seed = 23'h1DBFBC
) (input logic MB_CLK);
  wire logic RST_n;
  wire logic [4:0] Opcode_Synch;
  wire logic EN;
  wire logic PN_EN;
  wire logic Data_In;

  wire logic Data_Out;
  wire logic [7:0] Valid;
  wire logic VLD_SER_EN;

  clocking drv_cb @(posedge MB_CLK);
    // signals driven by the driver
    output RST_n;
    output Opcode_Synch;
    output EN;
    output PN_EN;
    output Data_In;
  endclocking

  clocking mon_cb @(posedge MB_CLK);
    // signals sampled by the monitor
    input Data_Out;
    input Valid;
    input VLD_SER_EN;
  endclocking
endinterface
