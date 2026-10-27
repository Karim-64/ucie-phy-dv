package Universal_pkg ;

parameter SRC_ID_LENGTH        = 3;
parameter DST_ID_LENGTH        = 3;
parameter TAG_LENGTH           = 5;
parameter STATUS_LENGTH        = 3;
parameter OPCODE_LENGTH        = 5;
parameter BE_LENGTH            = 8;
parameter ADDR_LENGTH          = 24;
parameter MSGCODE_LENGTH       = 8;

parameter opcode_offset        = 0;
parameter be_offset            = 14;
parameter tag_offset           = 22;
parameter status_offset        = 32;
parameter addr_offset          = 32;
parameter srcid_offset         = 29;
parameter dst_id_offset_32     = 24;
parameter dst_id_offset_64     = 56;
parameter cp_offset_32         = 30;
parameter dp_offset_32         = 31;
parameter cp_offset_64         = 62;
parameter dp_offset_64         = 63;
parameter msgcode_offset       = 14;
bit disable_compare;
bit request_pending ; 

parameter Remote_Terminated_Request = 1'b1;
parameter CHUNK_WIDTH = 32 ,ADDR_WIDTH=24;

typedef enum logic [4:0] {
    Memory_Read_32b            = 5'b00000,
    Memory_Write_32b           = 5'b00001,
    DMS_Register_Read_32b      = 5'b00010,
    DMS_Register_Write_32b     = 5'b00011,
    Configuration_Read_32b     = 5'b00100,
    Configuration_Write_32b    = 5'b00101,     
    Memory_Read_64b            = 5'b01000,
    Memory_Write_64b           = 5'b01001,
    DMS_Register_Read_64b      = 5'b01010,
    DMS_Register_Write_64b     = 5'b01011,
    Configuration_Read_64b     = 5'b01100,
    Configuration_Write_64b    = 5'b01101,
    Completion_Without_Data    = 5'b10000,
    Completion_With_32b_Data   = 5'b10001,
    Completion_With_64b_Data   = 5'b11001,
    Message_Without_Data       = 5'b10010,
    Message_With_64b_Data      = 5'b11011,
    MPM_Without_Data           = 5'b10111,
    MPM_With_Data              = 5'b11000 
} OPCODES;

typedef enum logic [7:0] {
    RDI_LINK_MANAGEMENT_REQ    = 8'h01,
    RDI_LINK_MANAGEMENT_RESP   = 8'h02,
    D2D0_LINK_MANAGEMENT_REQ   = 8'h03,
    D2D0_LINK_MANAGEMENT_RESP  = 8'h04,
    D2D1_LINK_MANAGEMENT_REQ   = 8'h05,
    D2D1_LINK_MANAGEMENT_RESP  = 8'h06,
    D2D_Parity_Feature_Req     = 8'h07         
} MSGCODES;

typedef enum logic [2:0] {
    SC    = 3'b000,
    UR    = 3'b001,
    CA    = 3'b100,
    Stall = 3'b111
} Comp_Status;

parameter DATA_WIDTH = 64;

parameter MS_TO_CLK = 1_000; ///////////////
parameter MS_TO_CLK_RST = 1; ///////////////

parameter SB_CLK_FREQ_HZ = 800_000_000 ; 
parameter SB_FACTOR = 1000 ; 

typedef enum logic [2:0] { 
   RESET       = 3'b000,   SBINIT      = 3'b001,
   MBINIT      = 3'b010,   MBTRAIN  = 3'b011,
   LINKINIT    = 3'b100,   ACTIVE      = 3'b101,
   PHYRETRAIN  = 3'b110,   TRAINERROR  = 3'b111
} LTSM_state;

typedef enum bit [2:0] { 
    PARAM        = 3'b000,     
    CAL          = 3'b001,
    REPAIRCLK    = 3'b010,   
    REPAIRVAL    = 3'b011,
    REVERSALMB   = 3'b100,   
    REPAIRMB     = 3'b101
} MBINIT_states;      

typedef enum bit [3:0] {
    VALVREF            = 4'b0000,  
    DATAVREF           = 4'b0001,
    SPEEDIDLE          = 4'b0010,    
    TXSELFCAL          = 4'b0011,
    RXCLKCAL           = 4'b0100,     
    VALTRAINCENTER     = 4'b0101,
    VALTRAINVREF       = 4'b0110,     
    DATATRAINCENTER1   = 4'b0111,
    DATATRAINVREF      = 4'b1000,  
    RXDESKEW           = 4'b1001,
    DATATRAINCENTER2   = 4'b1010,     
    LINKSPEED          = 4'b1011,
    REPAIR             = 4'b1100
} MBTRAIN_states;  

typedef enum bit [3:0] {
    Nop         = 4'b0000, 
    Active      = 4'b0001,
    LinkReset   = 4'b1001, 
    Retrain     = 4'b1011,
    Disable     = 4'b1100, 
    LinkError   = 4'b1010
} RDI_states;

typedef enum logic [1:0] {IDLE, STALL_REQ, STALL_ACK, STALL_DONE} phase_t;

// Parameters for msgcode
parameter logic [7:0] 
    req = 8'h01,
    rsp = 8'h02;
// rsvd[61:59]_dstid[58:56]_msginfo[55:40]_msgsubcode[39:32]_srcid[31:29]_rsvd[28:22]_msgcode[21:14]_rsvd[13:5]_opcode[4:0]
// {3'b0, 3'b_dstid, 16'b_msginfo, 8'b_msgsubcode, 3'b_srcid, 7'b0, 8'b_msgcode, 9'b0, 5'b_opcode}  

parameter logic [1:0]
    D2D = 2'b01,
    PHY = 2'b10,
    MPG = 2'b11;

// Parameters for msgsubcode
parameter logic [7:0] 
    nop_crd_reserved    = 8'h00, // Reserved for NOP CRD
    rdi_active          = 8'h01, // Active Request for RDI SM
    // rdi_l1           = 8'h04, // L1 Request for RDI SM
    // rdi_l2           = 8'h08, // L2 Request for RDI SM
    rdi_linkreset       = 8'h09, // Link Reset Request for RDI SM
    rdi_linkerror       = 8'h0A, // Link Error Request for RDI SM
    rdi_retrain         = 8'h0B, // Retrain Request for RDI SM
    rdi_disable         = 8'h0C; // Disable Request for RDI SM

bit [7:0] [4:0] rdi_msg_subcodes = {
    rdi_active,
    // rdi_l1,
    // rdi_l2,
    rdi_linkreset,
    rdi_linkerror,
    rdi_retrain,
    rdi_disable
};

