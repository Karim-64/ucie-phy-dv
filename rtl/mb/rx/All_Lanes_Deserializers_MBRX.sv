module All_Lanes_Deserializers_MBRX #(parameter FRAME_LENGTH=8,NUM_LANES=16,W_D_SIZE=128)

(
input bit CLK,
input bit RST_n,
input bit Deserializer_EN1,Deserializer_EN2,
input bit [NUM_LANES-1:0] Data_Lanes,
output bit [W_D_SIZE-1:0] All_Lanes
);

logic [FRAME_LENGTH-1:0] Lanes_Bytes[NUM_LANES-1:0];

// Deserializer instantiation for Lower significant Lanes (LSL)
genvar i;
generate
  for (i = 0; i < NUM_LANES/2; i = i + 1) begin : gen_Deser_LSL
    deserializer_MBRX #(
      .OP_LENGTH(FRAME_LENGTH)
    ) deserializer_inst (
      .CLK          (CLK),                 
      .RST_n        (RST_n),               
      .Deser_Start  (Deserializer_EN1),   
      .Sampled_Bit  (Data_Lanes[i]),       
      .P_Data       (Lanes_Bytes[i])       
    ); 
  end
endgenerate

// Deserializer instantiation for Most significant Lanes (MSL)
genvar j;
generate
  for (j = NUM_LANES/2; j < NUM_LANES; j = j + 1) begin : gen_Deser_MSL
    deserializer_MBRX #(
      .OP_LENGTH(FRAME_LENGTH)
    ) deserializer_inst (
      .CLK          (CLK),
      .RST_n        (RST_n),
      .Deser_Start  (Deserializer_EN2),
      .Sampled_Bit  (Data_Lanes[j]),
      .P_Data       (Lanes_Bytes[j])
    ); 
  end
endgenerate

// Assemble all deserialized bytes into a wide bus
genvar k;
generate 
  for (k = 0; k < NUM_LANES; k = k + 1) begin : gen_all_lanes
    assign All_Lanes[(k+1)*FRAME_LENGTH-1 -: FRAME_LENGTH] = Lanes_Bytes[k];
  end
endgenerate


endmodule









