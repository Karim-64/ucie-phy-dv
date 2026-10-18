//implementing the Main Band Transmitter Top module
module MB_TX_TOP #( parameter LFSR_WIDTH_TOP = 23,         // Width of the LFSR
                    parameter LFSR_Seed_TOP  = 23'h1DBFBC,
                    parameter DATA_WIDTH_TOP = 64,   // Width of data in FIFO
                    parameter FIFO_DEPTH_TOP = 4,   // FIFO's depth (must be power of 2)
                    parameter DATA_SIZE_TOP  = 2    // Gray Synchronizer Data Size

)(top_if.mbtx MT_IF);

         wire              lclk;
         wire              lclk_RST;           // Active-low write domain (lclk) reset
         wire              MB_CLK;
         wire              RST_n;              // Active-low read domain (MB_CLK) reset
         wire              lp_valid;           //from RDI Interface
         wire              lp_irdy;            //from RDI Interface
         wire              pl_trdy;           //from LTSM
         wire              pl_stallreq;     //from SB Controller
         wire  [63:0][7:0] lp_data;            //from RDI Interface  // demux input
         wire              lane_reversal_LTSM; //from SB Controller   
         wire  [1:0]       width_degrade_LTSM; //from SB Controller 
         wire  [4:0]       Opcode;             //from LTSM "Synchronized"
         wire              Start_LTSM;         //from SB Controller 
 
         wire              TVLD_P;
         wire  [15:0]      TD_P;
         wire              End_LTSM_Synch;
         wire              FULL;
         wire              Empty_Synch;


assign lclk               = MT_IF.lclk;
assign lclk_RST           = MT_IF.RST_n;
assign MB_CLK             = MT_IF.mbclk;
assign RST_n              = MT_IF.RST_n;
assign lp_valid           = MT_IF.lp_valid;
assign lp_irdy            = MT_IF.lp_irdy;
assign pl_trdy            = MT_IF.pl_trdy;
assign pl_stallreq        = MT_IF.pl_stallreq;
assign lane_reversal_LTSM = MT_IF.lane_reversal;
assign width_degrade_LTSM = MT_IF.width_degrade;
assign Opcode             = MT_IF.Opcode_Sync;
assign Start_LTSM         = MT_IF.start_LTSM;
assign lp_data            = MT_IF.lp_data;

assign MT_IF.TD_P           = TD_P;
assign MT_IF.TVLD_P         = TVLD_P;
assign MT_IF.End_LTSM_Synch = End_LTSM_Synch;
assign MT_IF.FULL           = FULL;
assign MT_IF.Empty_Synch    = Empty_Synch;

 //internal signals
 wire  [63:0][7:0]  lp_data_Synch;    // mux output & input to Byte-to-Lane Mapper

 wire  [63:0][7:0]  lp_data_Synch_1;  // mux input 1
 wire  [63:0][7:0]  lp_data_Synch_2;  // mux input 2

 wire  [63:0][7:0]  lp_data_0;  // demux ouput 1
 wire  [63:0][7:0]  lp_data_1;  // demux ouput 2

 wire               RD_EN;     //from MB_TX Controller
 wire               RD_EN_2;   //from MB_TX Controller

 wire               SEL_5;

 wire               EMPTY;   // from first FIFO 
 wire               EMPTY_2;   // from second FIFO 
 wire               Empty;
 wire               FULL_2;

 wire               End_LTSM;

 wire               lane_reversal_LTSM_Synch;   
 wire  [1:0]        width_degrade_LTSM_Synch;
 wire  [4:0]        Opcode_Synch;
 wire               Start_LTSM_Synch;  
  								   
 wire	            VALTRAIN_Done;
 wire               Byte_Mapping_Done;
 wire               PerLaneID_Done;
 
 wire	            VALTRAIN_Enable;
 wire               Byte_Mapping_Enable;
 wire               PerLaneID_Enable;

 wire               PN_EN; 
 wire               Scramble_EN;
 wire  [1:0]        SEL_1;
 wire               SEL_2;

 wire  [7:0]        Valid_test_output;

 wire  [18:0]       VLD_SER_Enable;
 wire               main_vld_Ser_En;

 wire  [7:0]        Active_Lanes [15:0];
 wire  [7:0]        Valid_acitve_output;
 wire               LANE_SER_Enable;

 wire               lane_Ser_1;
 wire               lane_Ser_2;

 wire  [7:0]        PerLaneID_Lanes [15:0];
 wire  [7:0]        Valid_PerLaneID_output;

 wire  [7:0]        Valid_LFSR_output [15:0];

 wire  [7:0]        MUX_1_OUT;
 wire  [7:0]        MUX_2_OUT  [15:0];

 wire  [15:0]       TD_L; // Intermediate wire for module output " Logical Output Lanes "

 wire wr_en_sig;


