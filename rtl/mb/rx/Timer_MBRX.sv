
module Timer_MBRX #(parameter NO_OF_CYCLES=3)
(
    input logic  clk  ,               // Clock input
    input logic  rst_n,               // Active-low reset
    input logic  start,               // Start signal to activate the timer
    output logic alarm                // Alarm signal after 32 clock cycles

);

logic [1:0] count; 
logic counting_in_process;      

always_ff @(posedge clk or negedge rst_n) begin
    
    if (!rst_n) begin

        count  <='b0; 
        counting_in_process<='b0;
        alarm <=1'b0;

    end else if (start || counting_in_process) begin

        counting_in_process<=1'b1;

        if (count == NO_OF_CYCLES-1) begin

            counting_in_process<=1'b0; 
            count<='b0;
            alarm <=1'b1;

        end else begin

            count <= count + 1; 

        end 
    end else 
        alarm <=1'b0;
   
end

endmodule

