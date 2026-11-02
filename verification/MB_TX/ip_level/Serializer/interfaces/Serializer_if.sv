interface Serializer_if #(
) (input logic MB_CLK);
  wire logic SER_EN;
  wire logic [7:0] DATA;

  wire logic SER_OUT;

  clocking drv_cb @(posedge MB_CLK);
    // signals driven by the driver
    output SER_EN;
    output DATA;
  endclocking

  clocking mon_cb @(posedge MB_CLK);
    // signals sampled by the monitor
    input SER_OUT;
  endclocking
endinterface
