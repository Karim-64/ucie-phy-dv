import Universal_pkg ::* ; 

module Controller_Arbiter #( parameter DATA_WIDTH = 64 )
(
    input  logic                  sys_rst               ,
    input  logic                  lclk                  ,
    input  logic                  phy_resend_req        , // signal to wait for the D2D to write its data in the Async. FIFO
    input  logic                  rdi_en                ,
    input  logic                  module_en             ,
    input  logic                  module_partner_en     ,
    input  logic [DATA_WIDTH-1:0] rdi_data              ,
    input  logic [DATA_WIDTH-1:0] module_data           ,
    input  logic [DATA_WIDTH-1:0] module_partner_data   ,
    output logic [DATA_WIDTH-1:0] encoder_data          ,
    output logic                  encoder_en,data_marker  // Data marker for the SB_TX Credits System
);

    //-------------- Buffers and counters ---------------//

    localparam SRC_ID = 3'b010;  // PHY
    localparam DST_ID = 3'b110;  // PHY

    logic CP,DP;
    logic Data_Message_M,Data_Message_MP;
    logic [DATA_WIDTH-3:0] temp_reg;

    logic [DATA_WIDTH-1:0] module_buf[1:0];
    logic [DATA_WIDTH-1:0] partner_buf[1:0];
    logic [DATA_WIDTH-1:0] rdi_buf;            // rdi_buf[1:0]

    logic [1:0] module_count, partner_count; // [1:0] rdi_count
    logic rdi_marker;      

    //-------------------------------------------------------//

    //----------------------- FSM ---------------------------//

    typedef enum logic [1:0] {IDLE, MODULE, PARTNER, RDI} state_t;
    state_t current_state, next_state;

    always_ff @(posedge lclk or negedge sys_rst) begin

    if (~sys_rst) 
        current_state <= IDLE;
    else 
        current_state <= next_state;
        
    end

    always_comb begin                      // State Transition

    // Default values 
        next_state   = IDLE;

         case (current_state)

            IDLE: begin
                if      (rdi_marker)        next_state = RDI;
                else if (partner_count > 0) next_state = PARTNER;
                else if (module_count  > 0) next_state = MODULE;
            end

            MODULE: begin
                 next_state = (~phy_resend_req) ? ((module_count > 1 & Data_Message_M) ? MODULE : IDLE) : MODULE;
            end

            PARTNER: begin
                next_state = (~phy_resend_req) ? ((partner_count > 1) ? PARTNER : IDLE) : PARTNER;
            end

            RDI: begin
                next_state = (~phy_resend_req) ? IDLE : RDI;
            end

        endcase

    end 

    always_comb begin               // Outputs Transition

        // Default outputs
        encoder_data = 0;
        encoder_en   = 0;
        data_marker  = 0;

        case (current_state)

            IDLE: begin

               encoder_en  = (rdi_marker || partner_count > 0 || module_count > 0)? 1'b1 : 1'b0;
               data_marker = (rdi_marker) ? 1'b0 :((partner_count > 0)? Data_Message_MP : ((module_count > 0) ? Data_Message_M : 1'b0));

            end

            MODULE: begin
                encoder_data = (Data_Message_M)? ((module_count > 1) ? {DP,CP,temp_reg} : module_buf[0]) : {DP,CP,temp_reg};
                data_marker  = Data_Message_M & (module_count > 1);
                encoder_en   = phy_resend_req;
            end

            PARTNER: begin
                encoder_data = (Data_Message_MP)? ((partner_count > 1) ? {DP,CP,temp_reg} : partner_buf[0]) : {DP,CP,temp_reg};
                data_marker  = Data_Message_MP & (partner_count > 1);
                encoder_en   = phy_resend_req;
            end

            RDI: begin
                encoder_data = {DP,CP,temp_reg};
                encoder_en = phy_resend_req;
            end

        endcase
    end

    //--------------------------------------------------------------//

    // ------------- Sequential Block ---------------------------- //
    always_ff @(posedge lclk or negedge sys_rst) begin

        if (~sys_rst) begin

            module_buf [0]  <= 0; module_buf[1]  <= 0; module_count  <= 0;
            partner_buf[0] <= 0; partner_buf[1] <= 0; partner_count <= 0;
            rdi_buf <= 0; rdi_marker <= 0;Data_Message_M<=0;Data_Message_MP<=0;

        end else begin
            // Capture logic (store 2 values max)
            if (module_en) begin

                Data_Message_M <= (module_count == 0)? (module_data[opcode_offset +: OPCODE_LENGTH] == Message_With_64b_Data) : Data_Message_M;
                module_buf[module_count] <= module_data;
                module_count <= module_count + 1;

            end

            if (module_partner_en) begin

               Data_Message_MP <= (partner_count == 0)? (module_partner_data [opcode_offset +: OPCODE_LENGTH] == Message_With_64b_Data): Data_Message_MP;
               partner_buf[partner_count] <= module_partner_data ;
               partner_count <= partner_count + 1;
  
            end

            if (rdi_en) begin
                rdi_buf    <= rdi_data;
                rdi_marker <= 1;
            end


            // Dequeue logic
            case (current_state)

                MODULE: 

                    if(~phy_resend_req) begin              
                    module_buf[0] <= module_buf[1];
                    module_buf[1] <= 0;
                    module_count  <= module_count - 1;
                    end 
                
                PARTNER:

                    if(~phy_resend_req) begin  
                    partner_buf[0] <= partner_buf[1];
                    partner_buf[1] <= 0;
                    partner_count  <= partner_count - 1;
                    end

                RDI: 

                    if(~phy_resend_req) begin
                    rdi_buf <= 0;
                    rdi_marker <=0;
                    end

            endcase

        end

    end

    //------------------------------------------------------------------//

    //----------------------- CP & DP Calculation ---------------------// 

    always_comb begin 

    //default values 
    CP='b0;
    DP='b0;
    temp_reg='b0;

    case(current_state)

    MODULE: begin

    temp_reg =((module_buf[0][cp_offset_64-1:0] & ~(64'h7 << srcid_offset) | (SRC_ID << srcid_offset)) & ~(64'h7 << dst_id_offset_64) | (DST_ID << dst_id_offset_64));
    CP=^temp_reg;
    DP=(Data_Message_M)? ^(module_buf[1]): 1'b0;
                
    end

    PARTNER:  begin

    temp_reg =((partner_buf[0][cp_offset_64-1:0] & ~(64'h7 << srcid_offset) | (SRC_ID << srcid_offset)) & ~(64'h7 << dst_id_offset_64) | (DST_ID << dst_id_offset_64));
    CP=^temp_reg;
    DP=(Data_Message_MP)? ^(partner_buf[1]): 1'b0;
                
    end

    RDI: begin
    
    temp_reg = ((rdi_buf[cp_offset_64-1:0] & ~(64'h7 << srcid_offset) | (SRC_ID << srcid_offset)) & ~(64'h7 << dst_id_offset_64) | (DST_ID << dst_id_offset_64));
    CP=^temp_reg;
    DP=1'b0;
         
    end

    endcase

    end 

    //-----------------------------------------------------------------//


endmodule

