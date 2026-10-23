`ifndef WR_CONTROL_SBTX_RANDOMIZED_SEQUENCE_SVH
`define WR_CONTROL_SBTX_RANDOMIZED_SEQUENCE_SVH

// Uses ONLY wr_control_sbtx_weighted_sequence_item for stimulus.
// RST_n and lp_cfg_vld come from the item's dist constraints.
class wr_control_sbtx_randomized_sequence extends wr_control_sbtx_base_sequence;
  `uvm_object_utils(wr_control_sbtx_randomized_sequence)
  `uvm_declare_p_sequencer(wr_control_sbtx_sequencer)

  int num_transactions = 150;

  function new(string name = "wr_control_sbtx_randomized_sequence");
    super.new(name);
  endfunction

  virtual task send_packet(wr_control_sbtx_sequence_item pkt);
    logic [31:0] phases[$];
    int          rst_at;

    phases.push_back(pkt.full_header[31:0]);
    phases.push_back(pkt.full_header[63:32]);
    if (pkt.has_data) begin
      phases.push_back(pkt.data_payload[31:0]);
      phases.push_back(pkt.data_payload[63:32]);
    end

    rst_at = pkt.RST_n ? phases.size() : $urandom_range(0, phases.size()-1);

    foreach (phases[i])
      drive_cycle((i < rst_at), pkt.lp_cfg_vld, phases[i]);

    repeat (pkt.num_idle_cycles)
      drive_cycle(1'b1, 1'b0, 32'h0);
  endtask

  virtual task body();
    wr_control_sbtx_weighted_sequence_item #() weighted_pkt;
    weighted_pkt = wr_control_sbtx_weighted_sequence_item#()::type_id::create("weighted_pkt");

    `uvm_info("SEQ", $sformatf("Starting wr_control_sbtx_randomized_sequence with %0d weighted packets...", num_transactions), UVM_LOW)

    send_reset(1);

    repeat (num_transactions) begin
      if (!weighted_pkt.randomize()) begin
        `uvm_error("SEQ", "Randomization failed for wr_control_sbtx_weighted_sequence_item")
        continue;
      end
      send_packet(weighted_pkt);
    end

    `uvm_info("SEQ", "Finished wr_control_sbtx_randomized_sequence.", UVM_LOW)
  endtask

endclass

`endif // WR_CONTROL_SBTX_RANDOMIZED_SEQUENCE_SVH
