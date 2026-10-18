import Universal_pkg ::* ; 

module LFSR_module_MBRX #(parameter LFSR_WIDTH=23,SEED=23'h1DBFBC)  // this module consist of each LFSR and its accompanied MUX
(
 
  input  logic                 MB_CLK        ,        // Clock signal
  input  logic                 RST_n         ,        // Asynchronous reset
  input  LTSM_states           Opcode_Synch  ,        // to reset the LFSR on state transitions
  input  logic                 EN            ,        // Enable signal
  input  logic                 Data_In       ,        // input bit of each lane
  input  logic                 SEL_3         ,        // MUX select to determine which input goes to the LFSR depending on the state
  output logic                 Data_Out               // output scrambled bit of each lane

);

//Internal Signals

logic OUT;


//Inistantiate LFSR_Per_Lane

LFSR_PerLane_MBRX #(.WIDTH(LFSR_WIDTH),.Seed(SEED)) LFSR_PerLane_U0

(
.MB_CLK(MB_CLK)              ,        
.RST_n(RST_n)                ,      
.Opcode_Synch(Opcode_Synch)  ,        
.EN(EN)                      ,        
.Data_In(OUT)                ,       
.Data_Out(Data_Out)            
);


//Inistantiate MUX

MUX_MBRX  MUX_U0
(
  .IN_0(Data_In) ,
  .IN_1(1'b0) , 
  .SEL_3(SEL_3),
  .OUT(OUT)
 );


 endmodule