assign Opcode_Synch = Opcode;


assign wr_en_sig = pl_trdy && !pl_stallreq;


assign Empty = EMPTY && EMPTY_2;
   

assign main_vld_Ser_En = (|VLD_SER_Enable);
assign LANE_SER_Enable = (lane_Ser_1|lane_Ser_2);


// Conditional assignment based on lane_reversal_LTSM_Synch
genvar i;
generate
    for (i = 0; i < 16; i = i + 1) begin : lane_reversal_assignment
        assign TD_P[i] = lane_reversal_LTSM_Synch ? TD_L[15 - i] : TD_L[i];
    end
endgenerate


///********************************************************///
/////////////////////// Synchronizer /////////////////////////  // Synchronizing the input Lane Reversal signal coming from the lclk domain
///********************************************************///

Synchronizer U0_Synchronizer (
.CLK (MB_CLK), 
.RST (RST_n),
.UnSynch_Input (lane_reversal_LTSM),     

.Synch_Output (lane_reversal_LTSM_Synch)
);


///********************************************************///
/////////////////////// Gray Synchronizer ////////////////////  // Synchronizing the input Width Degrade signal coming from the lclk domain
///********************************************************///

Gray_Synchronizer #( .DATA_SIZE(DATA_SIZE_TOP)) U0_Gray_Synchronizer (
.MB_CLK (MB_CLK), 
.RST_n (RST_n),
.Async_Data (width_degrade_LTSM),     

.Sync_Data (width_degrade_LTSM_Synch)
);



///********************************************************///
/////////////////////// Gray Synchronizer ////////////////////  // Synchronizing the input Opcode (cs) signal coming from the lclk domain
///********************************************************///
/*
Gray_Synchronizer #( .DATA_SIZE(5)) U1_Gray_Synchronizer (
.MB_CLK (MB_CLK), 
.RST_n (RST_n),
.Async_Data (Opcode),     

.Sync_Data (Opcode_Synch)
); */ 



///********************************************************///
/////////////////////// Synchronizer /////////////////////////  // Synchronizing the output Empty signal coming from the MB_CLK domain
///********************************************************///

Synchronizer U1_Synchronizer (
.CLK (lclk), 
.RST (lclk_RST),
.UnSynch_Input (Empty),     

.Synch_Output (Empty_Synch)
);


///********************************************************///
/////////////////////// Pulse Synchronizer ///////////////////  // Synchronizing the input Start pulse signal coming from the lclk domain
///********************************************************///

Pulse_Synchronizer U0_Pulse_Synchronizer (
.src_CLK (lclk),
.src_RST (lclk_RST),
.src_pulse (Start_LTSM),
.dst_CLK (MB_CLK), 
.dst_RST (RST_n),

.dst_pulse (Start_LTSM_Synch)    
);


///********************************************************///
/////////////////////// Pulse Synchronizer ///////////////////   // Synchronizing the output End pulse signal coming from the MB_CLK domain
///********************************************************///

Pulse_Synchronizer U1_Pulse_Synchronizer (
.src_CLK (MB_CLK),
.src_RST (RST_n),
.src_pulse (End_LTSM),
.dst_CLK (lclk), 
.dst_RST (lclk_RST),

.dst_pulse (End_LTSM_Synch)    
);


///********************************************************///
////////////////// De-Mux of Data input /////////////////////
///********************************************************///

DEMUX U0_DEMUX (
.lp_data (lp_data), 
.SEL_4 (pl_stallreq),

.lp_data_0 (lp_data_0),
.lp_data_1 (lp_data_1)
);


///********************************************************///
/////////////////////// Async_FIFO  /////////////////////////    // pl_trdy in active state FIFO 1
///********************************************************///

Async_FIFO #( .DATA_WIDTH(DATA_WIDTH_TOP), .FIFO_DEPTH(FIFO_DEPTH_TOP)) U0_Async_FIFO (
.lclk (lclk),
.lclk_RST (lclk_RST),
.MB_CLK (MB_CLK), 
.rst_n (RST_n),
.lp_valid (lp_valid),
.lp_irdy (lp_irdy),
.wr_en (wr_en_sig),
.lp_data (lp_data_0),
.RD_EN (RD_EN),

