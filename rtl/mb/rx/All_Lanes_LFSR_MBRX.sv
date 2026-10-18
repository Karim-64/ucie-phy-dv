import Universal_pkg ::* ; 

module All_Lanes_LFSR_MBRX #(parameter LFSR_WIDTH=23,NUM_LANES=16)
(

  input  logic                 MB_CLK        ,        // Clock signal
  input  logic                 RST_n         ,        // Asynchronous reset
  input  LTSM_states           Opcode_Synch  ,        // to reset the LFSR on state transitions
  input  logic                 EN            ,        // Enable signal
  input  logic [NUM_LANES-1:0] Data_In       ,        // input bits of all LFSRs
  input  logic                 SEL_3         ,        // MUX select to determine which input goes to the LFSR depending on the state
  output logic [NUM_LANES-1:0] Data_Out               // output de-scrambled of all LFSRs

);

localparam bit [LFSR_WIDTH-1:0] LFSR_SEEDS [7:0] = '{
23'h1bb807, 23'h0277ce, 23'h19cfc9, 23'h010F12,
    23'h18C0DB, 23'h1EC760, 23'h0607BB, 23'h1DBFBC
};


genvar i;

generate
  for (i = 0; i < NUM_LANES/2; i = i + 1) begin : gen_LFSR_LSL
    LFSR_module_MBRX #(
      .LFSR_WIDTH(LFSR_WIDTH),
      .SEED(LFSR_SEEDS[i])
    ) LFSR_inst (
      .MB_CLK       (MB_CLK),         
      .RST_n        (RST_n),         
      .Opcode_Synch (Opcode_Synch),       
      .EN           (EN),         
      .Data_In      (Data_In[i]),         
      .SEL_3        (SEL_3),             
      .Data_Out     (Data_Out[i])        
    );
  end
endgenerate


genvar j;

generate
  for (j = NUM_LANES/2; j < NUM_LANES; j = j + 1) begin : gen_LFSR_MSL
    LFSR_module_MBRX #(
      .LFSR_WIDTH(LFSR_WIDTH),
      .SEED(LFSR_SEEDS[j-8])
    ) LFSR_inst (
      .MB_CLK       (MB_CLK),         
      .RST_n        (RST_n),         
      .Opcode_Synch (Opcode_Synch),       
      .EN           (EN),         
      .Data_In      (Data_In[j]),         
      .SEL_3        (SEL_3),             
      .Data_Out     (Data_Out[j])        
    );
  end
endgenerate


endmodule