parameter bit [61:0]   
    LINK_MGMT_RDI_REQ_ACTIVE     = {1'b0,1'b0,3'b110,16'h0000,rdi_active,3'b010,7'h00,8'h01,9'h000,5'b10010},
    LINK_MGMT_RDI_RSP_ACTIVE     = {1'b0,1'b0,3'b110,16'h0000,rdi_active,3'b010,7'h00,8'h02,9'h000,5'b10010},
    // LINK_MGMT_RDI_REQ_L1      = {1'b0,1'b1,3'b110,16'h0000,rdi_l1,3'b010,7'h00,8'h01,9'h000,5'b10010},
    // LINK_MGMT_RDI_RSP_L1      = {1'b0,1'b1,3'b110,16'h0000,rdi_l1,3'b010,7'h00,8'h02,9'h000,5'b10010},
    // LINK_MGMT_RDI_REQ_L2      = {1'b0,1'b1,3'b110,16'h0000,rdi_l2,3'b010,7'h00,8'h01,9'h000,5'b10010},
    // LINK_MGMT_RDI_RSP_L2      = {1'b0,1'b1,3'b110,16'h0000,rdi_l2,3'b010,7'h00,8'h02,9'h000,5'b10010},   
    LINK_MGMT_RDI_REQ_LINKRESET  = {1'b0,1'b0,3'b110,16'h0000,rdi_linkreset,3'b010,7'h00,8'h01,9'h000,5'b10010},
    LINK_MGMT_RDI_RSP_LINKRESET  = {1'b0,1'b0,3'b110,16'h0000,rdi_linkreset,3'b010,7'h00,8'h02,9'h000,5'b10010},
    LINK_MGMT_RDI_REQ_LINKERROR  = {1'b0,1'b0,3'b110,16'h0000,rdi_linkerror,3'b010,7'h00,8'h01,9'h000,5'b10010},
    LINK_MGMT_RDI_RSP_LINKERROR  = {1'b0,1'b0,3'b110,16'h0000,rdi_linkerror,3'b010,7'h00,8'h02,9'h000,5'b10010},
    LINK_MGMT_RDI_REQ_RETRAIN    = {1'b0,1'b0,3'b110,16'h0000,rdi_retrain,3'b010,7'h00,8'h01,9'h000,5'b10010},
    LINK_MGMT_RDI_RSP_RETRAIN    = {1'b0,1'b0,3'b110,16'h0000,rdi_retrain,3'b010,7'h00,8'h02,9'h000,5'b10010},
    LINK_MGMT_RDI_REQ_DISABLE    = {1'b0,1'b0,3'b110,16'h0000,rdi_disable,3'b010,7'h00,8'h01,9'h000,5'b10010},
    LINK_MGMT_RDI_RSP_DISABLE    = {1'b0,1'b0,3'b110,16'h0000,rdi_disable,3'b010,7'h00,8'h02,9'h000,5'b10010},
    NULL                        = 62'hFFFF_FFFF_FFFF_FFFF; // 64'b

bit [61:0]  req_msgs [4:0] = {
    LINK_MGMT_RDI_REQ_ACTIVE,
    LINK_MGMT_RDI_REQ_LINKRESET,
    LINK_MGMT_RDI_REQ_LINKERROR,
    LINK_MGMT_RDI_REQ_RETRAIN,
    LINK_MGMT_RDI_REQ_DISABLE
};
bit [61:0]  rsp_msgs [4:0] = {
    LINK_MGMT_RDI_RSP_ACTIVE,
    LINK_MGMT_RDI_RSP_LINKRESET,
    LINK_MGMT_RDI_RSP_LINKERROR,
    LINK_MGMT_RDI_RSP_RETRAIN,
    LINK_MGMT_RDI_RSP_DISABLE
};
bit [61:0]  all_msgs [9:0] = {
    LINK_MGMT_RDI_REQ_ACTIVE,
    LINK_MGMT_RDI_RSP_ACTIVE,
    // LINK_MGMT_RDI_REQ_L1,
    // LINK_MGMT_RDI_RSP_L1,
    // LINK_MGMT_RDI_REQ_L2,
    // LINK_MGMT_RDI_RSP_L2,
    LINK_MGMT_RDI_REQ_LINKRESET,
    LINK_MGMT_RDI_RSP_LINKRESET,
    LINK_MGMT_RDI_REQ_LINKERROR,
    LINK_MGMT_RDI_RSP_LINKERROR,
    LINK_MGMT_RDI_REQ_RETRAIN,
    LINK_MGMT_RDI_RSP_RETRAIN,
    LINK_MGMT_RDI_REQ_DISABLE,
    LINK_MGMT_RDI_RSP_DISABLE
  };

//MsgCode
typedef enum logic [7:0] {
                          resp_tests       = 8'h 8A,
                          req_tests        = 8'h 85,
                          resp_sb          = 8'h 9A,
                          req_sb           = 8'h 95,
                          sb_done          = 8'h 91,
                          resp_MBINIT      = 8'h AA,
                          req_MBINIT       = 8'h A5,
                          req_MBTRAIN      = 8'h B5,
                          resp_MBTRAIN     = 8'h BA,
                          sweep_done       = 8'h 81,
                          nop_credit       = 8'h 00,
                          lnkmgmt_req      = 8'h 01,
                          lnkmgmt_resp     = 8'h 02,
                          lnkmgmnt_adp0_req= 8'h 03,
                          lnkmgmt_adp0_rsp = 8'h 04,
                          lnkmgmnt_adp1_req= 8'h 05,
                          lnkmgmt_adp1_rsp = 8'h 06, 
                          ParityFeature_Req= 8'h 07,
                          ParityFeature    = 8'h 08,
                          PHYRETRAIN_req   = 8'h c5,
                          PHYRETRAIN_resp  = 8'h CA,
                          TRAINERROR_req   = 8'h E5,
                          TRAINERROR_resp  = 8'h EA,
                          RECAL_req        = 8'h D5,
                          RECAL_resp       = 8'h DA,
                          err_msg          = 8'h 09,
                          vendor_defined   = 8'h FF
                        } msgcode_e;

typedef enum logic [23:0] { 
          Start_Tx_Init_D_to_C_point_test = 24'h 0000_01,
          LFSR_clear_error                = 24'h 0000_02,
          Tx_Init_D_to_C_results          = 24'h 0000_03,
          End_Tx_Init_D_to_C_point_test   = 24'h 0000_04,
          Start_Tx_Init_D_to_C_eye_sweep  = 24'h 0000_05,
          End_Tx_Init_D_to_C_eye_sweep    = 24'h 0000_06,
          Start_Rx_Init_D_to_C_point_test = 24'h 0000_07,
          Rx_Init_D_to_C_Tx_Count_Done    = 24'h 0000_08,
          End_Rx_Init_D_to_C_point_test   = 24'h 0000_09,
          Start_Rx_Init_D_to_C_eye_sweep  = 24'h 0000_0A,
          Rx_Init_D_to_C_results          = 24'h 0000_0B,
          End_Rx_Init_D_to_C_eye_sweep    = 24'h 0000_0D
                           }msgsub_msginfo_enum1;
typedef  enum logic [23:0] {
          SBINIT_done                      = 24'h 0000_01,
          SBINIT_out_of_Reset              = 24'h 0001_00
                           }sbinit_msgcode_msginfo;
typedef enum logic [23:0] {
          MBTRAIN_VALVREF_start             =  24'h 000000,
          MBTRAIN_VALVREF_end               =  24'h 0000_01,
          MBTRAIN_DATAVREF_start            =  24'h 0000_02,
          MBTRAIN_DATAVREF_end              =  24'h 0000_03,
          MBTRAIN_SPEEDIDLE_done            =  24'h 0000_04,
          MBTRAIN_TXSELFCAL_Done            =  24'h 0000_05,
          MBTRAIN_RXCLKCAL_start            =  24'h 0000_06,
          MBTRAIN_RXCLKCAL_done             =  24'h 0000_07,
          MBTRAIN_VALTRAINCENTER_start      =  24'h 0000_08,
          MBTRAIN_VALTRAINCENTER_done       =  24'h 0000_09,
          MBTRAIN_VALTRAINVREF_start        =  24'h 0000_0A,
          MBTRAIN_VALTRAINVREF_done         =  24'h 0000_0B,
          MBTRAIN_DATATRAINCENTER1_start    =  24'h 0000_0C,
          MBTRAIN_DATATRAINCENTER1_end      =  24'h 0000_0D,
          MBTRAIN_DATATRAINVREF_start       =  24'h 0000_0E,
          MBTRAIN_DATATRAINVREF_end         =  24'h 0000_10,
          MBTRAIN_RXDESKEW_start            =  24'h 0000_11,
          MBTRAIN_RXDESKEW_end              =  24'h 0000_12,
          MBTRAIN_DATATRAINCENTER2_start    =  24'h 0000_13,
          MBTRAIN_DATATRAINCENTER2_end      =  24'h 0000_14
                           } msgsub_msginfo_enum2;

typedef union packed{
               msgsub_msginfo_enum1 msgsubmsginfo1 ;
               msgsub_msginfo_enum2 msgsubmsginfo2 ;
               sbinit_msgcode_msginfo msgsubmsginfo3;
              } msgsub_msginfo_union;


 
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
        parameter SBINIT_out_of_Reset_Message = 64'h0600010000244012 ; 

        // parameter SBINIT_out_of_Reset_Message = { 
        //     SBINIT_DP,               // [63]
        //     SBINIT_CP,               // [62]
        //     SBINIT_RESERVED0,        // [61:59]
        //     DST_ID,                  // [58:56]
        //     SBINIT_MSGINFO,          // [55:40]
        //     SBINIT_SUBCODE,          // [39:32]
        //     SRC_ID,                  // [31:29]
        //     SBINIT_RESERVED1,        // [28:22]
        //     SBINIT_MSGCODE,          // [21:14]
        //     SBINIT_RESERVED2,        // [13:5]
        //     SBINIT_OPCODE            // [4:0]
        // };

                         
        // State Machine Definition
        typedef enum logic [1:0] {
            RESET_SBINIT  = 2'b10,  // Reset State
            active        = 2'b00,  // Active State
            Other_State   = 2'b01   // Other States
        } States;

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

typedef enum bit [4:0] {
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

OPCODES CRD [] = '{ 
    Memory_Read_32b, Memory_Write_32b, Configuration_Read_32b, Configuration_Write_32b,
    Memory_Read_64b, Memory_Write_64b, Configuration_Read_64b,  Configuration_Write_64b,
    Message_Without_Data, Message_With_64b_Data 
};

OPCODES PHASE [] = '{
    Memory_Write_32b,
    DMS_Register_Write_32b,
    Configuration_Write_32b,
    Memory_Write_64b,
    DMS_Register_Write_64b,
    Configuration_Write_64b,
    Message_With_64b_Data,
    MPM_With_Data, 
    Completion_With_32b_Data,
    Completion_With_64b_Data
};

//Verification Stuff 

bit start_mbtx_compare ; 
bit start_sbrx_compare ; 
bit start_sbtx_compare ; 

bit reset_done , reset_done1 ; 
bit bringup_done , bringup_done1 ; 
bit Active_from_Retrain_done, Active_from_Retrain_done1 ;
bit trainerror_up ;
bit entered_trainerror , entered_trainerror1 ;  
bit valid_corrupt_random_allowed ; 
bit lane_blackout_random_allowed ; 
bit d2d_err ; 
bit random_cycles ; 
bit end_of_seq_sbrx ;
bit end_of_seq_sbtx ;

int rdi_credits ;

 

parameter remote_die = 1'b1;

//dst_id[1:0] 
parameter  dst_D2D  = 2'b01
          ,dst_PHY  = 2'b10;
parameter    
        //   Start_Tx_Init_D_to_C_point_test   = 24'h 0000_01,
        //   LFSR_clear_error                  = 24'h 0000_02,
        //   Tx_Init_D_to_C_results            = 24'h 0000_03,
        //   End_Tx_Init_D_to_C_point_test     = 24'h 0000_04,
        //   Start_Tx_Init_D_to_C_eye_sweep    = 24'h 0000_05,
        //   End_Tx_Init_D_to_C_eye_sweep      = 24'h 0000_06,
        //   Start_Rx_Init_D_to_C_point_test   = 24'h 0000_07,
        //   Rx_Init_D_to_C_Tx_Count_Done      = 24'h 0000_08,
        //   End_Rx_Init_D_to_C_point_test     = 24'h 0000_09,
        //   Start_Rx_Init_D_to_C_eye_sweep    = 24'h 0000_0A,
        //   Rx_Init_D_to_C_results            = 24'h 0000_0B,
        //   End_Rx_Init_D_to_C_eye_sweep      = 24'h 0000_0D,
          TRAINERROR_ENTRY                  =  24'h0,
        //   MBTRAIN_VALVREF_start             =  24'h 000000,
        //   MBTRAIN_VALVREF_end               =  24'h 0000_01,
        //   MBTRAIN_DATAVREF_start            =  24'h 0000_02,
        //   MBTRAIN_DATAVREF_end              =  24'h 0000_03,
        //   MBTRAIN_SPEEDIDLE_done            =  24'h 0000_04,
        //   MBTRAIN_TXSELFCAL_Done            =  24'h 0000_05,
        //   MBTRAIN_RXCLKCAL_start            =  24'h 0000_06,
        //   MBTRAIN_RXCLKCAL_done             =  24'h 0000_07,
        //   MBTRAIN_VALTRAINCENTER_start      =  24'h 0000_08,
        //   MBTRAIN_VALTRAINCENTER_done       =  24'h 0000_09,
        //   MBTRAIN_VALTRAINVREF_start          = 24'h 0000_0A,
        //   MBTRAIN_VALTRAINVREF_done           = 24'h 0000_0B,
        //   MBTRAIN_DATATRAINCENTER1_start      = 24'h 0000_0C,
        //   MBTRAIN_DATATRAINCENTER1_end        = 24'h 0000_0D,
        //   MBTRAIN_DATATRAINVREF_start         = 24'h 0000_0E,
        //   MBTRAIN_DATATRAINVREF_end           = 24'h 0000_10,
        //   MBTRAIN_RXDESKEW_start              = 24'h 0000_11,
        //   MBTRAIN_RXDESKEW_end                = 24'h 0000_12,
        //   MBTRAIN_DATATRAINCENTER2_start      = 24'h 0000_13,
        //   MBTRAIN_DATATRAINCENTER2_end        = 24'h 0000_14,
        //   SBINIT_done                         = 24'h 0000_01,
        //   SBINIT_out_of_Reset                 = 24'h 0001_00,
          MBINIT_CONFG                        = 24'h0,
          MBINIT_REPAIRVAL_RESULT_errR_rq     = 24'h00000A,
          MBINIT_REPAIRVAL_RESULT_correct_R   = 24'h00010A,
          MBINIT_REPAIRCLK_RESULT_correctR    = 24'h000704,
          MBINIT_REPAIRCLK_RESULT_errR6       = 24'h000604,
          MBINIT_REPAIRCLK_RESULT_errR5       = 24'h000504,
          MBINIT_REPAIRCLK_RESULT_errR4       = 24'h000404,
          MBINIT_REPAIRCLK_RESULT_errR3       = 24'h000304,
          MBINIT_REPAIRCLK_RESULT_errR2       = 24'h000204,
          MBINIT_REPAIRCLK_RESULT_errR1       = 24'h000104,
          MBINIT_REPAIRCLK_RESULT_errR_rq     = 24'h000004, 
          MBINIT_CAL_DONE                     = 24'h000002,  
          MBINIT_REPAIRCLK_INIT               = 24'h000003,  
          MBINIT_REPAIRCLK_RESULT             = 24'h000004,  
          MBINIT_REPAIRCLK_DONE               = 24'h000008,
          MBINIT_REPAIRVAL_INIT               = 24'h000009,
          MBINIT_REPAIRVAL_APPLY_REPAIR       = 24'h00000B,
          MBINIT_REPAIRVAL_DONE               = 24'h00000C,
          MBINIT_REVERSALMB_INIT              = 24'h00000D,
          MBINIT_REVERSALMB_CLEAR_ERROR       = 24'h00000E,
          MBINIT_REVERSALMB_RESULT            = 24'h00000F,
          MBINIT_REVERSALMB_DONE              = 24'h000010,
          MBINIT_REPAIRMB_START               = 24'h000011,
          MBINIT_REPAIRMB_APPLY_REPAIR        =24'h000012,
          MBINIT_REPAIRMB_END                 = 24'h000013;
//___________________________________________________________________________________________________________
 parameter SBINIT_DONE_REQ_MSSG                      =64'h06000001_40254012,
           SBINIT_DONE_RESP_MSSG                     =64'h06000001_40268012,  
           MBINIT_PARAM_CONFIGURATION_REQ_MSSG       =64'h06000000_4029401B,
           MBINIT_PARAM_CONFIGURATION_RESP_MSSG      =64'h06000000_402A801B,
           MBINIT_CAL_DONE_REQ_MSSG                  =64'h06000002_40294012,
           MBINIT_CAL_DONE_RESP_MSSG                 =64'h06000002_402A8012,
           MBINIT_REPAIRCLK_INIT_REQ_MSSG            =64'h06000003_40294012,
           MBINIT_REPAIRCLK_INIT_RESP_MSSG           =64'h06000003_402A8012,
           MBINIT_REPAIRCLK_RESULT_REQ_MSSG          =64'h06000004_40294012,
           MBINIT_REPAIRCLK_RESULT_RESP_MSSG         =64'h06000004_402A8012,
           MBINIT_REPAIRCLK_DONE_REQ_MSSG            =64'h06000008_40294012,
           MBINIT_REPAIRCLK_DONE_RESP_MSSG           =64'h06000008_402A8012,
           MBINIT_REPAIRVAL_INIT_REQ_MSSG            =64'h06000009_40294012,
           MBINIT_REPAIRVAL_INIT_RESP_MSSG           =64'h06000009_402A8012,
           MBINIT_REPAIRVAL_RESULT_REQ_MSSG          =64'h0600000A_40294012,
           MBINIT_REPAIRVAL_RESULT_RESP_MSSG         =64'h0600010A_402A8012,
           MBINIT_REPAIRVAL_DONE_REQ_MSSG            =64'h0600000C_40294012,
           MBINIT_REPAIRVAL_DONE_RESP_MSSG           =64'h0600000C_402A8012,
           TRAINERROR_ENTRY_REQ_MSSG                 =64'h06000000_40394012,
           TRAINERROR_ENTRY_RESP_MSSG                =64'h06000000_403A8012,
           MBINIT_REVERSALMB_INIT_REQ_MSSG           =64'h0600000D_40294012,
           MBINIT_REVERSALMB_INIT_RESP_MSSG          =64'h0600000D_402A8012,
           MBINIT_REVERSALMB_CLEAR_ERR_REQ_MSSG      =64'h0600000E_40294012,
           MBINIT_REVERSALMB_CLEAR_ERR_RESP_MSSG     =64'h0600000E_402A8012,
           MBINIT_REVERSALMB_RESULT_REQ_MSSG         =64'h0600000F_40294012,
           MBINIT_REVERSALMB_RESULT_RESP_MSSG        =64'h0600000F_402A801b,
           MBINIT_REVERSALMB_DONE_REQ_MSSG           =64'h06000010_40294012,
           MBINIT_REVERSALMB_DONE_RESP_MSSG          =64'h06000010_402A8012,
           MBINIT_REPAIRMB_START_REQ_MSSG            =64'h06000011_40294012,
           MBINIT_REPAIRMB_START_RESP_MSSG           =64'h06000011_402A8012,
            // lane map m7tot b 3 ones w hn3mlo anding m3a el lane map el72i2i
           MBINIT_REPAIRMB_APPLY_DEGRADE_REQ          ={20'h06000,1'b0, 3'b111,40'h14_40294012},
           MBINIT_REPAIRMB_END_RESP_MSSG             =64'h06000013_402A8012,
           MBINIT_REPAIRMB_END_REQ_MSSG              =64'h06000013_40294012,
           MBTRAIN_VALVREF_START_REQ_MSSG            =64'h06000000_402D4012,
           MBTRAIN_VALVREF_START_RESP_MSSG           =64'h06000000_402E8012,
           START_RX_INIT_D_TO_C_TEST_REQ_MSSG        ={12'h060, 12'h000, 40'h07_4021401B}, 
           RX_INIT_D_TO_C_TX_COUNT_DONE_RESP_MSSG    = 64'h06000008_40228012,
           RX_INIT_D_TO_C_TX_COUNT_DONE_REQ_MSSG    = 64'h06000008_40214012,

           FAULTY_VALID_lANE                         =64'hFFFF_FDFF_FFFF_FFFF,
           START_RX_INIT_D_TO_C_TEST_RESP_MSSG       =64'h06000007_40228012,
           LFSR_CLEAR_ERROR_REQ_MSSG                 =64'h06000002_40214012,
           LFSR_CLEAR_ERROR_RESP_MSSG                =64'h06000002_40228012,
           //RX_INIT_D_TO_C_TX_COUNT_DONE_RESP_MSSG    =64'h06000008_40228012,
           END_RX_INIT_D_TO_C_POINT_TEST_REQ_MSSG    =64'h06000009_40214012,
           END_RX_INIT_D_TO_C_POINT_TEST_RESP_MSSG   =64'h06000009_40228012,
           MBTRAIN_VALVREF_END_REQ_MSSG               =64'h06000001_402D4012,
           MBTRAIN_VALVREF_END_RESP_MSSG                  =64'h06000001_402E8012,
           MBTRAIN_DATAVREF_START_REQ_MSSG           =64'h06000002_402D4012,
           MBTRAIN_DATAVREF_START_RESP_MSSG          =64'h06000002_402E8012,
           MBTRAIN_DATAVREF_END_REQ_MSSG             =64'h06000003_402D4012,
           MBTRAIN_DATAVREF_END_RESP_MSSG            =64'h06000003_402E8012,
           MBTRAIN_TXSELFCAL_START_REQ_MSSG          =64'h06000005_402D4012,
           MBTRAIN_TXSELFCAL_START_RESP_MSSG         =64'h06000005_402E8012,
           MBTRAIN_RXCLKCAL_START_REQ_MSSG           =64'h06000006_402D4012,
           MBTRAIN_RXCLKCAL_START_RESP_MSSG          =64'h06000006_402E8012,
           MBTRAIN_RXCLKCAL_DONE_REQ_MSSG            =64'h06000007_402D4012,
           MBTRAIN_RXCLKCAL_DONE_RESP_MSSG           =64'h06000007_402E8012,
           MBTRAIN_VALTRAINCENTER_START_REQ_MSSG     =64'h06000008_402D4012,
           MBTRAIN_VALTRAINCENTER_START_RESP_MSSG    =64'h06000008_402E8012,
           MBTRAIN_VALTRAINCENTER_END_REQ_MSSG       =64'h06000009_402D4012,
           MBTRAIN_VALTRAINCENTER_END_RESP_MSSG      =64'h06000009_402E8012,
           MBTRAIN_VALTRAINVREF_START_REQ_MSSG       =64'h0600000A_402D4012,
           MBTRAIN_VALTRAINVREF_START_RESP_MSSG      =64'h0600000A_402E8012,
           MBTRAIN_VALTRAINVREF_END_REQ_MSSG         =64'h0600000B_402D4012,
           MBTRAIN_VALTRAINVREF_END_RESP_MSSG        =64'h0600000B_402E8012,
           MBTRAIN_DATATRAINCENTER1_START_REQ_MSSG   =64'h0600000C_402D4012,
           MBTRAIN_DATATRAINCENTER1_START_RESP_MSSG  =64'h0600000C_402E8012,
           MBTRAIN_DATATRAINCENTER1_END_REQ_MSSG     =64'h0600000D_402D4012,
           MBTRAIN_DATATRAINCENTER1_END_RESP_MSSG    =64'h0600000D_402E8012,
           MBTRAIN_DATATRAINVREF_START_REQ_MSSG      =64'h0600000E_402D4012,
           MBTRAIN_DATATRAINVREF_START_RESP_MSSG     =64'h0600000E_402E8012,
           MBTRAIN_DATATRAINVREF_END_REQ_MSSG        =64'h06000010_402D4012,
           MBTRAIN_DATATRAINVREF_END_RESP_MSSG       =64'h06000010_402E8012,
           MBTRAIN_RXDESKEW_START_REQ_MSSG           =64'h06000011_402D4012,
           MBTRAIN_RXDESKEW_START_RESP_MSSG          =64'h06000011_402E8012,
           MBTRAIN_RXDESKEW_END_REQ_MSSG             =64'h06000012_402D4012,
           MBTRAIN_RXDESKEW_END_RESP_MSSG            =64'h06000012_402E8012,
           MBTRAIN_DATATRAINCENTER2_START_REQ_MSSG   =64'h06000013_402D4012,
           MBTRAIN_DATATRAINCENTER2_START_RESP_MSSG  =64'h06000013_402E8012,
           MBTRAIN_DATATRAINCENTER2_END_REQ_MSSG     =64'h06000014_402D4012,
           MBTRAIN_DATATRAINCENTER2_END_RESP_MSSG    =64'h06000014_402E8012,
 
           START_TX_INIT_D_TO_C_TEST_REQ_MSSG        =64'h06000001_4021401B,
           START_TX_INIT_D_TO_C_TEST_RESP_MSSG       =64'h06000001_40228012,
           TX_INIT_D_TO_C_RESULT_REQ_MSSG            =64'h06000003_40214012,
           TX_INIT_D_TO_C_RESULT_RESP_MSSG           = {5'b00000,3'b110,10'b0, 2'b11, 4'b0000,40'h03_4022801B},
           TX_INIT_D_TO_C_RESULT_RESP_MSSG_val       = {5'b00000,3'b110,9'b0, 2'b01, 1'b0, 4'b0000,40'h03_4022801B},
           TX_INIT_D_TO_C_RESULT_RESP_MSSG_data      = {5'b00000,3'b110,9'b0, 2'b00, 1'b1, 4'b0000,40'h03_4022801B},
           END_TX_INIT_D_TO_C_POINT_TEST_REQ_MSSG    =64'h06000004_40214012,
           END_TX_INIT_D_TO_C_POINT_TEST_RESP_MSSG   =64'h06000004_40228012,
           MBINIT_APPLY_DEGRADE_REQ_MSSG             =64'h06000314_40294012, // in binary its 01100000000000000000001100010100_010_0000000_1010_0101_00000000010010
           //widthdegrade bits are all ones here to add the real width degrade 
           MBINIT_APPLY_DEGRADE_RESP_MSSG            =64'h06000014_402A8012,
           SPEEDIDLE_DONE_REQ_MSSG                   =64'h06000004_402D4012,
           SPEEDIDLE_DONE_RESP_MSSG                  =64'h06000004_402E8012,
           PHYRETRAIN_START_REQ_MSSG                ={1'b0, 20'h0C000, 3'h7, 40'h0140314012},
           PHYRETRAIN_START_RESP_MSSG                ={1'b0, 20'h0C000, 3'h7, 40'h0140328012},
           MBTRAIN_LINKSPEED_START_REQ_MSSG          =64'h06000015_402D4012,
           MBTRAIN_LINKSPEED_START_RESP_MSSG         =64'h06000015_402E8012,
           MBTRAIN_LINKSPEED_ERROR_REQ_MSSG                 =64'h06000016_40_2D4_012,  
           MBTRAIN_LINKSPEED_ERROR_RESP_MSSG                 =64'h06000016_40_2E8_012,  
           MBTRAIN_LINKSPEED_EXIT_TO_SPEED_DEGRADE_REQ_MSSG =64'h06000018_40_2D4_012,  
           MBTRAIN_LINKSPEED_EXIT_TO_SPEED_DEGRADE_RESP_MSSG =64'h06000018_40_2E8_012, 

           MBTRAIN_LINKSPEED_EXIT_TO_REPAIR_REQ_MSSG        =64'h06000017_40_2D4_012,  
           MBTRAIN_LINKSPEED_EXIT_TO_REPAIR_RESP_MSSG        =64'h06000017_40_2E8_012,  
           MBTRAIN_LINKSPEED_DONE_REQ_MSSG                  =64'h06000019_40_2D4_012,  
           MBTRAIN_LINKSPEED_DONE_RESP_MSSG                 =64'h06000019_40_2E8_012,  
           MBTRAIN_REPAIR_INIT_REQ_MSSG                     =64'h0600001B_40_2D4_012,  
           MBTRAIN_REPAIR_INIT_RESP_MSSG                    =64'h0600001B_40_2E8_012,  
           MBTRAIN_REPAIR_END_REQ_MSSG                      =64'h0600001D_40_2D4_012,  
           MBTRAIN_REPAIR_END_RESP_MSSG                     =64'h0600001D_40_2E8_012,  
           MBTRAIN_REPAIR_APPLY_DEGRADE_REQ_MSSG            =64'h0600001E_40_2D4_012,  
           MBTRAIN_REPAIR_APPLY_DEGRADE_RESP_MSSG           =64'h0600001E_40_2E8_012;
          
      // Msg format = {dp[63], cp[62], rsvd[61:59], dstid[58:56], MsgInfo[55:40], MsgSubcode[39:32], srcid[31:29], rsvd[28:22], MsgCode[21:14], rsvd[13:5], opcode[4:0]}

  parameter bit [63:0] message_array[] = '{
  SBINIT_DONE_REQ_MSSG,
  SBINIT_DONE_RESP_MSSG,
  MBINIT_PARAM_CONFIGURATION_REQ_MSSG,
  MBINIT_PARAM_CONFIGURATION_RESP_MSSG,
  MBINIT_CAL_DONE_REQ_MSSG,
  MBINIT_CAL_DONE_RESP_MSSG,
  MBINIT_REPAIRCLK_INIT_REQ_MSSG,
  MBINIT_REPAIRCLK_INIT_RESP_MSSG,
  MBINIT_REPAIRCLK_RESULT_REQ_MSSG,
  MBINIT_REPAIRCLK_RESULT_RESP_MSSG,
  MBINIT_REPAIRCLK_DONE_REQ_MSSG,
  MBINIT_REPAIRCLK_DONE_RESP_MSSG,
  MBINIT_REPAIRVAL_INIT_REQ_MSSG,
  MBINIT_REPAIRVAL_INIT_RESP_MSSG,
  MBINIT_REPAIRVAL_RESULT_REQ_MSSG,
  MBINIT_REPAIRVAL_RESULT_RESP_MSSG,
  MBINIT_REPAIRVAL_DONE_REQ_MSSG,
  MBINIT_REPAIRVAL_DONE_RESP_MSSG,
  TRAINERROR_ENTRY_REQ_MSSG,
  TRAINERROR_ENTRY_RESP_MSSG,
  MBINIT_REVERSALMB_INIT_REQ_MSSG,
  MBINIT_REVERSALMB_INIT_RESP_MSSG,
  MBINIT_REVERSALMB_CLEAR_ERR_REQ_MSSG,
  MBINIT_REVERSALMB_CLEAR_ERR_RESP_MSSG,
  MBINIT_REPAIRMB_START_REQ_MSSG,
  MBINIT_REPAIRMB_START_RESP_MSSG,
  MBINIT_REPAIRMB_APPLY_DEGRADE_REQ,
  MBINIT_REPAIRMB_END_RESP_MSSG,
  MBINIT_REPAIRMB_END_REQ_MSSG,
  MBTRAIN_VALVREF_START_REQ_MSSG,
  MBTRAIN_VALVREF_START_RESP_MSSG,
  START_RX_INIT_D_TO_C_TEST_REQ_MSSG,
  RX_INIT_D_TO_C_TX_COUNT_DONE_RESP_MSSG,
  RX_INIT_D_TO_C_TX_COUNT_DONE_REQ_MSSG,
 64'h00000000_00000215,
  START_RX_INIT_D_TO_C_TEST_RESP_MSSG,
  LFSR_CLEAR_ERROR_REQ_MSSG,
  LFSR_CLEAR_ERROR_RESP_MSSG,
  END_RX_INIT_D_TO_C_POINT_TEST_REQ_MSSG,
  END_RX_INIT_D_TO_C_POINT_TEST_RESP_MSSG,
  MBTRAIN_VALVREF_END_REQ_MSSG,
  MBTRAIN_VALVREF_END_RESP_MSSG,
  MBTRAIN_DATAVREF_START_REQ_MSSG,
  MBTRAIN_DATAVREF_START_RESP_MSSG,
  MBTRAIN_DATAVREF_END_REQ_MSSG,
  MBTRAIN_DATAVREF_END_RESP_MSSG,
  MBTRAIN_TXSELFCAL_START_REQ_MSSG,
  MBTRAIN_TXSELFCAL_START_RESP_MSSG,
  MBTRAIN_RXCLKCAL_START_REQ_MSSG,
  MBTRAIN_RXCLKCAL_START_RESP_MSSG,
  MBTRAIN_RXCLKCAL_DONE_REQ_MSSG,
  MBTRAIN_RXCLKCAL_DONE_RESP_MSSG,
  MBTRAIN_VALTRAINCENTER_START_REQ_MSSG,
  MBTRAIN_VALTRAINCENTER_START_RESP_MSSG,
  MBTRAIN_VALTRAINCENTER_END_REQ_MSSG,
  MBTRAIN_VALTRAINCENTER_END_RESP_MSSG,
  MBTRAIN_VALTRAINVREF_START_REQ_MSSG,
  MBTRAIN_VALTRAINVREF_START_RESP_MSSG,
  MBTRAIN_VALTRAINVREF_END_REQ_MSSG,
  MBTRAIN_VALTRAINVREF_END_RESP_MSSG,
  MBTRAIN_DATATRAINCENTER1_START_REQ_MSSG,
  MBTRAIN_DATATRAINCENTER1_START_RESP_MSSG,
  MBTRAIN_DATATRAINCENTER1_END_REQ_MSSG,
  MBTRAIN_DATATRAINCENTER1_END_RESP_MSSG,
  MBTRAIN_DATATRAINVREF_START_REQ_MSSG,
  MBTRAIN_DATATRAINVREF_START_RESP_MSSG,
  MBTRAIN_DATATRAINVREF_END_REQ_MSSG,
  MBTRAIN_DATATRAINVREF_END_RESP_MSSG,
  MBTRAIN_RXDESKEW_START_REQ_MSSG,
  MBTRAIN_RXDESKEW_START_RESP_MSSG,
  MBTRAIN_RXDESKEW_END_REQ_MSSG,
  MBTRAIN_RXDESKEW_END_RESP_MSSG,
  MBTRAIN_DATATRAINCENTER2_START_REQ_MSSG,
  MBTRAIN_DATATRAINCENTER2_START_RESP_MSSG,
  MBTRAIN_DATATRAINCENTER2_END_REQ_MSSG,
  MBTRAIN_DATATRAINCENTER2_END_RESP_MSSG,

  START_TX_INIT_D_TO_C_TEST_REQ_MSSG,
  START_TX_INIT_D_TO_C_TEST_RESP_MSSG,
  TX_INIT_D_TO_C_RESULT_REQ_MSSG,
  TX_INIT_D_TO_C_RESULT_RESP_MSSG_val,
  TX_INIT_D_TO_C_RESULT_RESP_MSSG_data,
  END_TX_INIT_D_TO_C_POINT_TEST_REQ_MSSG,
  END_TX_INIT_D_TO_C_POINT_TEST_RESP_MSSG,
  MBINIT_APPLY_DEGRADE_REQ_MSSG,
  MBINIT_APPLY_DEGRADE_RESP_MSSG,
  SPEEDIDLE_DONE_REQ_MSSG,
  SPEEDIDLE_DONE_RESP_MSSG,
  PHYRETRAIN_START_REQ_MSSG,
  PHYRETRAIN_START_RESP_MSSG,
  MBTRAIN_LINKSPEED_START_REQ_MSSG,
  MBTRAIN_LINKSPEED_START_RESP_MSSG,
  MBTRAIN_LINKSPEED_ERROR_REQ_MSSG,
  MBTRAIN_LINKSPEED_ERROR_RESP_MSSG,
  MBTRAIN_LINKSPEED_EXIT_TO_SPEED_DEGRADE_REQ_MSSG,
  MBTRAIN_LINKSPEED_EXIT_TO_SPEED_DEGRADE_RESP_MSSG,
  MBTRAIN_LINKSPEED_EXIT_TO_REPAIR_REQ_MSSG,
  MBTRAIN_LINKSPEED_EXIT_TO_REPAIR_RESP_MSSG,
  MBTRAIN_LINKSPEED_DONE_REQ_MSSG,
  MBTRAIN_LINKSPEED_DONE_RESP_MSSG,
  MBTRAIN_REPAIR_INIT_REQ_MSSG,
  MBTRAIN_REPAIR_INIT_RESP_MSSG,
  MBTRAIN_REPAIR_END_REQ_MSSG,
  MBTRAIN_REPAIR_END_RESP_MSSG,
  MBTRAIN_REPAIR_APPLY_DEGRADE_REQ_MSSG,
  MBTRAIN_REPAIR_APPLY_DEGRADE_RESP_MSSG
};


    parameter bit [63:0] msgs_before_tx_init[] = '{
      MBINIT_REPAIRMB_START_RESP_MSSG,
      MBTRAIN_DATATRAINCENTER2_START_RESP_MSSG,
      MBTRAIN_DATATRAINCENTER1_START_RESP_MSSG,
      MBTRAIN_VALTRAINCENTER_START_RESP_MSSG,
      MBTRAIN_LINKSPEED_START_RESP_MSSG
    }; // array of messages before tx init

  parameter bit [63:0] msgs_before_rx_init [] ='{
  MBTRAIN_VALVREF_START_RESP_MSSG,
  MBTRAIN_DATAVREF_START_RESP_MSSG,
  MBTRAIN_RXDESKEW_START_RESP_MSSG,
  MBTRAIN_DATATRAINVREF_START_RESP_MSSG,
  MBTRAIN_VALTRAINVREF_START_RESP_MSSG
  };
// repairmb_tx_init_d2c_Data = 64'h00040000_00000001;
           
// Structure representing MsgInfo[15:0] for Tx Init D to C results resp
typedef struct packed {
    logic [9:0] reserved_high;    // [15:6] Reserved
    logic       valid_lane_cmp;   // [5]    Valid Lane comparison results
    logic       cumulative_res;   // [4]    Cumulative Results (0 = Fail, 1 = Pass)
    logic [3:0] rrd_compare;      // [3:0]  Redundant Lane compare results
} tx_init_d2c_msginfo_t;


        
typedef struct packed {
    logic [13:0] user_defined;        // [63:50] Custom or extension
    logic [34:0] reserved;            // [49:15] Reserved / future use
    logic [3:0]  module_id;           // [14:11] Module ID: 0h, 1h, 2h, 3h
    logic        clock_phase;         // [10]    0 = Differential; 1 = Quadrature
    logic        clock_mode;          // [9]     0 = Strobe; 1 = Continuous
    logic [4:0]  voltage_swing;       // [8:4]   Voltage Swing
    logic [3:0]  max_io_link_speed;   // [3:0]   Max IO Link Speed
} phy_config_t;

typedef struct packed {
  logic [2:0]   data_pattern_select;   // [63:61]
  logic [2:0]   valid_pattern;         // [60:58]
  logic [3:0]   clock_phase_control;   // [57:54]
  logic         pattern_mode;          // [53]
  logic [15:0]  burst_count;           // [52:37]
  logic [15:0]  idle_count;            // [36:21]
  logic [15:0]  iteration_count;       // [20:5]
  logic         comparison_mode;       // [4]
  logic [3:0]   reserved;              // [3:0]
} tx_init_config_t;


parameter tx_init_config_t D_TO_C_LFSR = '{
  data_pattern_select : 3'h0,
  valid_pattern       : 3'h0,
  clock_phase_control : 4'h0,
  pattern_mode        : 1'b0,
  burst_count         : 16'h1000,
  idle_count          : 16'h0000,
  iteration_count     : 16'h0001,
  comparison_mode     : 1'b0,
  reserved            : 4'h0
};
parameter tx_init_config_t D_TO_C_DEFAULT = '{
  data_pattern_select : 3'h0,
  valid_pattern       : 3'h0,
  clock_phase_control : 4'h0,
  pattern_mode        : 1'b0,
  burst_count         : 16'h0400,
  idle_count          : 16'h0000,
  iteration_count     : 16'h0001,
  comparison_mode     : 1'b0,
  reserved            : 4'h0
};

parameter tx_init_config_t D_TO_C_PERLANE = '{
  data_pattern_select : 3'h1,
  valid_pattern       : 3'h0,
  clock_phase_control : 4'h0,
  pattern_mode        : 1'b0,
  burst_count         : 16'h0800,
  idle_count          : 16'h0000,
  iteration_count     : 16'h0001,
  comparison_mode     : 1'b0,
  reserved             :4'h0
};

parameter phy_config_t PHY_CONFIG_REQ = '{
    max_io_link_speed : 4'h5,          // Example: Speed 32
    voltage_swing     : 5'h1,          // Example: Swing 0.4
    clock_mode        : 1'h1,          // Continuous mode
    clock_phase       : 1'h0,          // Differential clock
    module_id         : 4'h0,          // Module 0
    reserved          : '0,            // Reserved = 0
    user_defined      : 15'h0000       // Custom = 0
};

parameter phy_config_t PHY_CONFIG_RESP = '{
    max_io_link_speed : 4'h5,          // Example: Speed 32
    voltage_swing     : 5'h00,         // not in the resp msg 
    clock_mode        : 1'h1,          // Continuous mode
    clock_phase       : 1'h0,          // Differential clock
    module_id         : 4'h0,          // Module 0
    reserved          : '0,            // Reserved = 0
    user_defined      : 15'h0000       // Custom = 0
};

tx_init_d2c_msginfo_t msginfo_succ = '{
    reserved_high   : 10'b0,
    valid_lane_cmp  : 1'b1,
    cumulative_res  : 1'b1,
    rrd_compare     : 4'b0001
};





//src_id 
parameter src_PHY = 3'b010
         ,src_D2D = 3'b001;


 typedef enum int {
	       SBINIT_DONE_REQ,
           SBINIT_DONE_RESP,  
           MBINIT_PARAM_CONFIGURATION_REQ,
           MBINIT_PARAM_CONFIGURATION_RESP,
           MBINIT_CAL_DONE_REQ,
           MBINIT_CAL_DONE_RESP,
           MBINIT_REPAIRCLK_INIT_REQ,
           MBINIT_REPAIRCLK_INIT_RESP,
           MBINIT_REPAIRCLK_RESULT_REQ,
           MBINIT_REPAIRCLK_RESULT_RESP,
           MBINIT_REPAIRCLK_DONE_REQ,
           MBINIT_REPAIRCLK_DONE_RESP,
           MBINIT_REPAIRVAL_INIT_REQ,
           MBINIT_REPAIRVAL_INIT_RESP,
           MBINIT_REPAIRVAL_RESULT_REQ,
           MBINIT_REPAIRVAL_RESULT_RESP,
           MBINIT_REPAIRVAL_DONE_REQ,
           MBINIT_REPAIRVAL_DONE_RESP,
           TRAINERROR_ENTRY_REQ,
           TRAINERROR_ENTRY_RESP,
           MBINIT_REVERSALMB_INIT_REQ,
           MBINIT_REVERSALMB_INIT_RESP,
           MBINIT_REVERSALMB_CLEAR_ERR_REQ,
           MBINIT_REVERSALMB_CLEAR_ERR_RESP,
           MBINIT_REVERSALMB_RESULT_REQ,
           MBINIT_REVERSALMB_RESULT_RESP,
           MBINIT_REVERSALMB_DONE_REQ,
           MBINIT_REVERSALMB_DONE_RESP,
           MBINIT_REPAIRMB_START_REQ,
           MBINIT_REPAIRMB_START_RESP,
	   //  MBINIT_REPAIRMB_APPLY_DEGRADE_REQ   
           MBINIT_REPAIRMB_END_RESP,
           MBINIT_REPAIRMB_END_REQ,
           MBTRAIN_VALVREF_START_REQ,
           MBTRAIN_VALVREF_START_RESP,
		   // START_RX_INIT_D_TO_C_TEST_REQ        = lsa htt3dl ,
       //    FAULTY_VALID_lANE,
           START_RX_INIT_D_TO_C_TEST_RESP,
           LFSR_CLEAR_ERROR_REQ,
           LFSR_CLEAR_ERROR_RESP,
           RX_INIT_D_TO_C_TX_COUNT_DONE_RESP,
           END_RX_INIT_D_TO_C_POINT_TEST_REQ,
           END_RX_INIT_D_TO_C_POINT_TEST_RESP,
           MBTRAIN_VALVREF_END_REQ_E,
           MBTRAIN_VALVREF_END_RESP_E,
           MBTRAIN_DATAVREF_START_REQ,
           MBTRAIN_DATAVREF_START_RESP,
           MBTRAIN_TXSELFCAL_START_REQ,
           MBTRAIN_TXSELFCAL_START_RESP,
           MBTRAIN_RXCLKCAL_START_REQ,
           MBTRAIN_RXCLKCAL_START_RESP,
           MBTRAIN_RXCLKCAL_DONE_REQ,
           MBTRAIN_RXCLKCAL_DONE_RESP,
           MBTRAIN_VALTRAINCENTER_START_REQ,
           MBTRAIN_VALTRAINCENTER_START_RESP,
           MBTRAIN_VALTRAINCENTER_END_REQ,
           MBTRAIN_VALTRAINCENTER_END_RESP,
           START_TX_INIT_D_TO_C_TEST_REQ,
           START_TX_INIT_D_TO_C_TEST_RESP,
           TX_INIT_D_TO_C_RESULT_REQ,
           TX_INIT_D_TO_C_RESULT_RESP,
           END_TX_INIT_D_TO_C_POINT_TEST_REQ,
           END_TX_INIT_D_TO_C_POINT_TEST_RESP,
           MBINIT_APPLY_DEGRADE_REQ, 
           MBINIT_APPLY_DEGRADE_RESP,
           SPEEDIDLE_DONE_REQ,
           SPEEDIDLE_DONE_RESP,
           PHYRETRAIN_START_REQ,
           PHYRETRAIN_START_RESP,
           MBTRAIN_LINKSPEED_START_REQ,
           MBTRAIN_LINKSPEED_START_RESP,
           MBTRAIN_LINKSPEED_ERROR_REQ,  
           MBTRAIN_LINKSPEED_ERROR_RSP,  
           MBTRAIN_LINKSPEED_EXIT_TO_SPEED_DEGRADE_REQ,  
           MBTRAIN_LINKSPEED_EXIT_TO_SPEED_DEGRADE_RSP, 
           MBTRAIN_LINKSPEED_EXIT_TO_REPAIR_REQ,  
           MBTRAIN_LINKSPEED_EXIT_TO_REPAIR_RSP,  
           MBTRAIN_LINKSPEED_DONE_REQ,  
           MBTRAIN_LINKSPEED_DONE_RESP,  
           MBTRAIN_REPAIR_INIT_REQ,  
           MBTRAIN_REPAIR_INIT_RESP,  
           MBTRAIN_REPAIR_END_REQ,  
           MBTRAIN_REPAIR_END_RESP,  
           MBTRAIN_REPAIR_APPLY_DEGRADE_REQ,  
           MBTRAIN_REPAIR_APPLY_DEGRADE_RESP,
           MBTRAIN_VALTRAINVREF_START_REQ_ ,
           MBTRAIN_VALTRAINVREF_START_RESP,
           LINKERROR_REQ,
           LINKERROR_RSP,
           ACTIVE_REQ,
           ACTIVE_RSP,
           RETRAIN_REQ,
           RETRAIN_RSP,
           DISABLE_REQ,
           DISABLE_RSP,
           LINKRESET_REQ,
           LINKRESET_RSP,
		   ZEROS,
		   OTHER 


  } enum_t;
function enum_t msg2enum (logic [63:0] val);
    case (val)
      SBINIT_DONE_REQ_MSSG: return SBINIT_DONE_REQ;
      SBINIT_DONE_RESP_MSSG: return SBINIT_DONE_RESP;
      MBINIT_PARAM_CONFIGURATION_REQ_MSSG: return MBINIT_PARAM_CONFIGURATION_REQ;
      MBINIT_PARAM_CONFIGURATION_RESP_MSSG: return MBINIT_PARAM_CONFIGURATION_RESP;
      MBINIT_CAL_DONE_REQ_MSSG: return MBINIT_CAL_DONE_REQ;
      MBINIT_CAL_DONE_RESP_MSSG: return MBINIT_CAL_DONE_RESP;
      MBINIT_REPAIRCLK_INIT_REQ_MSSG: return MBINIT_REPAIRCLK_INIT_REQ;
      MBINIT_REPAIRCLK_INIT_RESP_MSSG: return MBINIT_REPAIRCLK_INIT_RESP;
      MBINIT_REPAIRCLK_RESULT_REQ_MSSG: return MBINIT_REPAIRCLK_RESULT_REQ;
      MBINIT_REPAIRCLK_RESULT_RESP_MSSG: return MBINIT_REPAIRCLK_RESULT_RESP;
      MBINIT_REPAIRCLK_DONE_REQ_MSSG: return MBINIT_REPAIRCLK_DONE_REQ;
      MBINIT_REPAIRCLK_DONE_RESP_MSSG: return MBINIT_REPAIRCLK_DONE_RESP;
      MBINIT_REPAIRVAL_INIT_REQ_MSSG: return MBINIT_REPAIRVAL_INIT_REQ;
      MBINIT_REPAIRVAL_INIT_RESP_MSSG: return MBINIT_REPAIRVAL_INIT_RESP;
      MBINIT_REPAIRVAL_RESULT_REQ_MSSG: return MBINIT_REPAIRVAL_RESULT_REQ;
      MBINIT_REPAIRVAL_RESULT_RESP_MSSG: return MBINIT_REPAIRVAL_RESULT_RESP;
      (MBINIT_REPAIRVAL_RESULT_RESP_MSSG^(64'h00000100_00000000)): return MBINIT_REPAIRVAL_RESULT_RESP;
      MBINIT_REPAIRVAL_DONE_REQ_MSSG: return MBINIT_REPAIRVAL_DONE_REQ;
      MBINIT_REPAIRVAL_DONE_RESP_MSSG: return MBINIT_REPAIRVAL_DONE_RESP;
      TRAINERROR_ENTRY_REQ_MSSG: return TRAINERROR_ENTRY_REQ;
      TRAINERROR_ENTRY_RESP_MSSG: return TRAINERROR_ENTRY_RESP;
      MBINIT_REVERSALMB_INIT_REQ_MSSG: return MBINIT_REVERSALMB_INIT_REQ;
      MBINIT_REVERSALMB_INIT_RESP_MSSG: return MBINIT_REVERSALMB_INIT_RESP;
      MBINIT_REVERSALMB_CLEAR_ERR_REQ_MSSG: return MBINIT_REVERSALMB_CLEAR_ERR_REQ;
      MBINIT_REVERSALMB_CLEAR_ERR_RESP_MSSG: return MBINIT_REVERSALMB_CLEAR_ERR_RESP;
      MBINIT_REVERSALMB_RESULT_REQ_MSSG: return MBINIT_REVERSALMB_RESULT_REQ;
      MBINIT_REVERSALMB_RESULT_RESP_MSSG: return MBINIT_REVERSALMB_RESULT_RESP;
      MBINIT_REVERSALMB_DONE_REQ_MSSG: return MBINIT_REVERSALMB_DONE_REQ;
      MBINIT_REVERSALMB_DONE_RESP_MSSG: return MBINIT_REVERSALMB_DONE_RESP;
      MBINIT_REPAIRMB_START_REQ_MSSG: return MBINIT_REPAIRMB_START_REQ;
      MBINIT_REPAIRMB_START_RESP_MSSG: return MBINIT_REPAIRMB_START_RESP;
      MBINIT_REPAIRMB_END_RESP_MSSG: return MBINIT_REPAIRMB_END_RESP;
      MBINIT_REPAIRMB_END_REQ_MSSG: return MBINIT_REPAIRMB_END_REQ;
      MBTRAIN_VALVREF_START_REQ_MSSG: return MBTRAIN_VALVREF_START_REQ;
      MBTRAIN_VALVREF_START_RESP_MSSG: return MBTRAIN_VALVREF_START_RESP;
      // START_RX_INIT_D_TO_C_TEST_REQ_MSSG: return START_RX_INIT_D_TO_C_TEST_REQ;
      MBTRAIN_VALTRAINVREF_START_REQ_MSSG  : return  MBTRAIN_VALTRAINVREF_START_REQ_ ;
      MBTRAIN_VALTRAINVREF_START_RESP_MSSG : return  MBTRAIN_VALTRAINVREF_START_RESP  ;
      START_RX_INIT_D_TO_C_TEST_RESP_MSSG: return START_RX_INIT_D_TO_C_TEST_RESP;
      LFSR_CLEAR_ERROR_REQ_MSSG: return LFSR_CLEAR_ERROR_REQ;
      LFSR_CLEAR_ERROR_RESP_MSSG: return LFSR_CLEAR_ERROR_RESP;
      RX_INIT_D_TO_C_TX_COUNT_DONE_RESP_MSSG: return RX_INIT_D_TO_C_TX_COUNT_DONE_RESP;
      END_RX_INIT_D_TO_C_POINT_TEST_REQ_MSSG: return END_RX_INIT_D_TO_C_POINT_TEST_REQ;
      END_RX_INIT_D_TO_C_POINT_TEST_RESP_MSSG: return END_RX_INIT_D_TO_C_POINT_TEST_RESP;
      MBTRAIN_VALVREF_END_REQ_MSSG: return MBTRAIN_VALVREF_END_REQ_E;
      MBTRAIN_VALVREF_END_RESP_MSSG: return MBTRAIN_VALVREF_END_RESP_E;
      MBTRAIN_DATAVREF_START_REQ_MSSG: return MBTRAIN_DATAVREF_START_REQ;
      MBTRAIN_DATAVREF_START_RESP_MSSG: return MBTRAIN_DATAVREF_START_RESP;
      MBTRAIN_TXSELFCAL_START_REQ_MSSG: return MBTRAIN_TXSELFCAL_START_REQ;
      MBTRAIN_TXSELFCAL_START_RESP_MSSG: return MBTRAIN_TXSELFCAL_START_RESP;
      MBTRAIN_RXCLKCAL_START_REQ_MSSG: return MBTRAIN_RXCLKCAL_START_REQ;
      MBTRAIN_RXCLKCAL_START_RESP_MSSG: return MBTRAIN_RXCLKCAL_START_RESP;
      MBTRAIN_RXCLKCAL_DONE_REQ_MSSG: return MBTRAIN_RXCLKCAL_DONE_REQ;
      MBTRAIN_RXCLKCAL_DONE_RESP_MSSG: return MBTRAIN_RXCLKCAL_DONE_RESP;
      MBTRAIN_VALTRAINCENTER_START_REQ_MSSG: return MBTRAIN_VALTRAINCENTER_START_REQ;
      MBTRAIN_VALTRAINCENTER_END_REQ_MSSG: return MBTRAIN_VALTRAINCENTER_END_REQ;
      MBTRAIN_VALTRAINCENTER_END_RESP_MSSG: return MBTRAIN_VALTRAINCENTER_END_RESP;
      START_TX_INIT_D_TO_C_TEST_REQ_MSSG: return START_TX_INIT_D_TO_C_TEST_REQ;
      START_TX_INIT_D_TO_C_TEST_RESP_MSSG: return START_TX_INIT_D_TO_C_TEST_RESP;
      TX_INIT_D_TO_C_RESULT_REQ_MSSG: return TX_INIT_D_TO_C_RESULT_REQ;
   //   TX_INIT_D_TO_C_RESULT_RESP_MSSG: return TX_INIT_D_TO_C_RESULT_RESP;
      END_TX_INIT_D_TO_C_POINT_TEST_REQ_MSSG: return END_TX_INIT_D_TO_C_POINT_TEST_REQ;
      END_TX_INIT_D_TO_C_POINT_TEST_RESP_MSSG: return END_TX_INIT_D_TO_C_POINT_TEST_RESP;
      MBINIT_APPLY_DEGRADE_REQ_MSSG: return MBINIT_APPLY_DEGRADE_REQ;
      MBINIT_APPLY_DEGRADE_RESP_MSSG: return MBINIT_APPLY_DEGRADE_RESP;
      SPEEDIDLE_DONE_REQ_MSSG: return SPEEDIDLE_DONE_REQ;
      SPEEDIDLE_DONE_RESP_MSSG: return SPEEDIDLE_DONE_RESP;
      PHYRETRAIN_START_REQ_MSSG: return PHYRETRAIN_START_REQ;
      PHYRETRAIN_START_RESP_MSSG: return PHYRETRAIN_START_RESP;
      MBTRAIN_LINKSPEED_START_REQ_MSSG: return MBTRAIN_LINKSPEED_START_REQ;
      MBTRAIN_LINKSPEED_START_RESP_MSSG: return MBTRAIN_LINKSPEED_START_RESP;
      MBTRAIN_LINKSPEED_ERROR_REQ_MSSG: return MBTRAIN_LINKSPEED_ERROR_REQ;
      MBTRAIN_LINKSPEED_ERROR_RESP_MSSG: return MBTRAIN_LINKSPEED_ERROR_RSP;
      MBTRAIN_LINKSPEED_EXIT_TO_SPEED_DEGRADE_REQ_MSSG: return MBTRAIN_LINKSPEED_EXIT_TO_SPEED_DEGRADE_REQ;
      MBTRAIN_LINKSPEED_EXIT_TO_SPEED_DEGRADE_RESP_MSSG: return MBTRAIN_LINKSPEED_EXIT_TO_SPEED_DEGRADE_RSP;
      MBTRAIN_LINKSPEED_EXIT_TO_REPAIR_REQ_MSSG: return MBTRAIN_LINKSPEED_EXIT_TO_REPAIR_REQ;
      MBTRAIN_LINKSPEED_EXIT_TO_REPAIR_RESP_MSSG: return MBTRAIN_LINKSPEED_EXIT_TO_REPAIR_RSP;
      MBTRAIN_LINKSPEED_DONE_REQ_MSSG: return MBTRAIN_LINKSPEED_DONE_REQ;
      MBTRAIN_LINKSPEED_DONE_RESP_MSSG: return MBTRAIN_LINKSPEED_DONE_RESP;
      MBTRAIN_REPAIR_INIT_REQ_MSSG: return MBTRAIN_REPAIR_INIT_REQ;
      MBTRAIN_REPAIR_INIT_RESP_MSSG: return MBTRAIN_REPAIR_INIT_RESP;
      MBTRAIN_REPAIR_END_REQ_MSSG: return MBTRAIN_REPAIR_END_REQ;
      MBTRAIN_REPAIR_END_RESP_MSSG: return MBTRAIN_REPAIR_END_RESP;
      MBTRAIN_REPAIR_APPLY_DEGRADE_REQ_MSSG: return MBTRAIN_REPAIR_APPLY_DEGRADE_REQ;
      MBTRAIN_REPAIR_APPLY_DEGRADE_RESP_MSSG: return MBTRAIN_REPAIR_APPLY_DEGRADE_RESP;
	  64'b0000_0000_0000_0000: return ZEROS;
      64'h06000001_40004012: return ACTIVE_REQ;
      64'h06000001_40008012: return ACTIVE_RSP;
      64'h0600000C_40004012: return DISABLE_REQ;
      64'h0600000C_40008012: return DISABLE_RSP;
      64'h06000009_40004012: return LINKRESET_REQ;
      64'h06000009_40008012: return LINKRESET_RSP;
      64'h0600000A_40004012: return LINKERROR_REQ;
      64'h0600000A_40008012: return LINKERROR_RSP;
      64'h0600000B_40004012: return RETRAIN_REQ;
      64'h0600000B_40008012: return RETRAIN_RSP;
      default: return OTHER;
    endcase
  endfunction
//___________________________________________________________________________________________________________          

endpackage
