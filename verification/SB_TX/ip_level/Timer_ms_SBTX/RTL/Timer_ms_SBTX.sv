module Timer_ms_SBTX #(parameter CLK_FREQ_HZ = 800_000_000 ,FACTOR = 1000)
(
    input  logic  clk  ,                     // Clock input
    input  logic  rst_n,                     // Active-low reset
    input  logic  start,                     // Start signal
    output logic  alarm,patt_alarm           // Alarm asserted after 1ms
);

    localparam int COUNT_MAX = (CLK_FREQ_HZ / FACTOR);  // Number of clock cycles for 1ms

    logic [$clog2(COUNT_MAX)-1:0] count;  
    logic counting_in_process;      

always_ff @(posedge clk or negedge rst_n) begin
    
    if (!rst_n) begin

        count  <='b0; 
        counting_in_process<='b0;

    end else if (start || counting_in_process) begin

        counting_in_process<=1'b1;

        if (count == COUNT_MAX-1) begin

            counting_in_process<=1'b0; 
            count<='b0; 

        end else begin

            count <= count + 1; 

        end 
    end 
   
end

assign alarm = (count == COUNT_MAX-1) ? 1'b1 : 1'b0;
assign patt_alarm = (count == COUNT_MAX-32) ? 1'b1 : 1'b0;

endmodule



