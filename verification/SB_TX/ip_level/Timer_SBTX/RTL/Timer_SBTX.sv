 
/*---------Description------------------//
 
this Module is required due to not supporting PMO 
where between each Message Phase(64 bits) and the other 
we need to asserts 32-low cycles and here comes the Timer 
Functionality.
 
//---------------------------------------*/
 
module Timer_SBTX #(parameter NO_OF_CYCLES=32)
(
    input logic  clk  ,               // Clock input
    input logic  rst_n,               // Active-low reset
    input logic  start,               // Start signal to activate the timer
    output logic alarm                // Alarm signal after 32 clock cycles
 
);
 
logic [$clog2(NO_OF_CYCLES)-1:0] count; 
logic counting_in_process;      
 
always_ff @(posedge clk or negedge rst_n) begin
    
    if (!rst_n) begin
 
        count  <='b0; 
        counting_in_process<='b0;
 
    end else if (start || counting_in_process) begin
 
        counting_in_process<=1'b1;
 
        if (count == NO_OF_CYCLES-1) begin
 
            counting_in_process<=1'b0; 
            count<='b0; 
 
        end else begin
 
            count <= count + 1; 
 
        end 
    end 
   
end
 
assign alarm = (count == NO_OF_CYCLES-1) ? 1'b1:1'b0;
 
endmodule