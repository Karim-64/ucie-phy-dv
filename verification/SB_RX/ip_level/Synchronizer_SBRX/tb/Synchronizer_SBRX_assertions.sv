module Synchronizer_SBRX_assertions (
  input logic clk_dst,
  input logic rst_n,
  input logic signal_src,
  input logic signal_dst
);

bit synch;
always_comb begin
  if (!rst_n) begin
      reset_assertion:assert final (signal_dst == 1'b0);
  end
end

always_ff @(posedge clk_dst or negedge rst_n) begin
  if(!rst_n)begin
      synch <= 0;
  end
  else begin
    synch <= 1;
  end
end

property two_cycle_synchronization;
  @(posedge clk_dst) disable iff (!rst_n) synch |=> (signal_dst == $past(signal_src, 2));
endproperty

p1: assert property (two_cycle_synchronization)  else $error("[ASSERTION_ERROR] Output does not match input sampled two cycles earlier");;

endmodule