.lp_data_Synch (lp_data_Synch_1),
.FULL (FULL),
.EMPTY (EMPTY)
);


///********************************************************///
/////////////////////// Async_FIFO 2  /////////////////////////   // pl_stallreq in active state FIFO 2
///********************************************************///

Async_FIFO #( .DATA_WIDTH(DATA_WIDTH_TOP), .FIFO_DEPTH(FIFO_DEPTH_TOP)) U1_Async_FIFO (
.lclk (lclk),
.lclk_RST (lclk_RST),
.MB_CLK (MB_CLK), 
.rst_n (RST_n),
.lp_valid (lp_valid),
.lp_irdy (lp_irdy),
.wr_en (pl_stallreq),
.lp_data (lp_data_1),
.RD_EN (RD_EN_2),

.lp_data_Synch (lp_data_Synch_2),
.FULL (FULL_2),
.EMPTY (EMPTY_2)
);


///********************************************************///
//////// Mux 5 of Data input to Byte-to-Lane Mapper //////////
///********************************************************///

Data_MUX U0_Data_MUX (
.IN_0 (lp_data_Synch_1), 
.IN_1 (lp_data_Synch_2),
.SEL_5 (SEL_5),
.OUT (lp_data_Synch)
);


///********************************************************///
////////////////////// TX Controller /////////////////////////
///********************************************************///

TX_Controller U0_TX_Controller (
.MB_CLK (MB_CLK), 
.Opcode_Synch (Opcode_Synch),  
.Start_LTSM_Synch (Start_LTSM_Synch), 
.Done_1 (VALTRAIN_Done),
.Done_2 (Byte_Mapping_Done),
.Done_3 (PerLaneID_Done),
.EMPTY (EMPTY),
.EMPTY_2 (EMPTY_2),
.width_degrade_LTSM_Synch (width_degrade_LTSM_Synch),

.VALTRAIN_EN (VALTRAIN_Enable),
.BYTE_MAP_EN (Byte_Mapping_Enable),
.PerLaneID_EN (PerLaneID_Enable),
.PN_EN (PN_EN), 
.Scramble_EN (Scramble_EN),
.SEL_1 (SEL_1),
.SEL_2 (SEL_2),
.SEL_5 (SEL_5),
.End_LTSM (End_LTSM),
.RD_EN (RD_EN),
.RD_EN_2 (RD_EN_2)
);


///********************************************************///
///////////////// VALTRAIN Generator /////////////////////////
///********************************************************///

VALTRAIN_Generator U0_VALTRAIN_Generator (
.MB_CLK (MB_CLK), 
.VALTRAIN_EN (VALTRAIN_Enable),

.Valid (Valid_test_output),
.VLD_SER_EN (VLD_SER_Enable[0]),
.Done_1 (VALTRAIN_Done)           
);


///********************************************************///
//////////////////// Byte-to-Lane Mapper /////////////////////
///********************************************************///

Byte_Mapper U0_Byte_Mapper (
.MB_CLK (MB_CLK), 
.BYTE_MAP_EN (Byte_Mapping_Enable),
.width_degrade_LTSM_Synch (width_degrade_LTSM_Synch),
.lp_data_Synch (lp_data_Synch),

.Lanes (Active_Lanes),
.Valid (Valid_acitve_output),
.VLD_SER_EN (VLD_SER_Enable[1]),
.LANE_SER_EN (lane_Ser_1),
.Done_2 (Byte_Mapping_Done)
);


///********************************************************///
///////////////////// Per-Lane ID Generator //////////////////
///********************************************************///

PerLaneID_Generator U0_PerLaneID_Generator (
.MB_CLK (MB_CLK), 
.PerLaneID_EN (PerLaneID_Enable),    
.width_degrade_LTSM_Synch (width_degrade_LTSM_Synch),

.Lanes (PerLaneID_Lanes),
.Valid (Valid_PerLaneID_output),
.VLD_SER_EN (VLD_SER_Enable[2]),
.LANE_SER_EN (lane_Ser_2),
.Done_3 (PerLaneID_Done)      
);


///********************************************************///
////////////////// Mux 1 of Valid output /////////////////////
///********************************************************///

