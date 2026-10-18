module deserializer_MBRX #(parameter OP_LENGTH=8)
(
    input bit CLK             ,          // Clock
    input bit RST_n           ,          // Active-low Reset
    input bit Deser_Start     ,          // Start signal for de-serialization
    input bit Sampled_Bit     ,          // Incoming serial bit from lane
    output logic [OP_LENGTH-1:0] P_Data  // Output deserialized data (byte)
);          

    always_ff @(posedge CLK  or negedge RST_n) begin
	
        if (!RST_n) begin
		
            P_Data <= 'b0; 
			
        end else begin
				
            if (Deser_Start) begin
                
                P_Data <= {Sampled_Bit,P_Data[OP_LENGTH-1:1]};   // descrambled bit out of descrambler
                
            end
                
            else begin 

                P_Data<='b0;

            end
			
        end
    end

endmodule



