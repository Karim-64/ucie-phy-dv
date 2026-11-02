`ifndef PATTERN_DETECTOR_SBRX_BASE_SEQUENCE_SVH
`define PATTERN_DETECTOR_SBRX_BASE_SEQUENCE_SVH

class Pattern_detector_SBRX_base_sequence extends uvm_sequence #(Pattern_detector_SBRX_sequence_item);
  `uvm_object_utils(Pattern_detector_SBRX_base_sequence)
  `uvm_declare_p_sequencer(Pattern_detector_SBRX_sequencer)

  logic [DATA_WIDTH-1:0] valid_pattern = 64'h5555_5555_5555_5555;
  logic [4:0] opcode  = 5'b10010;
  logic [2:0] dstid   = 3'b110;
  logic [7:0] msgcode = 8'h91;
  logic [3:0] result  = 4'b0001;
  int i;
  
  Pattern_detector_SBRX_sequence_item req;

  function new(string name = "Pattern_detector_SBRX_base_sequence");
    super.new(name);
  endfunction

  task send_item_direct(logic rstn ,logic [DATA_WIDTH-1:0] data_in ,logic valid);
    Pattern_detector_SBRX_sequence_item req;
    req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
    start_item(req);
    req.constraint_mode(0);
    if (!req.randomize() with {
       sb_sys_rst      == rstn;
       pattern_data_in == data_in;
       data_valid      == valid;
     }) `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
  endtask

  task send_SBINIT_out_of_Reset(logic rstn ,logic valid);
    Pattern_detector_SBRX_sequence_item req;
    req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
    start_item(req);
    req.constraint_mode(0);
    if (!req.randomize() with {
       sb_sys_rst                      == rstn;
       pattern_data_in[4:0]            == opcode;
       pattern_data_in[13:5]           == 9'h000;
       pattern_data_in[21:14]          == msgcode;
       pattern_data_in[28:22]          == 7'h00;
       pattern_data_in[31:29]          == 3'b010;
       pattern_data_in[39:32]          == 8'h00;
       pattern_data_in[43:40]          == result;
       pattern_data_in[55:44]          == 12'h000;
       pattern_data_in[58:56]          == dstid;
       pattern_data_in[61:59]          == 3'b000;
       pattern_data_in[62]             == (^pattern_data_in[61:0]);
       pattern_data_in[63]             == 1'b0;
       data_valid                      == valid;
     }) `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
  endtask

  task body();
    // ===========================================================================
    // CAT-01 — Reset & Initialization Behavior
    // ===========================================================================
    // TC-RST-01
    send_item_direct(0,valid_pattern,1);

    // TC-RST-02
    send_item_direct(1,valid_pattern,1);
    send_item_direct(0,valid_pattern,1);
    send_item_direct(1,valid_pattern,1);

    // TC-RST-03
    repeat(100) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.reset_recovery_and_timing.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-RST-04
    repeat(1000) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.reset_stress.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end


    // ===========================================================================
    // CAT-02 — Clock Pattern Detection — pattern_detected
    // ===========================================================================
    // TC-PAT-01
    send_item_direct(0,valid_pattern,1);
    send_item_direct(1,valid_pattern,1);
    send_item_direct(1,valid_pattern,1);
    
    // TC-PAT-02
    repeat(500) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.pattern_consecutiveness.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-PAT-03
    for(i = 0 ; i < 2*DATA_WIDTH ; i++) begin
      if(i%2 == 0) send_item_direct(1,valid_pattern,1);
      else begin
        logic [DATA_WIDTH-1:0] invalid_pattern = valid_pattern ^ (64'h1 << (i/2));
        send_item_direct(1,invalid_pattern,1);
      end
    end

    // TC-PAT-04
    send_item_direct(1, 64'h0000_0000_0000_0000, 1);
    send_item_direct(1, 64'hFFFF_FFFF_FFFF_FFFF, 1);
    send_item_direct(1, 64'hAAAA_AAAA_AAAA_AAAA, 1);
    repeat(1000) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.stress_pattern.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-PAT-05
    repeat(2) begin
      send_item_direct(1,valid_pattern,1);
    end
    send_item_direct(0,valid_pattern,1);

    repeat(4) begin
      send_item_direct(1,valid_pattern,1);
    end
    send_item_direct(0,valid_pattern,1);

    repeat(8) begin
      send_item_direct(1,valid_pattern,1);
    end
    send_item_direct(0,valid_pattern,1);


    // TC-PAT-06
    repeat(1000) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.inverted_bit_C.constraint_mode(1);
      req.interleaved_pattern_stream.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end


    // ===========================================================================
    // CAT-03 — SBINIT Out of Reset Detection — sb_o_detected
    // ===========================================================================
    // TC-SBO-01
    send_item_direct(0, 64'h0, 0);
    send_SBINIT_out_of_Reset(1, 1);

    // TC-SBO-02
    repeat(20) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.sbinit_cp_parity_error_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-SBO-03
    repeat(64) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.sbinit_invalid_opcode_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-SBO-04
    repeat(200) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.sbinit_invalid_msgcode_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-SBO-05
    repeat(32) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.sbinit_result_sweep_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-SBO-06
    repeat(100) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.sbinit_secondary_fields_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-SBO-07
    repeat(100) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.sbinit_srcid_dstid_var_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-SBO-08
    repeat(500) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.sbinit_rsvd_and_corrupted_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end


    // ===========================================================================
    // CAT-04 — Input Qualification & Enable Gating — data_valid
    // ===========================================================================
    // TC-VLD-01
    send_item_direct(0, 64'h0, 0);
    repeat(10) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.vld_pattern_ignored_when_low_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-VLD-02
    repeat(10) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.vld_sbinit_ignored_when_low_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-VLD-03
    send_item_direct(0, 64'h0, 0);
    send_item_direct(1, valid_pattern, 0);
    send_item_direct(1, valid_pattern, 1);
    send_item_direct(1, valid_pattern, 0);
    send_item_direct(1, valid_pattern, 1);
    send_item_direct(1, valid_pattern, 0);
    send_SBINIT_out_of_Reset(1, 0);
    send_SBINIT_out_of_Reset(1, 1);
    send_SBINIT_out_of_Reset(1, 0);
    repeat(100) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.vld_single_cycle_strobe_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-VLD-04
    send_item_direct(0, 64'h0, 0);
    send_item_direct(1, valid_pattern, 1);
    send_item_direct(1, valid_pattern, 1);
    send_item_direct(1, valid_pattern, 0);
    send_item_direct(1, valid_pattern, 0);
    send_SBINIT_out_of_Reset(1, 1);
    send_SBINIT_out_of_Reset(1, 0);
    send_SBINIT_out_of_Reset(1, 0);

    // TC-VLD-05
    repeat(300) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.vld_duty_cycle_modulation_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-VLD-06
    send_item_direct(0, 64'h0, 0);
    send_item_direct(1, valid_pattern, 1);
    repeat(256) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.vld_long_idle_gap_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
    send_item_direct(1, valid_pattern, 1);


    // ===========================================================================
    // CAT-05 — Output Independence, Mutual Exclusivity & Startup Sequencing
    // ===========================================================================
    // TC-SEQ-01
    send_item_direct(0, 64'h0, 0);
    repeat(2) begin
      send_item_direct(1, valid_pattern, 1);
    end
    repeat(4) begin
      send_item_direct(1, valid_pattern, 1);
    end
    send_item_direct(1, 64'h0, 0);
    repeat(4) begin
      send_SBINIT_out_of_Reset(1, 1);
    end

    // TC-SEQ-02
    send_item_direct(1, valid_pattern, 1);
    send_item_direct(1, valid_pattern, 1);
    send_SBINIT_out_of_Reset(1, 1);
    repeat(200) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.seq_mutual_exclusivity_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-SEQ-03
    send_item_direct(0, 64'h0, 0);
    send_SBINIT_out_of_Reset(1, 1);
    send_SBINIT_out_of_Reset(1, 1);

    // TC-SEQ-04
    send_item_direct(0, 64'h0, 0);
    send_item_direct(1, valid_pattern, 1);
    send_SBINIT_out_of_Reset(1, 1);
    send_item_direct(1, valid_pattern, 1);

    // TC-SEQ-05
    repeat(20) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.seq_repeated_sbinit_burst_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-SEQ-06
    send_item_direct(0, 64'h0, 0);
    send_item_direct(1, valid_pattern, 1);
    send_item_direct(1, valid_pattern, 1);
    send_SBINIT_out_of_Reset(1, 1);
    send_item_direct(1, valid_pattern, 1);
    send_item_direct(1, valid_pattern, 1);
    repeat(200) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.seq_retraining_cycle_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end


    // ===========================================================================
    // CAT-06 — Corner Cases, Aliasing & Bit-Level Stress
    // ===========================================================================
    // TC-CRN-01
    repeat(50) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.crn_near_miss_aliasing_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-CRN-02
    repeat(64) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.crn_parity_comp_double_flip_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-CRN-03
    for(i = 0; i < DATA_WIDTH; i++) begin
      send_item_direct(1, (64'h1 << i), 1);
      send_item_direct(1, ~(64'h1 << i), 1);
    end
    repeat(128) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.crn_walking_ones_zeros_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-CRN-04
    repeat(200) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.crn_other_ucie_packets_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-CRN-05
    // send_item_direct(0, 64'h0, 0);
    // repeat(10) begin
    //   send_item_direct(1, 64'h5555_5555_5555_5555, 1);
    //   send_item_direct(1, 64'hAAAA_AAAA_AAAA_AAAA, 1);
    // end
    repeat(100) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.crn_alternating_5555_aaaa_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // TC-CRN-06
    repeat(5000) begin
      req = Pattern_detector_SBRX_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.crn_full_random_soak_c.constraint_mode(1);
      if (!req.randomize()) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

  endtask
endclass

`endif // PATTERN_DETECTOR_SBRX_BASE_SEQUENCE_SVH
