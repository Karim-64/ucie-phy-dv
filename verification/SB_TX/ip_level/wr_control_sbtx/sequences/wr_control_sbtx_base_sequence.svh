`ifndef WR_CONTROL_SBTX_BASE_SEQUENCE_SVH
`define WR_CONTROL_SBTX_BASE_SEQUENCE_SVH

class wr_control_sbtx_base_sequence extends uvm_sequence #(wr_control_sbtx_sequence_item);
  `uvm_object_utils(wr_control_sbtx_base_sequence)
  `uvm_declare_p_sequencer(wr_control_sbtx_sequencer)

  function new(string name = "wr_control_sbtx_base_sequence");
    super.new(name);
  endfunction

  // Helper task to build and send a multi-phase packet using the pin-level sequence item
  task send_sideband_packet(logic [4:0] opcode, logic [7:0] msgcode, bit has_data);
    logic [63:0] header;
    logic [63:0] data_payload;
    bit          cp_calc;
    bit          dp_calc;
    
    // 1. Construct the 64-bit Header
    header = '0;
    header[4:0]   = opcode;
    header[21:14] = msgcode;
    
    // 2. Generate Dummy Data if required
    if (has_data) begin
      data_payload = 64'hDEADBEEF_CAFEBABE;
      dp_calc = ^data_payload; // Data Parity
    end else begin
      data_payload = 64'h0;
      dp_calc = 1'b0;          // DP must be 0 if no data
    end
    
    // 3. Calculate Parity and Insert into Phase 1 (Upper 32 bits)
    cp_calc = ^header[61:0];   // Control Parity
    header[62] = cp_calc;
    header[63] = dp_calc;
    
    // ---------------------------------------------------------
    // Send Phase 0 (Header Lower 32 bits)
    // ---------------------------------------------------------
    req = wr_control_sbtx_sequence_item#()::type_id::create("req_ph0");
    start_item(req);
    if (!req.randomize() with {
        RST_n      == 1'b1;
        lp_cfg_vld == 1'b1;
        lp_cfg     == header[31:0];
    }) `uvm_error("SEQ", "Randomization failed for Phase 0")
    finish_item(req);       p_sequencer.seqr_aport.write(req);

    
    // ---------------------------------------------------------
    // Send Phase 1 (Header Upper 32 bits)
    // ---------------------------------------------------------
    req = wr_control_sbtx_sequence_item#()::type_id::create("req_ph1");
    start_item(req);
    if (!req.randomize() with {
        RST_n      == 1'b1;
        lp_cfg_vld == 1'b1;
        lp_cfg     == header[63:32];
    }) `uvm_error("SEQ", "Randomization failed for Phase 1")
    finish_item(req);       p_sequencer.seqr_aport.write(req);

    
    // ---------------------------------------------------------
    // Send Data Phases (If applicable)
    // ---------------------------------------------------------
    if (has_data) begin
        // Send Phase 2 (Data Lower 32 bits)
        req = wr_control_sbtx_sequence_item#()::type_id::create("req_ph2");
        start_item(req);
        if (!req.randomize() with {
            RST_n      == 1'b1;
            lp_cfg_vld == 1'b1;
            lp_cfg     == data_payload[31:0];
        }) `uvm_error("SEQ", "Randomization failed for Phase 2")
        finish_item(req);       p_sequencer.seqr_aport.write(req);

        
        // Send Phase 3 (Data Upper 32 bits)
        req = wr_control_sbtx_sequence_item#()::type_id::create("req_ph3");
        start_item(req);
        if (!req.randomize() with {
            RST_n      == 1'b1;
            lp_cfg_vld == 1'b1;
            lp_cfg     == data_payload[63:32];
        }) `uvm_error("SEQ", "Randomization failed for Phase 3")
        finish_item(req);       p_sequencer.seqr_aport.write(req);

    end
    
    //Insert a single cycle of de-assertion between packets (optional idle cycle)
    req = wr_control_sbtx_sequence_item#()::type_id::create("req_idle");
    start_item(req);
    if (!req.randomize() with {
        RST_n      == 1'b1;
        lp_cfg_vld == 1'b0;
        lp_cfg     == 32'h0;
    }) `uvm_error("SEQ", "Randomization failed for Idle Phase")
    finish_item(req);       p_sequencer.seqr_aport.write(req);

    
  endtask

  task body();
    `uvm_info("SEQ", "Starting wr_control_sbtx_base_sequence...", UVM_LOW)
    req = wr_control_sbtx_sequence_item#()::type_id::create("req");
    start_item(req);
    req.randomize() with {RST_n==0;};
    finish_item(req);       p_sequencer.seqr_aport.write(req);

    // Transaction 1: Message Without Data (Start Tx Init D to C eye sweep req)
    // Opcode: 5'b10010 (MSG_NO_DATA), MsgCode: 8'h85
    send_sideband_packet(5'b10010, 8'h85, 1'b0);

    // Transaction 2: Message With 64-bit Data Payload (Tx Init D to C results resp)
    // Opcode: 5'b11011 (MSG_WITH_64B_DATA), MsgCode: 8'h8A
    send_sideband_packet(5'b11011, 8'h8A, 1'b1);

    // Transaction 3: Register Access Request (64-bit Configuration Write)
    // Opcode: 5'b01101 (CFG_WR_64B), MsgCode: 8'h00 (Not used for RAR)
    send_sideband_packet(5'b01101, 8'h00, 1'b1);

    // Transaction 4: Completion Without Data (Sideband Completion)
    // Opcode: 5'b10000 (CMPL_NO_DATA), MsgCode: 8'h00 (Not used for Completions)
    send_sideband_packet(5'b10000, 8'h00, 1'b0);

    `uvm_info("SEQ", "Finished wr_control_sbtx_base_sequence.", UVM_LOW)
  endtask

  //Reusable Tasks that child sequences will call

  virtual task drive_cycle(logic rst_n, logic vld, logic [31:0] cfg_data);
    wr_control_sbtx_sequence_item cycle_req;
    cycle_req = wr_control_sbtx_sequence_item#()::type_id::create("cycle_req");
    start_item(cycle_req);
    cycle_req.RST_n      = rst_n;
    cycle_req.lp_cfg_vld = vld;
    cycle_req.lp_cfg     = cfg_data;
    finish_item(cycle_req);
    p_sequencer.seqr_aport.write(cycle_req);

  endtask

  virtual task send_reset(int reset_cycles = 1);
    repeat (reset_cycles) begin
      drive_cycle(1'b0, 1'b0, 32'h0);
    end
  endtask

  virtual task send_packet(wr_control_sbtx_sequence_item pkt);
    // 1. Send Header Phase 0 & Phase 1
    drive_cycle(1'b1, 1'b1, pkt.full_header[31:0]);
    drive_cycle(1'b1, 1'b1, pkt.full_header[63:32]);

    // 2. Send Data Phase 0 & Phase 1 (if opcode carries data)
    if (pkt.has_data) begin
      drive_cycle(1'b1, 1'b1, pkt.data_payload[31:0]);
      drive_cycle(1'b1, 1'b1, pkt.data_payload[63:32]);
    end

    // 3. Send Trailing Idle Cycles (if pkt.num_idle_cycles > 0)
    //    If num_idle_cycles == 0, the next packet starts immediately Back-to-Back!
    repeat (pkt.num_idle_cycles) begin
      drive_cycle(1'b1, 1'b0, 32'h0);
    end
  endtask
endclass

`endif // WR_CONTROL_SBTX_BASE_SEQUENCE_SVH