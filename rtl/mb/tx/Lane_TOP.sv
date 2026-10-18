//implementing each Lane Top module
module Lane_TOP #( parameter LFSR_WIDTH = 23,         // Width of the LFSR
                   parameter LFSR_Seed  = 23'h1DBFBC ) 

(
 input   wire            MB_CLK,
 input   wire    [7:0]   DATA_IN,     // 8-bit parallel input
 input   wire            SER_EN,
 input   wire            PN_EN, 
 input   wire            Scramble_EN,
 input   wire            RST_n,        // Asynchronous reset
 input   wire    [4:0]   Opcode_Synch  ,        // to reset the LFSR on state transitions

 output  wire            DATA_OUT,
 output  wire    [7:0]   Valid_LFSR_output,
 output  wire            VLD_SER_Enable
);


 //internal signals
 wire          SER_OUTPUT;
 wire          MUX_3_OUT;


///********************************************************///
/////////////////////// Lane 0 Serializer ////////////////////
///********************************************************///

Serializer U1_Serializer ( 
.MB_CLK (MB_CLK), 
.SER_EN (SER_EN),
.DATA (DATA_IN), 
.SER_OUT (SER_OUTPUT)
);


///********************************************************///
////////////////// Mux 3 of each Lane output /////////////////////
///********************************************************///

MUX U0_MUX (
.IN_0 (SER_OUTPUT), 
.IN_1 (1'b0),
.SEL_3 (PN_EN),
.OUT (MUX_3_OUT)
);


///********************************************************///
////////////////////// PerLane LFSR //////////////////////////
///********************************************************///

LFSR_PerLane #( .WIDTH(LFSR_WIDTH), .Seed(LFSR_Seed)) U0_LFSR_PerLane (
.MB_CLK (MB_CLK),
.RST_n (RST_n),       
.Opcode_Synch (Opcode_Synch),        
.EN (Scramble_EN),   
.PN_EN (PN_EN),     
.Data_In (MUX_3_OUT),        
.Data_Out (DATA_OUT),
.Valid (Valid_LFSR_output),
.VLD_SER_EN (VLD_SER_Enable)           
);


endmodule