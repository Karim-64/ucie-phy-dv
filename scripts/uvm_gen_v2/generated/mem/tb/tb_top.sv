`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import mem_pkg::*;

  bit clk;

  // Clock generator
  initial begin
    clk = 0;
    forever begin
      #1 clk = ~clk;
    end
  end

  // Interface instantiation
  mem_if #(.DATA_WIDTH(DATA_WIDTH), .ADDRESS_WIDTH(ADDRESS_WIDTH))
      mem_if_inst (.clk(clk));

  // DUT instantiation
  Memory #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDRESS_WIDTH(ADDRESS_WIDTH)
  ) dut (
    .data_in(mem_if_inst.data_in),
    .addr(mem_if_inst.addr),
    .cs(mem_if_inst.cs),
    .we(mem_if_inst.we),
    .clk(clk),
    .rst(mem_if_inst.rst),
    .data_out(mem_if_inst.data_out),
    .valid_out(mem_if_inst.valid_out)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual mem_if#(DATA_WIDTH, ADDRESS_WIDTH))::set(
        null, "uvm_test_top", "MEM_VIF", mem_if_inst);
    run_test();
  end
endmodule