VLD_MUX U0_VLD_MUX (
.IN_0 (Valid_test_output), 
.IN_1 (Valid_acitve_output),
.IN_2 (Valid_PerLaneID_output),
.IN_3 (Valid_LFSR_output[0]),
.SEL_1 (SEL_1),
.OUT (MUX_1_OUT)
);


///********************************************************///
////////////////// Mux 2 of Lanes output /////////////////////
///********************************************************///

Lanes_MUX U0_Lanes_MUX (
.IN_0 (Active_Lanes), 
.IN_1 (PerLaneID_Lanes),
.SEL_2 (SEL_2),
.OUT (MUX_2_OUT)
);


///********************************************************///
/////////////////////// Valid Serializer /////////////////////
///********************************************************///

Serializer U0_Serializer ( 
.MB_CLK (MB_CLK), 
.SER_EN (main_vld_Ser_En),
.DATA (MUX_1_OUT), 
.SER_OUT (TVLD_P)
);


///********************************************************///
/////////////////////// Lane 0 output ////////////////////
///********************************************************///

Lane_TOP #( .LFSR_WIDTH(LFSR_WIDTH_TOP), .LFSR_Seed(LFSR_Seed_TOP)) U0_Lane_TOP ( 
.MB_CLK (MB_CLK),
.DATA_IN (MUX_2_OUT[0]),
.SER_EN (LANE_SER_Enable),
.PN_EN (PN_EN), 
.Scramble_EN (Scramble_EN),
.RST_n (RST_n),
.Opcode_Synch (Opcode_Synch),
.DATA_OUT (TD_L[0]),              // Connect module output to intermediate wire
.Valid_LFSR_output (Valid_LFSR_output[0]),
.VLD_SER_Enable (VLD_SER_Enable[3])
);


///********************************************************///
/////////////////////// Lane 1 output ////////////////////
///********************************************************///

Lane_TOP #( .LFSR_WIDTH(LFSR_WIDTH_TOP), .LFSR_Seed(23'h0607BB)) U1_Lane_TOP ( 
.MB_CLK (MB_CLK),
.DATA_IN (MUX_2_OUT[1]),
.SER_EN (LANE_SER_Enable),
.PN_EN (PN_EN), 
.Scramble_EN (Scramble_EN),
.RST_n (RST_n),
.Opcode_Synch (Opcode_Synch),
.DATA_OUT (TD_L[1]),
.Valid_LFSR_output (Valid_LFSR_output[1]),
.VLD_SER_Enable (VLD_SER_Enable[4])
);


///********************************************************///
/////////////////////// Lane 2 output ////////////////////
///********************************************************///

Lane_TOP #( .LFSR_WIDTH(LFSR_WIDTH_TOP), .LFSR_Seed(23'h1EC760)) U2_Lane_TOP ( 
.MB_CLK (MB_CLK),
.DATA_IN (MUX_2_OUT[2]),
.SER_EN (LANE_SER_Enable),
.PN_EN (PN_EN), 
.Scramble_EN (Scramble_EN),
.RST_n (RST_n),
.Opcode_Synch (Opcode_Synch),
.DATA_OUT (TD_L[2]),
.Valid_LFSR_output (Valid_LFSR_output[2]),
.VLD_SER_Enable (VLD_SER_Enable[5])
);


///********************************************************///
/////////////////////// Lane 3 output ////////////////////
///********************************************************///

Lane_TOP #( .LFSR_WIDTH(LFSR_WIDTH_TOP), .LFSR_Seed(23'h18C0DB)) U3_Lane_TOP ( 
.MB_CLK (MB_CLK),
.DATA_IN (MUX_2_OUT[3]),
.SER_EN (LANE_SER_Enable),
.PN_EN (PN_EN), 
.Scramble_EN (Scramble_EN),
.RST_n (RST_n),
.Opcode_Synch (Opcode_Synch),
.DATA_OUT (TD_L[3]),
.Valid_LFSR_output (Valid_LFSR_output[3]),
.VLD_SER_Enable (VLD_SER_Enable[6])
);


///********************************************************///
/////////////////////// Lane 4 output ////////////////////
///********************************************************///

