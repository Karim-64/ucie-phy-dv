`ifndef WR_CONTROL_SBTX_DIRECTED_SEQ_SVH
`define WR_CONTROL_SBTX_DIRECTED_SEQ_SVH

class wr_control_sbtx_directed_seq extends wr_control_sbtx_base_sequence;
  `uvm_object_utils(wr_control_sbtx_directed_seq)
  `uvm_declare_p_sequencer(wr_control_sbtx_sequencer)

  function new(string name = "wr_control_sbtx_directed_seq");
    super.new(name);
  endfunction

  virtual task body();
    wr_control_sbtx_sequence_item pkt;
    pkt = wr_control_sbtx_sequence_item#()::type_id::create("pkt");

    send_reset(2);

    // 1. Valid MSG_NO_DATA with Req_Resp_Marker = 1 (D2D0 Link Mgmt Req)
    if (!pkt.randomize() with {
      opcode  == SB_MSG_NO_DATA;
      msgcode == SB_D2D0_LINK_MGMT_REQ;
    }) `uvm_error("SEQ", "Randomization failed")
    send_packet(pkt);

    // 2. 64b Config Write with Control Parity Error (CP Error)
    if (!pkt.randomize() with {
      opcode        == SB_CFG_WR_64B;
      dstid         == 3'b100;
      inject_cp_err == 1'b1;
    }) `uvm_error("SEQ", "Randomization failed")
    send_packet(pkt);

    // 3. Completion With Data + Data Parity Error (Error_Handler must stay 0)
    if (!pkt.randomize() with {
      opcode        == SB_CMPL_WITH_64B_DATA;
      inject_dp_err == 1'b1;
    }) `uvm_error("SEQ", "Randomization failed")
    send_packet(pkt);

    // 4. Non-Completion 4-Phase Packet with both CP and DP Errors
    if (!pkt.randomize() with {
      opcode        == SB_CFG_WR_64B;
      dstid         == 3'b010;
      inject_cp_err == 1'b1;
      inject_dp_err == 1'b1;
    }) `uvm_error("SEQ", "Randomization failed")
    send_packet(pkt);

    // 5. 2-Phase Packet with DP = 1 Error (header-only must have DP == 0)
    if (!pkt.randomize() with {
      opcode        == SB_MEM_RD_32B;
      inject_dp_err == 1'b1;
    }) `uvm_error("SEQ", "Randomization failed")
    send_packet(pkt);

    // 6. Non-Req/Resp Error Message (ErrMsg)
    if (!pkt.randomize() with {
      opcode  == SB_MSG_NO_DATA;
      msgcode == SB_ERR_MSG;
    }) `uvm_error("SEQ", "Randomization failed")
    send_packet(pkt);

    // 7. 4-Phase Message With Data followed by 2 idle drain cycles before reset test
    if (!pkt.randomize() with {
      opcode          == SB_MSG_WITH_64B_DATA;
      msgcode         == SB_RDI_LINK_MGMT_REQ;
      num_idle_cycles == 2;
    }) `uvm_error("SEQ", "Randomization failed")
    send_packet(pkt);

    // 8. Valid asserted while reset is asserted (RST_n=0, lp_cfg_vld=1)
    drive_cycle(1'b0, 1'b1, 32'hA5A5_5A5A);
    drive_cycle(1'b1, 1'b0, 32'h0000_0000);

    drain_pipeline(2);
  endtask
endclass

`endif // WR_CONTROL_SBTX_DIRECTED_SEQ_SVH
