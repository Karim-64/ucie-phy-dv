`ifndef DESERIALIZER_SBRX_base_SEQUENCE_SVH
`define DESERIALIZER_SBRX_base_SEQUENCE_SVH


class Deserializer_SBRX_base_sequence extends uvm_sequence #(Deserializer_SBRX_sequence_item);
  `uvm_object_utils(Deserializer_SBRX_base_sequence)
  `uvm_declare_p_sequencer(Deserializer_SBRX_sequencer)


  function new(string name = "Deserializer_SBRX_base_sequence");
    super.new(name);
  endfunction

  // ===========================================================================
  // Atomic Transaction Helpers (Item-Level)
  // ===========================================================================

  // Drives a single cycle item with explicit directed values
  task send_item_direct(logic rst = 1'b1, logic rx_data = 1'b0);
    req = Deserializer_SBRX_sequence_item::type_id::create("req");
    start_item(req);
    req.constraint_mode(0);
    if (!req.randomize() with {
      sb_sys_rst == rst;
      RXDATASB   == rx_data;
    }) begin
      `uvm_error(get_type_name(), "Randomization failed in send_item_direct")
    end
    finish_item(req);
    if (p_sequencer != null) p_sequencer.seqr_aport.write(req);
  endtask
  // Drives a single cycle item with fully randomized fields
  task send_item_random();
    req = Deserializer_SBRX_sequence_item::type_id::create("req");
    start_item(req);
    if (!req.randomize()) begin
      `uvm_error(get_type_name(), "Randomization failed in send_item_random")
    end
    finish_item(req);
    if (p_sequencer != null) p_sequencer.seqr_aport.write(req);
  endtask
  // Drives a single cycle item with directed reset/clk and randomized serial data
  task send_item_random_data(logic rst = 1'b1);
    req = Deserializer_SBRX_sequence_item::type_id::create("req");
    start_item(req);
    req.constraint_mode(0);
    if (!req.randomize() with {
      sb_sys_rst == rst;
    }) begin
      `uvm_error(get_type_name(), "Randomization failed in send_item_random_data")
    end
    finish_item(req);
    if (p_sequencer != null) p_sequencer.seqr_aport.write(req);
  endtask

    // Drives a single cycle item with randomized reset and directed clk/data
  task send_item_random_reset(logic rx_data = 1'b0);
    req = Deserializer_SBRX_sequence_item::type_id::create("req");
    start_item(req);
    req.constraint_mode(0);
    req.burst_reset.constraint_mode(1);
    if (!req.randomize() with {
      RXDATASB == rx_data;
    }) begin
      `uvm_error(get_type_name(), "Randomization failed in send_item_random_reset")
    end
    finish_item(req);
    if (p_sequencer != null) p_sequencer.seqr_aport.write(req);
  endtask
  // Drives idle cycles with specified reset value
  task send_idle_cycles(int count = 5, logic rst = 1'b1);
    repeat (count) begin
      send_item_direct(rst);
    end
  endtask

  task body();
    // ===========================================================================
    // Reset & Initialization Verification
    // ===========================================================================

    `uvm_info(get_type_name(), "==================================================", UVM_LOW)
    `uvm_info(get_type_name(), "Starting Section 1: Reset & Initialization Verification", UVM_LOW)
    `uvm_info(get_type_name(), "==================================================", UVM_LOW)

    // TC_RST_01: test_power_on_reset
     repeat (10) begin
      send_item_direct(.rst(1'b0), .rx_data(1'b0));
    end
    send_idle_cycles(5, .rst(1'b1));

    // TC_RST_02: test_mid_frame_reset_at_first_bit
    send_item_direct(.rst(1'b1), .rx_data(1'b0));
    send_item_direct(.rst(1'b1), .rx_data(1'b1));
    repeat (4) begin
      send_item_direct(.rst(1'b0), .rx_data(1'b0));
    end
    send_idle_cycles(5, .rst(1'b1));


    // TC_RST_03: test_mid_frame_reset_at_mid_word
    for (int i = 0; i < 32; i++) begin
      send_item_random_data(.rst(1'b1));
    end
    repeat (4) begin
      send_item_direct(.rst(1'b0), .rx_data(1'b0));
    end
    send_idle_cycles(5, .rst(1'b1));

    // TC_RST_04: test_mid_frame_reset_at_last_bit
    for (int i = 0; i < 63; i++) begin
      send_item_random_data(.rst(1'b1));
    end
    send_item_direct(.rst(1'b0), .rx_data(1'b1));
    repeat (4) begin
      send_item_direct(.rst(1'b0), .rx_data(1'b0));
    end
    send_idle_cycles(5, .rst(1'b1));

    // TC_RST_05: test_reset_during_cdc_handshake
    for (int i = 0; i < 64; i++) begin
      send_item_random_data(.rst(1'b1));
    end
    repeat (5) begin
      send_item_direct(.rst(1'b0), .rx_data(1'b0));
    end
    send_idle_cycles(5, .rst(1'b1));

    // TC_RST_06: test_immediate_transmission_after_reset_release
    repeat (5) begin
      send_item_direct(.rst(1'b0), .rx_data(1'b0));
    end
    for (int i = 0; i < 64; i++) begin
      send_item_random_data(.rst(1'b1));
    end
    send_idle_cycles(10, .rst(1'b1));

    // TC_RST_07: test_multiple_rapid_resets
    send_item_direct(.rst(1'b0), .rx_data(1'b1));
    send_item_direct(.rst(1'b1), .rx_data(1'b0));
    repeat (2) send_item_direct(.rst(1'b0), .rx_data(1'b1));
    repeat (2) send_item_direct(.rst(1'b1), .rx_data(1'b0));
    repeat (3) send_item_direct(.rst(1'b0), .rx_data(1'b1));
    repeat (1) send_item_direct(.rst(1'b1), .rx_data(1'b0));
    repeat (1) send_item_direct(.rst(1'b0), .rx_data(1'b1));
    repeat (2) send_item_direct(.rst(1'b1), .rx_data(1'b0));
    repeat (3) send_item_direct(.rst(1'b0), .rx_data(1'b1));
    send_idle_cycles(5, .rst(1'b1));

    // TC_RST_08: test_random_reset_during_active_streaming
    repeat (64) begin
      send_item_random_reset(.rx_data($urandom_range(0, 1)));
    end
    send_idle_cycles(5, .rst(1'b1));
    for (int i = 0; i < 64; i++) begin
      send_item_random_data(.rst(1'b1));
    end
    send_idle_cycles(10, .rst(1'b1));


    // ===========================================================================
    // 2. Bit Accumulation, Word Assembly & Endianness (64-Bit Data Path)
    // ===========================================================================

    `uvm_info(get_type_name(), "==================================================", UVM_LOW)
    `uvm_info(get_type_name(), "Starting Section 2: Bit Accumulation, Word Assembly & Endianness", UVM_LOW)
    `uvm_info(get_type_name(), "==================================================", UVM_LOW)

    // Reset to guarantee exact bit-0 alignment at start of Section 2
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_ORD_01: test_lsb_first_assembly_verification (64'h0000_0000_0000_0001)
    send_item_direct(.rst(1'b1), .rx_data(1'b1));
    repeat (63) begin
      send_item_direct(.rst(1'b1), .rx_data(1'b0));
    end

    // TC_ORD_02: test_msb_first_assembly_verification (64'h8000_0000_0000_0000)
    repeat (63) begin
      send_item_direct(.rst(1'b1), .rx_data(1'b0));
    end
    send_item_direct(.rst(1'b1), .rx_data(1'b1));

    // TC_ORD_03: test_incremental_nibble_ramp_pattern (64'h0123_4567_89AB_CDEF)
    begin
      bit [63:0] ramp_pattern = 64'h0123_4567_89AB_CDEF;
      for (int i = 0; i < 64; i++) begin
        send_item_direct(.rst(1'b1), .rx_data(ramp_pattern[i]));
      end
    end

    // TC_ORD_04: test_random_bit_order_stress
    repeat (500) begin
      for (int i = 0; i < 64; i++) begin
        send_item_random_data(.rst(1'b1));
      end
      send_idle_cycles(2, .rst(1'b1));
    end
    send_idle_cycles(10, .rst(1'b1));

    // ===========================================================================
    // 3. Output Handshake, Pulse Integrity & Data Stability (data_valid & deser_data_out)
    // ===========================================================================

    `uvm_info(get_type_name(), "==================================================", UVM_LOW)
    `uvm_info(get_type_name(), "Starting Section 3: Output Handshake, Pulse Integrity & Data Stability", UVM_LOW)
    `uvm_info(get_type_name(), "==================================================", UVM_LOW)

    // Reset to guarantee exact bit-0 alignment at start of Section 3
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_SIG_01: test_data_valid_exact_single_cycle_pulse
    repeat (100) begin
      for (int i = 0; i < 64; i++) begin
        send_item_random_data(.rst(1'b1));
      end
      send_idle_cycles(2, .rst(1'b1));
    end
    send_idle_cycles(10, .rst(1'b1));
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_SIG_02: test_data_out_stable_during_data_valid
    repeat (10) begin
      for (int i = 0; i < 64; i++) begin
        send_item_random_data(.rst(1'b1));
      end
      send_idle_cycles(5, .rst(1'b1));
    end
    send_idle_cycles(10, .rst(1'b1));
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_SIG_03: test_data_out_persistence_during_idle
    begin
      bit [63:0] persist_word = 64'hA5A5_5A5A_1234_5678;
      for (int i = 0; i < 64; i++) begin
        send_item_direct(.rst(1'b1), .rx_data(persist_word[i]));
      end
    end
    send_idle_cycles(200, .rst(1'b1));
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_SIG_04: test_data_valid_zero_during_partial_word
    for (int i = 0; i < 63; i++) begin
      send_item_random_data(.rst(1'b1));
    end
    send_idle_cycles(20, .rst(1'b1));
    send_item_random_data(.rst(1'b1));
    send_idle_cycles(10, .rst(1'b1));
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_SIG_05: test_random_traffic_pulse_integrity_monitor
    repeat (500) begin
      for (int i = 0; i < 64; i++) begin
        send_item_random_data(.rst(1'b1));
      end
      send_idle_cycles($urandom_range(1, 10), .rst(1'b1));
    end
    send_idle_cycles(10, .rst(1'b1));
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // ===========================================================================
    // 4. Boundary & Data Pattern Corner Cases (Extreme Patterns & Incomplete Frames)
    // ===========================================================================
    
    `uvm_info(get_type_name(), "==================================================", UVM_LOW)
    `uvm_info(get_type_name(), "Starting Section 4: Boundary & Data Pattern Corner Cases", UVM_LOW)
    `uvm_info(get_type_name(), "==================================================", UVM_LOW)

    // Reset to guarantee exact bit-0 alignment at start of Section 4
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_CNR_01: test_all_zeros_pattern (64'h0000_0000_0000_0000)
    repeat (64) begin
      send_item_direct(.rst(1'b1), .rx_data(1'b0));
    end

    // TC_CNR_02: test_all_ones_pattern (64'hFFFF_FFFF_FFFF_FFFF)
    repeat (64) begin
      send_item_direct(.rst(1'b1), .rx_data(1'b1));
    end

    // TC_CNR_04: test_alternating_1010_pattern (64'hAAAA_AAAA_AAAA_AAAA)
    repeat(3) begin
      bit [63:0] pattern_aa = 64'hAAAA_AAAA_AAAA_AAAA;
      for (int i = 0; i < 64; i++) begin
        send_item_direct(.rst(1'b1), .rx_data(pattern_aa[i]));
      end
    end


    // TC_CNR_03: test_alternating_0101_pattern (64'h5555_5555_5555_5555)
    repeat(5) begin
      bit [63:0] pattern_55 = 64'h5555_5555_5555_5555;
      for (int i = 0; i < 64; i++) begin
        send_item_direct(.rst(1'b1), .rx_data(pattern_55[i]));
      end
    end

    // UCIe Preamble Pattern (64'h5555_AAAA_5555_AAAA)
    begin
      bit [63:0] pattern_preamble = 64'h5555_AAAA_5555_AAAA;
      send_item_direct(.rst(1'b0), .rx_data(1'b0));
      repeat(10) begin
        for (int i = 0; i < 64; i++) begin
          send_item_direct(.rst(1'b1), .rx_data(pattern_preamble[i]));
        end
        send_idle_cycles(10, .rst(1'b1));
      end
    end

    // TC_CNR_05: test_walking_ones_pattern
    for (int k = 0; k < 64; k++) begin
      bit [63:0] walking_one = (64'h1 << k);
      for (int i = 0; i < 64; i++) begin
        send_item_direct(.rst(1'b1), .rx_data(walking_one[i]));
      end
    end
    send_idle_cycles(10, .rst(1'b1));
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_CNR_06: test_walking_zeros_pattern
    for (int k = 0; k < 64; k++) begin
      bit [63:0] walking_zero = ~(64'h1 << k);
      for (int i = 0; i < 64; i++) begin
        send_item_direct(.rst(1'b1), .rx_data(walking_zero[i]));
      end
    end
    send_idle_cycles(10, .rst(1'b1));
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_CNR_07: test_consecutive_identical_words
    begin
      bit [63:0] cafe_word = 64'hCAFE_BABE_DEAD_BEEF;
      repeat (5) begin
        for (int i = 0; i < 64; i++) begin
          send_item_direct(.rst(1'b1), .rx_data(cafe_word[i]));
        end
      end
    end
    send_idle_cycles(10, .rst(1'b1));
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_CNR_08: test_full_bus_toggle_back_to_back
    begin
      bit [63:0] zeros_word = 64'h0000_0000_0000_0000;
      bit [63:0] ones_word  = 64'hFFFF_FFFF_FFFF_FFFF;
      for (int i = 0; i < 64; i++) begin
        send_item_direct(.rst(1'b1), .rx_data(zeros_word[i]));
      end
      for (int i = 0; i < 64; i++) begin
        send_item_direct(.rst(1'b1), .rx_data(ones_word[i]));
      end
    end
    send_idle_cycles(10, .rst(1'b1));
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_CNR_09: test_sparse_isolated_nibble_patterns
    begin
      bit [63:0] sparse_words[3] = '{
        64'h0000_0000_0000_000F,
        64'hF000_0000_0000_0000,
        64'h0000_00FF_0000_0000
      };
      foreach (sparse_words[w]) begin
        for (int i = 0; i < 64; i++) begin
          send_item_direct(.rst(1'b1), .rx_data(sparse_words[w][i]));
        end
      end
    end
    send_idle_cycles(10, .rst(1'b1));
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_CNR_10: test_incomplete_word_single_bit
    send_item_direct(.rst(1'b1), .rx_data(1'b1));
    send_idle_cycles(100, .rst(1'b1));
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_CNR_11: test_incomplete_word_63_bits
    for (int i = 0; i < 63; i++) begin
      send_item_random_data(.rst(1'b1));
    end
    send_idle_cycles(100, .rst(1'b1));
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_CNR_12: test_resume_after_incomplete_word
    for (int i = 0; i < 63; i++) begin
      send_item_random_data(.rst(1'b1));
    end
    send_idle_cycles(50, .rst(1'b1));
    send_item_random_data(.rst(1'b1));
    for (int i = 0; i < 64; i++) begin
      send_item_random_data(.rst(1'b1));
    end
    send_idle_cycles(10, .rst(1'b1));

    // ===========================================================================
    // 5. Protocol Framing, Inter-Packet Timing & Line Idle States
    // ===========================================================================

    `uvm_info(get_type_name(), "==================================================", UVM_LOW)
    `uvm_info(get_type_name(), "Starting Section 5:  Protocol Framing, Inter-Packet Timing & Line Idle States", UVM_LOW)
    `uvm_info(get_type_name(), "==================================================", UVM_LOW)

    // Reset to guarantee exact bit-0 alignment at start of Section 5
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_FRM_01: test_back_to_back_continuous_streaming
    repeat (100) begin
      for (int i = 0; i < 64; i++) begin
        send_item_random_data(.rst(1'b1));
      end
    end
    send_idle_cycles(10, .rst(1'b1));
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_FRM_02: test_minimum_inter_word_gap_1cycle
    repeat (20) begin
      for (int i = 0; i < 64; i++) begin
        send_item_random_data(.rst(1'b1));
      end
    end
    send_idle_cycles(10, .rst(1'b1));
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_FRM_03: test_variable_random_inter_word_gaps
    repeat (50) begin
      for (int i = 0; i < 64; i++) begin
        send_item_random_data(.rst(1'b1));
      end
      send_idle_cycles($urandom_range(1, 64), .rst(1'b1));
    end
    send_idle_cycles(10, .rst(1'b1));
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_FRM_04: test_extended_idle_between_words
    for (int i = 0; i < 64; i++) begin
      send_item_random_data(.rst(1'b1));
    end
    send_idle_cycles(1000, .rst(1'b1));
    for (int i = 0; i < 64; i++) begin
      send_item_random_data(.rst(1'b1));
    end
    send_idle_cycles(10, .rst(1'b1));

    // ===========================================================================
    // 6. Constrained Random & Stress Verification (Random Stimulus & Phase Variations)
    // ===========================================================================

    `uvm_info(get_type_name(), "==================================================", UVM_LOW)
    `uvm_info(get_type_name(), "Starting Section 6:  Constrained Random & Stress Verification", UVM_LOW)
    `uvm_info(get_type_name(), "==================================================", UVM_LOW)

    // Reset to guarantee exact bit-0 alignment at start of Section 6
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_RND_01: test_random_data_fixed_delays
    repeat (100) begin
      for (int i = 0; i < 64; i++) begin
        send_item_random_data(.rst(1'b1));
      end
      send_idle_cycles(5, .rst(1'b1));
    end
    send_idle_cycles(10, .rst(1'b1));
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_RND_02: test_random_data_random_delays
    repeat (100) begin
      for (int i = 0; i < 64; i++) begin
        send_item_random_data(.rst(1'b1));
      end
      send_idle_cycles($urandom_range(0, 50), .rst(1'b1));
    end
    send_idle_cycles(10, .rst(1'b1));
    send_item_direct(.rst(1'b0), .rx_data(1'b0));

    // TC_RND_03: test_high_stress_back_to_back_burst
    repeat (500) begin
      for (int i = 0; i < 64; i++) begin
        send_item_random_data(.rst(1'b1));
      end
    end
    send_idle_cycles(10, .rst(1'b1));

  endtask

endclass

`endif // DESERIALIZER_SBRX_base_SEQUENCE_SVH
