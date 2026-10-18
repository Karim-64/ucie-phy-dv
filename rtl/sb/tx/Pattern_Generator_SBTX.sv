
/*---------Description------------------//

this Module generates the SBINIT Pattern and control the Timer_64(10101.....)

//---------------------------------------*/


module Pattern_Generator_SBTX 
(
    input  logic CLK, RST_n  ,         // Clock & Active-low reset
    input  logic Patt_Gen_En ,         // Enable signal to start
    output logic start_64    ,         // Trigger for the 64-cycle timer
    output logic SBTX_DATA             // Serialized output (1-bit)
);

// Internal signals
logic Pattern;

always_ff @(posedge CLK or negedge RST_n) begin 

    if (!RST_n) begin 
        
        Pattern <= 1'b1; 
    
    end else if (Patt_Gen_En) begin 
 
        Pattern <= ~Pattern;  // Toggle pattern
    
    end else begin 

        Pattern <= 1'b1;  // Reset pattern

    end 

end


always_ff @(posedge CLK or negedge RST_n) begin 

    if (!RST_n) begin 
        
     SBTX_DATA<='b0;
     start_64  <= 1'b0;
    
    end else if (Patt_Gen_En) begin 

     SBTX_DATA <= Pattern;
     start_64  <= 1'b1;
     
    end else begin

     SBTX_DATA <= 1'b0;
     start_64  <= 1'b0;

    end 

end


endmodule