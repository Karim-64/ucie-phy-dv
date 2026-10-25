module clk_gate_sva#(parameter PULSE_WIDTH=1) (
     clk_gate_sbtx_if vif
);

  realtime last_edge_time;
  realtime pulse_width;

  always @(vif.SBTX_CLK) begin
    pulse_width = $realtime - last_edge_time;
        if(last_edge_time > 0)
            assert (pulse_width>= PULSE_WIDTH) else
                $error("Runt pulse detected on SBTX_CLK! Pulse width was %0t, expected >= %0t",
            pulse_width, PULSE_WIDTH);
    last_edge_time=$realtime;  
  end

  //if Enable drops while CLK is high, SBTX_CLK doesn't drop

property p_no_high_chop;
    @(negedge vif.Enable or negedge vif.Load)
    (vif.CLK == 1'b1 && !(vif.Enable | vif.Load))
    |-> (vif.SBTX_CLK == 1'b1)
        until_with ($fell(vif.CLK));
endproperty

assert property (p_no_high_chop);
cover property (p_no_high_chop);

    
endmodule