`ifndef WR_CONTROL_SBTX_COMP_SEQ_SVH
`define WR_CONTROL_SBTX_COMP_SEQ_SVH

// TC_04: Constrained-Random Completions (without data, 32b data, 64b data; clean + errored)
class wr_control_sbtx_comp_seq extends wr_control_sbtx_base_sequence;
  `uvm_object_utils(wr_control_sbtx_comp_seq)
  `uvm_declare_p_sequencer(wr_control_sbtx_sequencer)

  int num_transactions = 1000;

  function new(string name = "wr_control_sbtx_comp_seq");
    super.new(name);
  endfunction

  virtual task body();
    wr_control_sbtx_sequence_item pkt;
    pkt = wr_control_sbtx_sequence_item#()::type_id::create("pkt");
    pkt.c_default_no_err.constraint_mode(0);
    pkt.c_default_no_idle.constraint_mode(0);

    `uvm_info(get_type_name(), "Starting TC_04 Completion Handling CR Sequence", UVM_LOW)
    send_reset(2);

    repeat (num_transactions) begin
      if (!pkt.randomize() with {
        opcode inside {comp_packets};
        inject_cp_err   dist { 1'b0 := 70, 1'b1 := 30 };
        inject_dp_err   dist { 1'b0 := 70, 1'b1 := 30 };
        num_idle_cycles dist { 0 := 60, [1:2] := 40 };
      }) `uvm_error(get_type_name(), "Randomization failed")
      send_packet(pkt);
    end

    drain_pipeline(3);
  endtask
endclass

`endif // WR_CONTROL_SBTX_COMP_SEQ_SVH