Lane_TOP #( .LFSR_WIDTH(LFSR_WIDTH_TOP), .LFSR_Seed(23'h010F12)) U4_Lane_TOP ( 
.MB_CLK (MB_CLK),
.DATA_IN (MUX_2_OUT[4]),
.SER_EN (LANE_SER_Enable),
.PN_EN (PN_EN), 
.Scramble_EN (Scramble_EN),
.RST_n (RST_n),
.Opcode_Synch (Opcode_Synch),
.DATA_OUT (TD_L[4]),
.Valid_LFSR_output (Valid_LFSR_output[4]),
.VLD_SER_Enable (VLD_SER_Enable[7])
);


///********************************************************///
/////////////////////// Lane 5 output ////////////////////
///********************************************************///

Lane_TOP #( .LFSR_WIDTH(LFSR_WIDTH_TOP), .LFSR_Seed(23'h19CFC9)) U5_Lane_TOP ( 
.MB_CLK (MB_CLK),
.DATA_IN (MUX_2_OUT[5]),
.SER_EN (LANE_SER_Enable),
.PN_EN (PN_EN), 
.Scramble_EN (Scramble_EN),
.RST_n (RST_n),
.Opcode_Synch (Opcode_Synch),
.DATA_OUT (TD_L[5]),
.Valid_LFSR_output (Valid_LFSR_output[5]),
.VLD_SER_Enable (VLD_SER_Enable[8])
);


///********************************************************///
/////////////////////// Lane 6 output ////////////////////
///********************************************************///

Lane_TOP #( .LFSR_WIDTH(LFSR_WIDTH_TOP), .LFSR_Seed(23'h0277CE)) U6_Lane_TOP ( 
.MB_CLK (MB_CLK),
.DATA_IN (MUX_2_OUT[6]),
.SER_EN (LANE_SER_Enable),
.PN_EN (PN_EN), 
.Scramble_EN (Scramble_EN),
.RST_n (RST_n),
.Opcode_Synch (Opcode_Synch),
.DATA_OUT (TD_L[6]),
.Valid_LFSR_output (Valid_LFSR_output[6]),
.VLD_SER_Enable (VLD_SER_Enable[9])
);


///********************************************************///
/////////////////////// Lane 7 output ////////////////////
///********************************************************///

Lane_TOP #( .LFSR_WIDTH(LFSR_WIDTH_TOP), .LFSR_Seed(23'h1BB807)) U7_Lane_TOP ( 
.MB_CLK (MB_CLK),
.DATA_IN (MUX_2_OUT[7]),
.SER_EN (LANE_SER_Enable),
.PN_EN (PN_EN), 
.Scramble_EN (Scramble_EN),
.RST_n (RST_n),
.Opcode_Synch (Opcode_Synch),
.DATA_OUT (TD_L[7]),
.Valid_LFSR_output (Valid_LFSR_output[7]),
.VLD_SER_Enable (VLD_SER_Enable[10])
);


///********************************************************///
/////////////////////// Lane 8 output ////////////////////
///********************************************************///

Lane_TOP #( .LFSR_WIDTH(LFSR_WIDTH_TOP), .LFSR_Seed(23'h1DBFBC)) U8_Lane_TOP ( 
.MB_CLK (MB_CLK),
.DATA_IN (MUX_2_OUT[8]),
.SER_EN (LANE_SER_Enable),
.PN_EN (PN_EN), 
.Scramble_EN (Scramble_EN),
.RST_n (RST_n),
.Opcode_Synch (Opcode_Synch),
.DATA_OUT (TD_L[8]),
.Valid_LFSR_output (Valid_LFSR_output[8]),
.VLD_SER_Enable (VLD_SER_Enable[11])
);


///********************************************************///
/////////////////////// Lane 9 output ////////////////////
///********************************************************///

Lane_TOP #( .LFSR_WIDTH(LFSR_WIDTH_TOP), .LFSR_Seed(23'h0607BB)) U9_Lane_TOP ( 
.MB_CLK (MB_CLK),
.DATA_IN (MUX_2_OUT[9]),
.SER_EN (LANE_SER_Enable),
.PN_EN (PN_EN), 
.Scramble_EN (Scramble_EN),
.RST_n (RST_n),
.Opcode_Synch (Opcode_Synch),
.DATA_OUT (TD_L[9]),
.Valid_LFSR_output (Valid_LFSR_output[9]),
.VLD_SER_Enable (VLD_SER_Enable[12])
);


///********************************************************///
/////////////////////// Lane 10 output ////////////////////
///********************************************************///

