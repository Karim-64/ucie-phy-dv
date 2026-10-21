`timescale 1ns/1ns
module tb_top();
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import up_down_counter_pkg::*;

  bit lclk;

  // Clock generator
  initial begin
    lclk = 0;
    forever begin
      #1 lclk = ~lclk;
    end
  end

  // Interface instantiation
  up_down_counter_if #(.WIDTH(WIDTH))
      up_down_counter_if_inst (.lclk(lclk));

  // DUT instantiation
  up_down_counter #(
    .WIDTH(WIDTH)
  ) dut (
    .lclk(lclk),
    .sys_rst(up_down_counter_if_inst.sys_rst),
    .up(up_down_counter_if_inst.up),
    .down(up_down_counter_if_inst.down),
    .count(up_down_counter_if_inst.count)
  );

  // Config DB & test start
  initial begin
    uvm_config_db#(virtual up_down_counter_if#(WIDTH))::set(
        null, "uvm_test_top", "UP_DOWN_COUNTER_VIF", up_down_counter_if_inst);
    run_test("up_down_counter_base_test");
  end
endmodule
