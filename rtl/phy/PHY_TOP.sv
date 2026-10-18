import Universal_pkg ::* ; 

module PHY_TOP #(
                parameter NC=32,
                parameter NUM_LANES=16,
                parameter LFSR_WIDTH_TOP = 23,         // Width of the LFSR
                parameter LFSR_Seed_TOP  = 23'h1DBFBC,
                parameter DATA_WIDTH_TOP = 64,   // Width of data in FIFO
                parameter FIFO_DEPTH_TOP = 4,   // FIFO's depth (must be power of 2)
                parameter DATA_SIZE_TOP  = 2,   // Gray Synchronizer Data Size
                parameter FRAME_LENGTH   = 8,
                parameter W_D_SIZE       = 128
)
(top_if.top phy_if);


    //----------------Inistantiate Controller & SB--------------//

    Controller_SB_Top #(.NC(NC),.DATA_WIDTH(DATA_WIDTH_TOP),.NUM_LANES(NUM_LANES)) Controller_SB_Top_U0
    (phy_if);

    //------------------Inistantiate LTSM------------------------//

    LTSM LTSM_U0  (phy_if);


    //----------------------MB----------------------//
    MB_TOP #( .LFSR_WIDTH_TOP(LFSR_WIDTH_TOP), .LFSR_Seed_TOP(LFSR_Seed_TOP),
              .DATA_WIDTH_TOP(DATA_WIDTH_TOP), .FIFO_DEPTH_TOP(FIFO_DEPTH_TOP),
              .DATA_SIZE_TOP(DATA_SIZE_TOP),   .FRAME_LENGTH_TOP(FRAME_LENGTH)) U0_MB_TOP (phy_if);


endmodule
