`ifndef WR_CONTROL_SBTX_MID_PKT_RST_SEQ_SVH
`define WR_CONTROL_SBTX_MID_PKT_RST_SEQ_SVH

// TC_07: Mid-Packet Async Reset after Phase 0, Phase 1, and Phase 2 + immediate clean recovery
class wr_control_sbtx_mid_pkt_rst_seq extends wr_control_sbtx_base_sequence;
  `uvm_object_utils(wr_control_sbtx_mid_pkt_rst_seq)
  `uvm_declare_p_sequencer(wr_control_sbtx_sequencer)

  int num_iterations = 24;

  function new(string name = "wr_control_sbtx_mid_pkt_rst_seq");
    super.new(name);
  endfunction

  virtual task send_aborted_packet(wr_control_sbtx_sequence_item pkt, int abort_after_phase);
    logic [31:0] phases[$];

    phases.push_back(pkt.full_header[31:0]);
    phases.push_back(pkt.full_header[63:32]);
    if (pkt.has_data) begin
      phases.push_back(pkt.data_payload[31:0]);
      phases.push_back(pkt.data_payload[63:32]);
    end

    for (int i = 0; i < abort_after_phase && i < phases.size(); i++) begin
      drive_cycle(1'b1, 1'b1, phases[i]);
    end

    // Assert async reset mid-packet (with vld randomly 0 or 1), then release cleanly
    drive_cycle(1'b0, $urandom_range(0, 1), $urandom());
    drive_cycle(1'b1, 1'b0, 32'h0000_0000);
  endtask

  virtual task body();
    wr_control_sbtx_sequence_item abort_pkt;
    wr_control_sbtx_sequence_item clean_pkt;
    int cut_phase;

    abort_pkt = wr_control_sbtx_sequence_item#()::type_id::create("abort_pkt");
    clean_pkt = wr_control_sbtx_sequence_item#()::type_id::create("clean_pkt");

    `uvm_info(get_type_name(), "Starting TC_07 Mid-Packet Reset & Recovery CR Sequence", UVM_LOW)
    send_reset(2);

    for (int iter = 0; iter < num_iterations; iter++) begin
      if (!abort_pkt.randomize() with {
        inject_cp_err == 1'b0;
        inject_dp_err == 1'b0;
      }) `uvm_error(get_type_name(), "Randomization failed for abort_pkt")

      // Abort after 1 phase (HP0) for 2-phase, or after 1/2/3 phases (HP0/HP1/DP0) for 4-phase
      cut_phase = abort_pkt.has_data ? $urandom_range(1, 3) : 1;
      send_aborted_packet(abort_pkt, cut_phase);

      // Immediately follow with a clean packet to verify phase framing resynchronized to HP0
      if (!clean_pkt.randomize() with {
        inject_cp_err   == 1'b0;
        inject_dp_err   == 1'b0;
        num_idle_cycles == 1;
      }) `uvm_error(get_type_name(), "Randomization failed for clean_pkt")
      send_packet(clean_pkt);
    end

    drain_pipeline(3);
  endtask
endclass

`endif // WR_CONTROL_SBTX_MID_PKT_RST_SEQ_SVH

