`ifndef WR_CONTROL_SBTX_RAR_SEQ_SVH
`define WR_CONTROL_SBTX_RAR_SEQ_SVH

// TC_02: Constrained-Random across all 8 RAR opcodes (32b/64b Memory & Config Rd/Wr)
class wr_control_sbtx_rar_seq extends wr_control_sbtx_base_sequence;
  `uvm_object_utils(wr_control_sbtx_rar_seq)
  `uvm_declare_p_sequencer(wr_control_sbtx_sequencer)

  int num_transactions = 5000;

  function new(string name = "wr_control_sbtx_rar_seq");
    super.new(name);
  endfunction

  virtual task body();
    wr_control_sbtx_sequence_item pkt;
    pkt = wr_control_sbtx_sequence_item#()::type_id::create("pkt");
    pkt.c_default_no_idle.constraint_mode(0);

    `uvm_info(get_type_name(), "Starting TC_02 RAR Constrained-Random Sequence", UVM_LOW)
    send_reset(2);

    repeat (num_transactions) begin
      if (!pkt.randomize() with {
        opcode inside {rar_packets};
        inject_cp_err   == 1'b0;
        inject_dp_err   == 1'b0;
        num_idle_cycles dist { 0 := 60, [1:2] := 40 };
      }) `uvm_error(get_type_name(), "Randomization failed")
      send_packet(pkt);
    end

    drain_pipeline(3);
  endtask
endclass

`endif // WR_CONTROL_SBTX_RAR_SEQ_SVH

