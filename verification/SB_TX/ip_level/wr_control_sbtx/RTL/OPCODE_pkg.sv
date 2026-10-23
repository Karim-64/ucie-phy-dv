package OPCODE_pkg;

parameter SRC_ID_LENGTH=3;
parameter DST_ID_LENGTH=3;
parameter TAG_LENGTH=5;
parameter STATUS_LENGTH=3;
parameter OPCODE_LENGTH=5;
parameter BE_LENGTH=8;
parameter ADDR_LENGTH=24;
parameter MSGCODE_LENGTH=8;

parameter opcode_offset=0;
parameter be_offset=14;
parameter tag_offset=22;
parameter status_offset=32;
parameter addr_offset=32;
parameter srcid_offset=29;
parameter dst_id_offset_32=24;
parameter dst_id_offset_64=56;
parameter cp_offset_32=30;
parameter dp_offset_32=31;
parameter cp_offset_64=62;
parameter dp_offset_64=63;
parameter msgcode_offset=14;

parameter Remote_Terminated_Request=1'b1;


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
    SC = 3'b000,
    UR = 3'b001,
    CA= 3'b100,
    Stall= 3'b111

    } Comp_Status;

    
endpackage
