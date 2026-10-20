//implementing 1x2 Data De-Multiplexer
module DEMUX (
    input       [63:0] [7:0]  lp_data,       // 64-byte input
    input                     SEL_4,         // 1-bit select signal
    output      [63:0] [7:0]  lp_data_0,     // 64-byte output 0 (of normal active operation when pl_trdy is asserted)
    output reg  [63:0] [7:0]  lp_data_1      // 64-byte output 1 (of stall req ack mechanism handshake when pl_stallreq is asserted)
);


assign lp_data_0 = SEL_4 ? 'b0     : lp_data ;
assign lp_data_1 = SEL_4 ? lp_data : 'b0 ;


endmodule