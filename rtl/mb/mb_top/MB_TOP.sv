import Universal_pkg ::* ; 

//implementing the Main Band Top module

module MB_TOP #( parameter LFSR_WIDTH_TOP   = 23,   // Width of the LFSR
                 parameter LFSR_Seed_TOP    = 23'h1DBFBC,
                 parameter DATA_WIDTH_TOP   = 64,   // Width of data in FIFO
                 parameter FIFO_DEPTH_TOP   = 4 ,   // FIFO's depth (must be power of 2)
                 parameter DATA_SIZE_TOP    = 2 ,   // Gray Synchronizer Data Size
                 parameter FRAME_LENGTH_TOP = 8 
                 

)(top_if IF);

 //___________________________________________________________________________________________________________
logic [4:0] mb_op;
logic [4:0] Opcode_Sync;
assign mb_op = IF.mb_op ;
assign IF.Opcode_Sync = LTSM_states'( Opcode_Sync);

//___________________________________________________________________________________________________________

Gray_Synchronizer_SBTX  #(.DATA_SIZE(5)) Gray_Synchronizer_LTSM_OPCODE
(
 .CLK(IF.mbclk), 
 .RST_n(IF.RST_n), 
 .Async_Data(mb_op), 
 .Sync_Data(Opcode_Sync)
);


///********************************************************///
/////////////////////// MB_TX //////////////////////////////// 
///********************************************************///

MB_TX_TOP #( .LFSR_WIDTH_TOP(LFSR_WIDTH_TOP), 
             .LFSR_Seed_TOP(LFSR_Seed_TOP),
             .DATA_WIDTH_TOP(DATA_WIDTH_TOP), 
             .FIFO_DEPTH_TOP(FIFO_DEPTH_TOP),
             .DATA_SIZE_TOP(DATA_SIZE_TOP) ) U0_MB_TX_TOP (IF.mbtx);


///********************************************************///
////////////////MB_RX_Inputs_Synchronizers////////////////// 
///********************************************************///


Level_Sync_SBTX    Level_Sync_Width_Degrade_Update (
.CLK(IF.mbclk), 
.RST_n(IF.RST_n), 
.Async_Signal(IF.Width_Update), 
.Sync_Signal(IF.Width_Degrade_Update_Sync)
);

Level_Sync_SBTX    Level_Sync_Test_Resp (
.CLK(IF.mbclk), 
.RST_n(IF.RST_n), 
.Async_Signal(IF.Test_Resp_Sync), 
.Sync_Signal(IF.Test_Resp_mb_Sync)
);


// Width_Update & Error_Threshold are enable-synchronised

//************************************************************//


///********************************************************///
/////////////////////// MB_RX //////////////////////////////// 
///********************************************************///

MB_RX # (.FRAME_LENGTH(FRAME_LENGTH_TOP), 
         .LFSR_WIDTH(LFSR_WIDTH_TOP), 
         .R_D_SIZE_Bytes(DATA_WIDTH_TOP))  U0_MB_RX  (IF.mbrx);



endmodule

