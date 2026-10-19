package states_pkg_MB;

parameter WIDTH_DEGRADE_LENGTH=3;
parameter ERROR_THRESHOLD_LENGTH=16;
parameter CHUNK_LENGTH=3;

parameter NUM_LANES=16;
parameter W_D_SIZE= 128;

parameter Least_Sig_Lanes=3'b001;
parameter Most_Sig_Lanes=3'b010;
parameter All_Lanes=3'b011;

parameter Valid_Frame          = 8'b00001111;      // usual Valid Frame
parameter Cons_Iterations      = 16         ;      // # of consecutive iterations to indicate successful detection
parameter Total_Iterations     = 128        ;      // # of max. iterations for training  

parameter Suff_Frames=16                   ; // number of sufficient correct frames to indicate the lane is functional
parameter Iteration_Count_Lane_ID=128      ; // number of Iterations of Lane_ID test
parameter Iteration_Count_LFSR=4096        ; // number of Iterations of LFSR test
parameter Pattern_Length=16                ; // the Lane_ID is a 16 bit pattern

typedef enum logic [4:0] {
    _RESET                    = 5'b00000,
    _SBINIT                   = 5'b00001,
    _MBINIT_PARAM             = 5'b00010,
    _MBINIT_CAL               = 5'b00011,
    _MBINIT_REPAIRCLK         = 5'b00100,
    _MBINIT_REPAIRVAL         = 5'b00101,
    _MBINIT_REVERSALMB        = 5'b00110,
    _MBINIT_REPAIRMB          = 5'b00111,
    _MBTRAIN_VALVREF          = 5'b01000,
    _MBTRAIN_DATAVREF         = 5'b01001,
    _MBTRAIN_SPEEDIDLE        = 5'b01010,
    _MBTRAIN_TXSELFCAL        = 5'b01011,
    _MBTRAIN_RXCLKCAL         = 5'b01100,
    _MBTRAIN_VALTRAINCENTER   = 5'b01101,
    _MBTRAIN_VALTRAINVREF     = 5'b01110,
    _MBTRAIN_DATATRAINCENTER1 = 5'b01111,
    _MBTRAIN_DATATRAINVREF    = 5'b10000,
    _MBTRAIN_RXDESKEW         = 5'b10001,
    _MBTRAIN_DATATRAINCENTER2 = 5'b10010,
    _MBTRAIN_LINKSPEED        = 5'b10011,
    _MBTRAIN_REPAIR           = 5'b10100,
    _LINKINIT                 = 5'b10101,   
    _ACTIVE                   = 5'b10110,
    _PHYRETRAIN               = 5'b10111,   
    _TRAINERROR               = 5'b11000    
} LTSM_states;

   
   parameter MS_TO_CLK = 1;
endpackage

