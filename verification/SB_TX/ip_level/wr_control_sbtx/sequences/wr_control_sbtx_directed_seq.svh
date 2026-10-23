class wr_control_sbtx_directed_seq extends wr_control_sbtx_base_sequence;
  `uvm_object_utils(wr_control_sbtx_directed_seq)
  `uvm_declare_p_sequencer(wr_control_sbtx_sequencer)


  function new(string name = "wr_control_sbtx_directed_seq");
    super.new(name);
  endfunction

  virtual task body();
    wr_control_sbtx_sequence_item pkt;
    pkt = wr_control_sbtx_sequence_item#()::type_id::create("pkt");

    send_reset(1);

    // 1.Valid MSG_NO_DATA with Req_Resp_Marker = 1 (e.g., msgcode 8'h85)
    if (!pkt.randomize() with {
        opcode          == MSG_NO_DATA;
        msgcode         == 8'h85;
        
    }) `uvm_error("SEQ", "Randomization failed")
    send_packet(pkt);

    // 2. Directed Packet: 64b Config Write with Control Parity Error (CP Error)
    if (!pkt.randomize() with {
        opcode          == CFG_WR_64B;
        dstid           == 3'b100; // Remote RAR
        inject_cp_err   == 1'b1;   // Inject CP Error!
        
    }) `uvm_error("SEQ", "Randomization failed")
    send_packet(pkt);

    // 3. Directed Packet: Completion With Data + Data Parity Error (Verify Error_Handler stays 0!)
    if (!pkt.randomize() with {
        opcode          == CMPL_WITH_64B_DATA;
        inject_dp_err   == 1'b1;   // Inject DP Error!
        
    }) `uvm_error("SEQ", "Randomization failed")
    send_packet(pkt);

    // 4. Non-Completion Packet with both Control Parity and Data Parity Errors
    // Note: Must use an opcode with a payload so DP is evaluated.

    if (!pkt.randomize() with {
       opcode == CFG_WR_64B; 
       dstid == 3'b000; 
       inject_cp_err == 1'b1; 
       inject_dp_err == 1'b1; 
        }) `uvm_error("SEQ", "Randomization failed") send_packet(pkt);

   // 5. Unacknowledged Error Escalation Message ({ErrMsg}) 
   if (!pkt.randomize() with {
     opcode == MSG_NO_DATA; 
     msgcode == 8'h09; 
      }) `uvm_error("SEQ", "Randomization failed") send_packet(pkt);

   // 6. Parameter Exchange Message ({AdvCap.Adapter}) 
   if (!pkt.randomize() with {
     opcode == MSG_WITH_64B_DATA; 
     msgcode == 8'h01; 
      }) `uvm_error("SEQ", "Randomization failed") send_packet(pkt);

    // Valid asserted while reset is asserted (RST_n=0, lp_cfg_vld=1)
    drive_cycle(1'b0, 1'b1, 32'hA5A5_5A5A);

    //De-asserting valid signal
    drive_cycle(1'b1, 1'b0, 32'h0);



  endtask
endclass