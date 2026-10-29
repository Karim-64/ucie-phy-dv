module Serializer_assertions (
    input logic       MB_CLK,
    input logic       SER_EN,
    input logic [7:0] DATA,
    input logic       SER_OUT
);

// ser_out should be low if ser_en is disabled
property default_ser_out;
  @(posedge MB_CLK)  ~SER_EN |-> SER_OUT == 1'b0;
endproperty

p1: assert property (default_ser_out) else $error("[ASSERTION_ERROR] default_ser_out failed");

// ser_en should be high for 8 clk cycles after raise up.
property high_ser_en_for_8cycles;
  @(posedge MB_CLK)  $rose(SER_EN) |-> SER_EN[*8];
endproperty

p2: assert property (high_ser_en_for_8cycles) else $error("[ASSERTION_ERROR] high_ser_en_for_8cycles failed");



endmodule