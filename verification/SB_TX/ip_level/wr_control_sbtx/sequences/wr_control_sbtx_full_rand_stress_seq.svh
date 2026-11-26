`ifndef WR_CONTROL_SBTX_FULL_RAND_STRESS_SEQ_SVH
`define WR_CONTROL_SBTX_FULL_RAND_STRESS_SEQ_SVH

// TC_09: Full Weighted Constrained-Random Stress Sequence
// Mixes all 13 opcodes, all req_resp/non_req_resp msgcodes, CP/DP parity errors,
// back-to-back bursts, idle gaps with bus noise, and occasional mid-packet resets.
class wr_control_sbtx_full_rand_stress_seq extends wr_control_sbtx_base_sequence;
  `uvm_object_utils(wr_control_sbtx_full_rand_stress_seq)
  `uvm_declare_p_sequencer(wr_control_sbtx_sequencer)

  int num_transactions = 5000;

  function new(string name = "wr_control_sbtx_full_rand_stress_seq");
    super.new(name);
  endfunction

  virtual task body();
    wr_control_sbtx_sequence_item pkt;
    int msg_bucket;
    int do_mid_rst;
    int cut_phase;
    logic [31:0] phases[$];

    pkt = wr_control_sbtx_sequence_item#()::type_id::create("pkt");
    pkt.c_default_no_err.constraint_mode(0);
    pkt.c_default_no_idle.constraint_mode(0);

    `uvm_info(get_type_name(), $sformatf("Starting TC_09 Full Rand Stress Sequence (%0d packets)", num_transactions), UVM_LOW)
    send_reset(2);

    repeat (num_transactions) begin
      msg_bucket = $urandom_range(0, 99);
      do_mid_rst = ($urandom_range(0, 99) < 3); // ~3% chance of mid-packet reset

      if (!pkt.randomize() with {
        opcode dist {
          SB_MEM_RD_32B         := 6,
          SB_CFG_RD_32B         := 6,
          SB_MEM_RD_64B         := 6,
          SB_CFG_RD_64B         := 6,
          SB_MEM_WR_32B         := 6,
          SB_CFG_WR_32B         := 6,
          SB_MEM_WR_64B         := 6,
          SB_CFG_WR_64B         := 6,
          SB_CMPL_NO_DATA       := 8,
          SB_CMPL_WITH_32B_DATA := 7,
          SB_CMPL_WITH_64B_DATA := 7,
          SB_MSG_NO_DATA        := 15,
          SB_MSG_WITH_64B_DATA  := 15
        };

        if (opcode inside {msg_packets}) {
          if (msg_bucket < 35)
            msgcode inside {d2d_req_resp_msgcodes};
          else if (msg_bucket < 70)
            msgcode inside {req_resp_msgcodes};
          else
            msgcode inside {non_req_resp_msgcodes};
        }

        {inject_cp_err, inject_dp_err} dist {
          2'b00 := 70, // Clean
          2'b10 := 12, // CP error only
          2'b01 := 12, // DP error only
          2'b11 := 6   // CP + DP error
        };

        num_idle_cycles dist {
          0     := 70,
          [1:3] := 30
        };
      }) begin
        `uvm_error(get_type_name(), "Randomization failed in full_rand_stress_seq")
        continue;
      end

      if (do_mid_rst) begin
        phases.delete();
        phases.push_back(pkt.full_header[31:0]);
        phases.push_back(pkt.full_header[63:32]);
        if (pkt.has_data) begin
          phases.push_back(pkt.data_payload[31:0]);
          phases.push_back(pkt.data_payload[63:32]);
        end
        cut_phase = pkt.has_data ? $urandom_range(1, 3) : 1;
        for (int i = 0; i < cut_phase; i++)
          drive_cycle(1'b1, 1'b1, phases[i]);
        drive_cycle(1'b0, $urandom_range(0, 1), $urandom());
        drive_cycle(1'b1, 1'b0, 32'h0000_0000);
      end else begin
        send_packet(pkt, $urandom());
      end
    end

    drain_pipeline(3);
    `uvm_info(get_type_name(), "Finished TC_09 Full Rand Stress Sequence", UVM_LOW)
  endtask
endclass

`endif // WR_CONTROL_SBTX_FULL_RAND_STRESS_SEQ_SVH

