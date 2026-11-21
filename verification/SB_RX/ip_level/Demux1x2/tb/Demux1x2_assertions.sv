module Demux1x2_assertions #(
  parameter int DATA_WIDTH = 64
) (
  input logic                 clk,
  input logic [DATA_WIDTH-1:0] data_in,
  input logic                 sel,
  input logic [DATA_WIDTH-1:0] out0,
  input logic [DATA_WIDTH-1:0] out1
);


  property p_select_zero_routes_data_to_out0;
    @(posedge clk) sel === 1'b0 |-> (out0 === data_in && out1 === {DATA_WIDTH{1'b0}});
  endproperty

  property p_select_one_routes_data_to_out1;
    @(posedge clk) sel === 1'b1 |-> (out1 === data_in && out0 === {DATA_WIDTH{1'b0}});
  endproperty


  a_select_zero_routes_data_to_out0: assert property (p_select_zero_routes_data_to_out0)
    else $error("a_select_zero_routes_data_to_out0 assertion failed");

  a_select_one_routes_data_to_out1: assert property (p_select_one_routes_data_to_out1)
    else $error("a_select_one_routes_data_to_out1 assertion failed");

endmodule
