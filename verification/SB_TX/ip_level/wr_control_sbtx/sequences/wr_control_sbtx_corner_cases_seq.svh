`ifndef WR_CONTROL_SBTX_CORNER_CASES_SEQ_SVH
`define WR_CONTROL_SBTX_CORNER_CASES_SEQ_SVH

// TC_08: RAR BE/MsgCode Collision, Reserved Opcodes, and Idle Bus Noise Gaps
class wr_control_sbtx_corner_cases_seq extends wr_control_sbtx_base_sequence;
  `uvm_object_utils(wr_control_sbtx_corner_cases_seq)
  `uvm_declare_p_sequencer(wr_control_sbtx_sequencer)

  function new(string name = "wr_control_sbtx_corner_cases_seq");
    super.new(name);
  endfunction

  virtual task body();
    wr_control_sbtx_sequence_item pkt;
    pkt = wr_control_sbtx_sequence_item#()::type_id::create("pkt");
    pkt.c_default_no_idle.constraint_mode(0);

    `uvm_info(get_type_name(), "Starting TC_08 Corner Cases CR Sequence", UVM_LOW)
    send_reset(2);

    // -------------------------------------------------------------------------
    // Part 1: RAR Byte-Enable [21:14] colliding with Req/Resp MsgCodes (Req_Resp_Marker must be 0!)
    // -------------------------------------------------------------------------
    repeat (24) begin
      if (!pkt.randomize() with {
        opcode inside {rar_packets};
        be     inside {req_resp_msgcodes};
        inject_cp_err   == 1'b0;
        inject_dp_err   == 1'b0;
        num_idle_cycles dist { 0 := 50, [1:3] := 50 };
      }) `uvm_error(get_type_name(), "Randomization failed in RAR BE collision")
      send_packet(pkt, $urandom()); // Drive random noise on lp_cfg while lp_cfg_vld == 0
    end

    drain_pipeline(2);

    // -------------------------------------------------------------------------
    // Part 2: Reserved / Illegal 5-bit Opcodes (SVA-safe 2-cycle header framing)
    // -------------------------------------------------------------------------
    repeat (10) begin
      if (!pkt.randomize() with {
        use_raw_opcode == 1'b1;
        !(raw_opcode inside {rar_packets, comp_packets, msg_packets, 5'b00011, 5'b01011});
        inject_cp_err   == 1'b0;
        inject_dp_err   == 1'b0;
        num_idle_cycles == 2;
      }) `uvm_error(get_type_name(), "Randomization failed in Reserved Opcode")
      send_packet(pkt, $urandom());

      // Reset cleanly so if buggy RTL treated reserved opcode as 4-phase, next iteration starts aligned
      send_reset(1);
    end

    // -------------------------------------------------------------------------
    // Part 3: Varied Inter-Packet Idle Gaps (1..5 cycles) with Random Bus Noise
    // -------------------------------------------------------------------------
    repeat (20) begin
      if (!pkt.randomize() with {
        use_raw_opcode  == 1'b0;
        inject_cp_err   == 1'b0;
        inject_dp_err   == 1'b0;
        num_idle_cycles inside {[1:5]};
      }) `uvm_error(get_type_name(), "Randomization failed in Idle Gap Noise")
      send_packet(pkt, $urandom());
    end

    drain_pipeline(3);
  endtask
endclass

`endif // WR_CONTROL_SBTX_CORNER_CASES_SEQ_SVH

