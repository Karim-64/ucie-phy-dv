`ifndef WR_CONTROL_SBTX_PARITY_ERR_SEQ_SVH
`define WR_CONTROL_SBTX_PARITY_ERR_SEQ_SVH

// TC_05: Constrained-Random CP-only, DP-only (including 2-phase DP=1), and CP+DP Parity Errors
class wr_control_sbtx_parity_err_seq extends wr_control_sbtx_base_sequence;
  `uvm_object_utils(wr_control_sbtx_parity_err_seq)
  `uvm_declare_p_sequencer(wr_control_sbtx_sequencer)

  int num_transactions = 2000;

  function new(string name = "wr_control_sbtx_parity_err_seq");
    super.new(name);
  endfunction

  virtual task body();
    wr_control_sbtx_sequence_item pkt;
    pkt = wr_control_sbtx_sequence_item#()::type_id::create("pkt");
    pkt.c_default_no_err.constraint_mode(0);
    pkt.c_default_no_idle.constraint_mode(0);

    `uvm_info(get_type_name(), "Starting TC_05 Parity Error Detection CR Sequence", UVM_LOW)
    send_reset(2);

    repeat (num_transactions) begin
      if (!pkt.randomize() with {
        // Guarantee balanced mix of CP-only, DP-only, Both, and Clean recovery packets
        {inject_cp_err, inject_dp_err} dist {
          2'b10 := 30, // CP error only
          2'b01 := 30, // DP error only (covers 2-phase DP=1 & 4-phase DP mismatch)
          2'b11 := 20, // Simultaneous CP + DP error
          2'b00 := 20  // Clean packets interleaved to verify clean recovery
        };
        num_idle_cycles dist { 0 := 60, [1:2] := 40 };
      }) `uvm_error(get_type_name(), "Randomization failed")
      send_packet(pkt);
    end

    drain_pipeline(3);
  endtask
endclass

`endif // WR_CONTROL_SBTX_PARITY_ERR_SEQ_SVH

