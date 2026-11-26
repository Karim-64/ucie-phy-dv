`ifndef WR_CONTROL_SBTX_B2B_PIPELINE_SEQ_SVH
`define WR_CONTROL_SBTX_B2B_PIPELINE_SEQ_SVH

// TC_06: Zero-Bubble Back-to-Back Pipelining (num_idle_cycles == 0 across 2->2, 2->4, 4->2, 4->4)
class wr_control_sbtx_b2b_pipeline_seq extends wr_control_sbtx_base_sequence;
  `uvm_object_utils(wr_control_sbtx_b2b_pipeline_seq)
  `uvm_declare_p_sequencer(wr_control_sbtx_sequencer)

  int num_transactions = 150;

  function new(string name = "wr_control_sbtx_b2b_pipeline_seq");
    super.new(name);
  endfunction

  virtual task body();
    wr_control_sbtx_sequence_item pkt;
    pkt = wr_control_sbtx_sequence_item#()::type_id::create("pkt");
    pkt.c_default_no_err.constraint_mode(0);

    `uvm_info(get_type_name(), "Starting TC_06 Back-to-Back Pipelining CR Sequence", UVM_LOW)
    send_reset(2);

    repeat (num_transactions) begin
      if (!pkt.randomize() with {
        num_idle_cycles == 0; // Strictly continuous lp_cfg_vld across packet boundaries
        inject_cp_err   dist { 1'b0 := 85, 1'b1 := 15 };
        inject_dp_err   dist { 1'b0 := 85, 1'b1 := 15 };
      }) `uvm_error(get_type_name(), "Randomization failed")
      send_packet(pkt);
    end

    drain_pipeline(3);
  endtask
endclass

`endif // WR_CONTROL_SBTX_B2B_PIPELINE_SEQ_SVH

