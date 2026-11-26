`ifndef WR_CONTROL_SBTX_MSG_SEQ_SVH
`define WR_CONTROL_SBTX_MSG_SEQ_SVH

// TC_03: Constrained-Random Sideband Messages (MSG_NO_DATA & MSG_WITH_64B_DATA x Req/Resp & Non-Req/Resp)
class wr_control_sbtx_msg_seq extends wr_control_sbtx_base_sequence;
  `uvm_object_utils(wr_control_sbtx_msg_seq)
  `uvm_declare_p_sequencer(wr_control_sbtx_sequencer)

  int num_transactions = 5000;

  function new(string name = "wr_control_sbtx_msg_seq");
    super.new(name);
  endfunction

  virtual task body();
    wr_control_sbtx_sequence_item pkt;
    int msg_bucket;
    pkt = wr_control_sbtx_sequence_item#()::type_id::create("pkt");
    pkt.c_default_no_idle.constraint_mode(0);

    `uvm_info(get_type_name(), "Starting TC_03 Sideband Messages & Req/Resp CR Sequence", UVM_LOW)
    send_reset(2);

    repeat (num_transactions) begin
      msg_bucket = $urandom_range(0, 99);
      if (!pkt.randomize() with {
        opcode inside {msg_packets};
        if (msg_bucket < 35)
          msgcode inside {d2d_req_resp_msgcodes};
        else if (msg_bucket < 70)
          msgcode inside {req_resp_msgcodes};
        else
          msgcode inside {non_req_resp_msgcodes};
        inject_cp_err   == 1'b0;
        inject_dp_err   == 1'b0;
        num_idle_cycles dist { 0 := 60, [1:2] := 40 };
      }) `uvm_error(get_type_name(), "Randomization failed")
      send_packet(pkt);
    end

    drain_pipeline(3);
  endtask
endclass

`endif // WR_CONTROL_SBTX_MSG_SEQ_SVH

