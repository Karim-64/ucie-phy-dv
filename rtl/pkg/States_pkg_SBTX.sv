
package states_pkg_SBTX;

    // General Parameters
    parameter PATTERN_CYCLES = 4;
    parameter TIMER_CYCLES = 8;
   
    // Source and Destination IDs for PHY communication
    parameter SRC_ID  = 3'b010;  // PHY Source ID
    parameter DST_ID  = 3'b110;  // PHY Destination ID

    // SBINIT_out_of_Reset Message Field Parameters (Total = 64 bits)
    // Using the 'Message_Without_Data' from OPCODE_pkg
    parameter SBINIT_OPCODE    = 5'b10010; 
    parameter SBINIT_CP        = 1'b0;         // Control Parity
    parameter SBINIT_DP        = 1'b0;         // Data Parity
    parameter SBINIT_MSGCODE   = 8'h91;  // Message Code
    parameter SBINIT_SUBCODE   = 8'b0;         // Message Subcode
    parameter SBINIT_MSGINFO   = 16'b1;        // Message Info (bits[3:0] reserved for no Redundant lanes)
    parameter SBINIT_RESERVED0 = 3'b0;         // Reserved Bits
    parameter SBINIT_RESERVED1 = 7'b0;         // Reserved Bits
    parameter SBINIT_RESERVED2 = 9'b0;         // Reserved Bits

    // 64-bit Message Construction (SBINIT)
    parameter SBINIT_out_of_Reset_Message = {
        SBINIT_DP,               // [63]
        SBINIT_CP,               // [62]
        SBINIT_RESERVED0,        // [61:59]
        DST_ID,                  // [58:56]
        SBINIT_MSGINFO,          // [55:40]
        SBINIT_SUBCODE,          // [39:32]
        SRC_ID,                  // [31:29]
        SBINIT_RESERVED1,        // [28:22]
        SBINIT_MSGCODE,          // [21:14]
        SBINIT_RESERVED2,        // [13:5]
        SBINIT_OPCODE            // [4:0]
    };

    typedef enum logic [2:0] { 
       RESET       = 3'b000,   SBINIT      = 3'b001,
       MBINIT      = 3'b010,   MBTRAIN  = 3'b011,
       LINKINIT    = 3'b100,   ACTIVE      = 3'b101,
       PHYRETRAIN  = 3'b110,   TRAINERROR  = 3'b111
    } LTSM_state;
    
    typedef enum logic [2:0] { 
       PARAM       = 3'b000,   CAL      = 3'b001,
       REPAIRCLK   = 3'b010,   REPAIRVAL   = 3'b011,
       REVERSALMB  = 3'b100,   REPAIRMB    = 3'b101
    } MBINIT_states;     
     
    typedef enum logic [3:0] {
       VALVREF        = 4'b0000,  DATAVREF          = 4'b0001,
       SPEEDIDLE         = 4'b0010,  TXSELFCAL         = 4'b0011,
       RXCLKCAL          = 4'b0100,  VALTRAINCENTER       = 4'b0101,
       VALTRAINVREF      = 4'b0110,  DATATRAINCENTER1  = 4'b0111,
       DATATRAINVREF     = 4'b1000,  RXDESKEW          = 4'b1001,
       DATATRAINCENTER2  = 4'b1010,  LINKSPEED         = 4'b1011,
       REPAIR            = 4'b1100
    } MBTRAIN_states;
    
    // State Machine Definition
    typedef enum logic [1:0] {
        RESET_SBINIT  = 2'b00,  // Reset State
        Active        = 2'b01,  // Active State
        Other_State   = 2'b10   // Other States
    } States;

endpackage
