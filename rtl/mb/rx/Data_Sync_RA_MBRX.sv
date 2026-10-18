module Data_Sync_RA_MBRX #(parameter WIDTH=2)   
(
    input  logic              fast_clk  ,
    input  logic              slow_clk  ,
    input  logic              fast_reset,   // Reset signal for fast clock domain
    input  logic              slow_reset,   // Reset signal for slow clock domain
    input  logic              Req_Src   ,
    output logic              Req_Syn   ,
    input  logic [WIDTH-1:0]  fast_data ,   // Two-bit data from fast domain
    output logic [WIDTH-1:0]  slow_data     // Synchronized two-bit data in slow domain
);

    // Handshake signals
    logic req, ack;
    logic [WIDTH-1:0] data_latch; // Latched data in fast clock domain

    //-----------------latch Data in Fast Clock Domain--------------//

    always_ff @(posedge fast_clk or negedge fast_reset) begin

        if (~fast_reset) begin

        data_latch <= '0;
        req        <= 1'b0;

    end else begin

        if (!req & Req_Src) begin
            
            data_latch <= fast_data;     // Latch new data
            req        <= 1'b1;          // Start a new handshake

        end else if (ack) req <= 1'b0;   // Clear request once acknowledged
    end

    end

    
    //-------------synch. Request--------------------//

    logic req_ff1,req_ff2,req_sync; // Synchronizers for req signal

    always_ff @(posedge slow_clk or negedge slow_reset) begin

        if (~slow_reset) begin

            req_sync   <= 1'b0;
            req_ff1    <= 1'b0;
            req_ff2    <= 1'b0;

        end else begin

            req_ff1   <= req;         
            req_ff2   <= req_ff1;
            req_sync  <= req_ff2;    

        end
    end

    assign Req_Syn = ~req_sync & req_ff2; // Rising edge detection
    assign slow_data = data_latch;

// ---------------Sync. Acknowledge-------------------------//

logic ack_ff1,ack_ff2,ack_sync;

always_ff @(posedge fast_clk or negedge fast_reset) begin

    if (~fast_reset) begin

        ack_ff1  <= 1'b0;
        ack_sync <= 1'b0;
        ack_ff2  <= 1'b0;

    end else begin

        ack_ff1    <= req_sync;
        ack_ff2    <= ack_ff1 ;
        ack_sync   <= ack_ff2;

    end
end

assign ack = ~ack_sync & ack_ff2;


endmodule