Lane_TOP #( .LFSR_WIDTH(LFSR_WIDTH_TOP), .LFSR_Seed(23'h1EC760)) U10_Lane_TOP ( 
.MB_CLK (MB_CLK),
.DATA_IN (MUX_2_OUT[10]),
.SER_EN (LANE_SER_Enable),
.PN_EN (PN_EN), 
.Scramble_EN (Scramble_EN),
.RST_n (RST_n),
.Opcode_Synch (Opcode_Synch),
.DATA_OUT (TD_L[10]),
.Valid_LFSR_output (Valid_LFSR_output[10]),
.VLD_SER_Enable (VLD_SER_Enable[13])
);


///********************************************************///
/////////////////////// Lane 11 output ////////////////////
///********************************************************///

Lane_TOP #( .LFSR_WIDTH(LFSR_WIDTH_TOP), .LFSR_Seed(23'h18C0DB)) U11_Lane_TOP ( 
.MB_CLK (MB_CLK),
.DATA_IN (MUX_2_OUT[11]),
.SER_EN (LANE_SER_Enable),
.PN_EN (PN_EN), 
.Scramble_EN (Scramble_EN),
.RST_n (RST_n),
.Opcode_Synch (Opcode_Synch),
.DATA_OUT (TD_L[11]),
.Valid_LFSR_output (Valid_LFSR_output[11]),
.VLD_SER_Enable (VLD_SER_Enable[14])
);


///********************************************************///
/////////////////////// Lane 12 output ////////////////////
///********************************************************///

Lane_TOP #( .LFSR_WIDTH(LFSR_WIDTH_TOP), .LFSR_Seed(23'h010F12)) U12_Lane_TOP ( 
.MB_CLK (MB_CLK),
.DATA_IN (MUX_2_OUT[12]),
.SER_EN (LANE_SER_Enable),
.PN_EN (PN_EN), 
.Scramble_EN (Scramble_EN),
.RST_n (RST_n),
.Opcode_Synch (Opcode_Synch),
.DATA_OUT (TD_L[12]),
.Valid_LFSR_output (Valid_LFSR_output[12]),
.VLD_SER_Enable (VLD_SER_Enable[15])
);


///********************************************************///
/////////////////////// Lane 13 output ////////////////////
///********************************************************///

Lane_TOP #( .LFSR_WIDTH(LFSR_WIDTH_TOP), .LFSR_Seed(23'h19CFC9)) U13_Lane_TOP ( 
.MB_CLK (MB_CLK),
.DATA_IN (MUX_2_OUT[13]),
.SER_EN (LANE_SER_Enable),
.PN_EN (PN_EN), 
.Scramble_EN (Scramble_EN),
.RST_n (RST_n),
.Opcode_Synch (Opcode_Synch),
.DATA_OUT (TD_L[13]),
.Valid_LFSR_output (Valid_LFSR_output[13]),
.VLD_SER_Enable (VLD_SER_Enable[16])
);


///********************************************************///
/////////////////////// Lane 14 output ////////////////////
///********************************************************///

Lane_TOP #( .LFSR_WIDTH(LFSR_WIDTH_TOP), .LFSR_Seed(23'h0277CE)) U14_Lane_TOP ( 
.MB_CLK (MB_CLK),
.DATA_IN (MUX_2_OUT[14]),
.SER_EN (LANE_SER_Enable),
.PN_EN (PN_EN), 
.Scramble_EN (Scramble_EN),
.RST_n (RST_n),
.Opcode_Synch (Opcode_Synch),
.DATA_OUT (TD_L[14]),
.Valid_LFSR_output (Valid_LFSR_output[14]),
.VLD_SER_Enable (VLD_SER_Enable[17])
);


///********************************************************///
/////////////////////// Lane 15 output ////////////////////
///********************************************************///

Lane_TOP #( .LFSR_WIDTH(LFSR_WIDTH_TOP), .LFSR_Seed(23'h1BB807)) U15_Lane_TOP ( 
.MB_CLK (MB_CLK),
.DATA_IN (MUX_2_OUT[15]),
.SER_EN (LANE_SER_Enable),
.PN_EN (PN_EN), 
.Scramble_EN (Scramble_EN),
.RST_n (RST_n),
.Opcode_Synch (Opcode_Synch),
.DATA_OUT (TD_L[15]),
.Valid_LFSR_output (Valid_LFSR_output[15]),
.VLD_SER_Enable (VLD_SER_Enable[18])
);


endmodule