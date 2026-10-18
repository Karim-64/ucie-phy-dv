module Per_Lane_ID_MBRX #(parameter NUM_LANES=16)
(

output logic [15:0] Lanes_IDs[NUM_LANES-1:0]   

);


//********************Generate the Per-Lane IDs to use them for comparison********************//

genvar i; 
generate
    for (i = 0; i < NUM_LANES; i++) begin 
         assign Lanes_IDs[i] = {4'b1010, 8'(i[7:0]), 4'b1010};
    end
endgenerate

//*******************************************************************************************/

endmodule 
