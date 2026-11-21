`ifndef PATTERN_DETECTOR_SBRX_SEQUENCE_ITEM_SVH
`define PATTERN_DETECTOR_SBRX_SEQUENCE_ITEM_SVH

class Pattern_detector_SBRX_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(Pattern_detector_SBRX_sequence_item)

  localparam [DATA_WIDTH-1:0] valid_pattern = 64'h5555_5555_5555_5555;
  localparam [DATA_WIDTH-1:0] SBINIT_out_of_Reset = 64'h4600_0100_4024_4012;
  localparam [4:0] opcode  = 5'b10010;
  localparam [2:0] dstid   = 3'b110;
  localparam [7:0] msgcode = 8'h91;
  localparam [3:0] result  = 4'b0001;
  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic sb_sys_rst;
  rand logic [DATA_WIDTH-1:0] pattern_data_in;
  rand logic data_valid;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic pattern_detected;
  logic sb_o_detected;

  rand logic [DATA_WIDTH-1:0] inverted_pattern;
  rand bit [5:0] flip_bit;
  randc bit [4:0] bad_opcode_c;
  randc bit [3:0] result_sweep_c;
  randc bit [2:0] msgcode_flip_bit_c;
  randc bit [5:0] walk_bit_c;


  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "Pattern_detector_SBRX_sequence_item");
    super.new(name);
  endfunction

  // =========================================================================
  //  CAT-01 Constraints
  // =========================================================================
  constraint reset_recovery_and_timing{
    sb_sys_rst dist {1'b0:=50 , 1'b1:=50};
    data_valid == 1'b1;
    pattern_data_in dist {valid_pattern :=70 , SBINIT_out_of_Reset :=30};
  }

  constraint reset_stress{
    sb_sys_rst dist {1'b0:=70 , 1'b1:=30};
    data_valid dist {1'b0:=30 , 1'b1:=70};
    pattern_data_in dist {valid_pattern :=35 , SBINIT_out_of_Reset :=35 ,
                          [64'h0 : 64'hFFFF_FFFF_FFFF_FFFF] := 30};
  }

  // =========================================================================
  //  CAT-02 Constraints
  // =========================================================================
  constraint pattern_consecutiveness{
    sb_sys_rst == 1'b1;
    data_valid dist {1'b0:=70 , 1'b1:=30};
    pattern_data_in == valid_pattern;
  }

  constraint stress_pattern{
    sb_sys_rst == 1'b1;
    data_valid == 1'b1;
    pattern_data_in inside {[64'h0 : 64'hFFFF_FFFF_FFFF_FFFF]};
  }

  constraint inverted_bit_C {
    flip_bit inside {[0:63]};
    inverted_pattern == (64'h5555_5555_5555_5555 ^ (64'h1 << flip_bit));
  }

  constraint interleaved_pattern_stream{
    sb_sys_rst == 1'b1;
    data_valid == 1'b1;
    pattern_data_in dist {valid_pattern :=40 , inverted_pattern:=20 , [64'h0 : 64'hFFFF_FFFF_FFFF_FFFF] :=40};
  }

  // =========================================================================
  //  CAT-03 Constraints — SBINIT Out of Reset Detection (sb_o_detected)
  // =========================================================================

  constraint sbinit_cp_parity_error_c {
    sb_sys_rst              == 1'b1;
    data_valid              == 1'b1;
    pattern_data_in[4:0]    == opcode;
    pattern_data_in[21:14]  == msgcode;
    pattern_data_in[31:29]  == 3'b010;
    pattern_data_in[39:32]  == 8'h00;
    pattern_data_in[43:40]  == result;
    pattern_data_in[58:56]  == dstid;
    pattern_data_in[62]     != (^pattern_data_in[61:0]); // Odd parity (CP error)
  }

  constraint sbinit_invalid_opcode_c {
    sb_sys_rst              == 1'b1;
    data_valid              == 1'b1;
    bad_opcode_c            != opcode;
    pattern_data_in[4:0]    == bad_opcode_c;
    pattern_data_in[21:14]  == msgcode;
    pattern_data_in[43:40]  == result;
    pattern_data_in[58:56]  == 3'b110;
    pattern_data_in[62]     == (^pattern_data_in[61:0]);
  }

  constraint sbinit_invalid_msgcode_c {
    sb_sys_rst              == 1'b1;
    data_valid              == 1'b1;
    pattern_data_in[4:0]    == opcode;
    pattern_data_in[21:14]  != msgcode;
    pattern_data_in[21:14] dist {
      8'h95 := 20, // {SBINIT done req}
      8'h9A := 20, // {SBINIT done resp}
      8'h00 := 15, // {Nop.Crd}
      8'h85 := 15, // {LFSR_clear_error req}
      8'hA5 := 15, // {MBINIT.CAL Done req}
      [8'h01:8'hFF] := 15
    };
    pattern_data_in[43:40]  == result;
    pattern_data_in[58:56]  == 3'b110;
    pattern_data_in[62]     == (^pattern_data_in[61:0]);
  }

  constraint sbinit_result_sweep_c {
    sb_sys_rst              == 1'b1;
    data_valid              == 1'b1;
    pattern_data_in[4:0]    == opcode;
    pattern_data_in[21:14]  == msgcode;
    pattern_data_in[39:32]  == 8'h00;
    pattern_data_in[43:40]  == result_sweep_c;
    pattern_data_in[58:56]  == 3'b110;
    pattern_data_in[62]     == (^pattern_data_in[61:0]);
  }

  constraint sbinit_secondary_fields_c {
    sb_sys_rst              == 1'b1;
    data_valid              == 1'b1;
    pattern_data_in[4:0]    == opcode;
    pattern_data_in[21:14]  == msgcode;
    pattern_data_in[43:40]  == result;
    pattern_data_in[58:56]  == 3'b110;
    (pattern_data_in[39:32] != 8'h00) || (pattern_data_in[63] == 1'b1);
    pattern_data_in[62]     == (^pattern_data_in[61:0]);
  }

  constraint sbinit_srcid_dstid_var_c {
    sb_sys_rst              == 1'b1;
    data_valid              == 1'b1;
    pattern_data_in[4:0]    == opcode;
    pattern_data_in[21:14]  == msgcode;
    pattern_data_in[39:32]  == 8'h00;
    pattern_data_in[43:40]  == result;
    (pattern_data_in[31:29] != 3'b010) || (pattern_data_in[58:56] != 3'b110);
    pattern_data_in[62]     == (^pattern_data_in[61:0]);
  }

  constraint sbinit_rsvd_and_corrupted_c {
    sb_sys_rst              == 1'b1;
    data_valid              == 1'b1;
    pattern_data_in         != valid_pattern;
    pattern_data_in[4:0]    dist {opcode := 70, [5'b00000:5'b11111] := 30};
    pattern_data_in[21:14]  dist {msgcode    := 70, [8'h00:8'hFF]       := 30};
    pattern_data_in[58:56]  dist {3'b110   := 70, [3'b000:3'b111]     := 30};
    pattern_data_in[43:40]  dist {result  := 70, [4'h0:4'hF]         := 30};
    (pattern_data_in[13:5] != 9'h0) || (pattern_data_in[28:22] != 7'h0) ||
    (pattern_data_in[55:44] != 12'h0) || (pattern_data_in[61:59] != 3'b0);
  }

  // =========================================================================
  //  CAT-04 Constraints — Input Qualification & Enable Gating (data_valid)
  // =========================================================================

  constraint vld_pattern_ignored_when_low_c {
    sb_sys_rst      == 1'b1;
    data_valid      == 1'b0;
    pattern_data_in == valid_pattern;
  }

  constraint vld_sbinit_ignored_when_low_c {
    sb_sys_rst              == 1'b1;
    data_valid              == 1'b0;
    pattern_data_in[4:0]    == opcode;
    pattern_data_in[21:14]  == msgcode;
    pattern_data_in[43:40]  == result;
    pattern_data_in[58:56]  == dstid;
    pattern_data_in[62]     == (^pattern_data_in[61:0]);
  }

  constraint vld_single_cycle_strobe_c {
    sb_sys_rst == 1'b1;
    data_valid dist {1'b0 := 70, 1'b1 := 30};
    pattern_data_in dist {valid_pattern := 50, SBINIT_out_of_Reset := 50};
  }

  constraint vld_duty_cycle_modulation_c {
    sb_sys_rst == 1'b1;
    data_valid dist {1'b1 := 50, 1'b0 := 50};
    pattern_data_in dist {
      valid_pattern                       := 40,
      SBINIT_out_of_Reset                 := 40,
      [64'h0 : 64'hFFFF_FFFF_FFFF_FFFF]   := 20
    };
  }

  constraint vld_long_idle_gap_c {
    sb_sys_rst == 1'b1;
    data_valid == 1'b0;
    pattern_data_in dist {
      valid_pattern                       := 30,
      SBINIT_out_of_Reset                 := 30,
      [64'h0 : 64'hFFFF_FFFF_FFFF_FFFF]   := 40
    };
  }

  // =========================================================================
  //  CAT-05 Constraints — Output Independence, Mutual Exclusivity & Sequencing
  // =========================================================================
  constraint seq_mutual_exclusivity_c {
    sb_sys_rst == 1'b1;
    data_valid == 1'b1;
    pattern_data_in dist {
      valid_pattern                       := 45,
      SBINIT_out_of_Reset                 := 45,
      [64'h0 : 64'hFFFF_FFFF_FFFF_FFFF]   := 10
    };
  }

  constraint seq_repeated_sbinit_burst_c {
    sb_sys_rst              == 1'b1;
    data_valid              == 1'b1;
    pattern_data_in[4:0]    == opcode;
    pattern_data_in[13:5]   == 9'h000;
    pattern_data_in[21:14]  == msgcode;
    pattern_data_in[28:22]  == 7'h00;
    pattern_data_in[31:29]  == 3'b010;
    pattern_data_in[39:32]  == 8'h00;
    pattern_data_in[43:40]  == result;
    pattern_data_in[55:44]  == 12'h000;
    pattern_data_in[58:56]  == dstid;
    pattern_data_in[61:59]  == 3'b000;
    pattern_data_in[62]     == (^pattern_data_in[61:0]);
    pattern_data_in[63]     == 1'b0;
  }

  constraint seq_retraining_cycle_c {
    sb_sys_rst == 1'b1;
    data_valid dist {1'b1 := 85, 1'b0 := 15};
    pattern_data_in dist {
      valid_pattern                       := 50,
      SBINIT_out_of_Reset                 := 40,
      [64'h0 : 64'hFFFF_FFFF_FFFF_FFFF]   := 10
    };
  }

  // =========================================================================
  //  CAT-06 Constraints — Corner Cases, Aliasing & Bit-Level Stress
  // =========================================================================

  constraint crn_near_miss_aliasing_c {
    sb_sys_rst      == 1'b1;
    data_valid      == 1'b1;
    pattern_data_in != valid_pattern;
    (
      // Case A: Valid {SBINIT out of Reset} with 0x5555-like alternating bits in unchecked fields
      (pattern_data_in[4:0]   == opcode  &&
       pattern_data_in[13:5]  == 9'h155  &&
       pattern_data_in[21:14] == msgcode &&
       pattern_data_in[28:22] == 7'h55   &&
       pattern_data_in[31:29] == 3'b101  &&
       pattern_data_in[39:32] == 8'h55   &&
       pattern_data_in[43:40] == 4'h5    &&
       pattern_data_in[55:44] == 12'h555 &&
       pattern_data_in[58:56] == dstid   &&
       pattern_data_in[61:59] == 3'b101  &&
       pattern_data_in[62]    == (^pattern_data_in[61:0]))
      ||
      // Case B: Clock pattern 0x5555_5555_5555_5555 in upper bits [63:5] with Opcode=10010b in [4:0]
      (pattern_data_in[63:5]  == valid_pattern[63:5] &&
       pattern_data_in[4:0]   == opcode)
    );
  }

  constraint crn_parity_comp_double_flip_c {
    sb_sys_rst              == 1'b1;
    data_valid              == 1'b1;
    pattern_data_in[4:0]    == opcode;
    pattern_data_in[21:14]  == (msgcode ^ (8'h01 << msgcode_flip_bit_c));
    pattern_data_in[31:29]  == 3'b010;
    pattern_data_in[39:32]  == 8'h00;
    pattern_data_in[43:40]  == result;
    pattern_data_in[58:56]  == dstid;
    // Second compensating bit flip in reserved fields so even parity (CP) remains valid
    $onehot({pattern_data_in[61:59], pattern_data_in[55:44], pattern_data_in[28:22], pattern_data_in[13:5]});
    pattern_data_in[62]     == (^pattern_data_in[61:0]);
  }

  constraint crn_walking_ones_zeros_c {
    sb_sys_rst == 1'b1;
    data_valid == 1'b1;
    pattern_data_in dist {
      (64'h1 << walk_bit_c)   := 50,
      ~(64'h1 << walk_bit_c)  := 50
    };
  }

  constraint crn_other_ucie_packets_c {
    sb_sys_rst == 1'b1;
    data_valid == 1'b1;
    pattern_data_in[4:0] inside {
      5'b00000, 5'b00001, 5'b00010, 5'b00011,
      5'b00100, 5'b00101, 5'b01000, 5'b01001,
      5'b10000, 5'b10001, 5'b11001, 5'b11011
    };
    pattern_data_in[62] == (^pattern_data_in[61:0]);
  }

  constraint crn_alternating_5555_aaaa_c {
    sb_sys_rst == 1'b1;
    data_valid == 1'b1;
    pattern_data_in dist {
      64'h5555_5555_5555_5555 := 50,
      64'hAAAA_AAAA_AAAA_AAAA := 50
    };
  }

  constraint crn_full_random_soak_c {
    sb_sys_rst dist {1'b1 := 95, 1'b0 := 5};
    data_valid dist {1'b1 := 80, 1'b0 := 20};
    pattern_data_in dist {
      valid_pattern                       := 25,
      SBINIT_out_of_Reset                 := 25,
      64'hAAAA_AAAA_AAAA_AAAA             := 10,
      [64'h0 : 64'hFFFF_FFFF_FFFF_FFFF]   := 40
    };
  }

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("Pattern_detector_SBRX_seq_item: sb_sys_rst=%0b pattern_data_in=0x%0h data_valid=%0b pattern_detected=%0b sb_o_detected=%0b",
      sb_sys_rst, pattern_data_in, data_valid, pattern_detected, sb_o_detected);
  endfunction


endclass

`endif // PATTERN_DETECTOR_SBRX_SEQUENCE_ITEM_SVH
