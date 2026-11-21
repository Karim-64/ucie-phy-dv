`ifndef PATTERN_DETECTOR_SBRX_SVA_SV
`define PATTERN_DETECTOR_SBRX_SVA_SV


module Pattern_detector_SBRX_sva #(
  parameter int DATA_WIDTH = 64
) (
  input logic                  sb_clk,
  input logic                  sb_sys_rst,
  input logic [DATA_WIDTH-1:0] pattern_data_in,
  input logic                  data_valid,
  input logic                  pattern_detected,
  input logic                  sb_o_detected
);

  // ---------------------------------------------------------------------------
  // Protocol Constants & Helper Expressions
  // ---------------------------------------------------------------------------
  localparam logic [DATA_WIDTH-1:0] CLK_PAT         = 64'h5555_5555_5555_5555;
  localparam logic [4:0]            OPC_MSG_NO_DATA = 5'b10010;
  localparam logic [7:0]            MSGCODE_SBO     = 8'h91;
  localparam logic [2:0]            DSTID_REM_PHY   = 3'b110;

  wire is_clk_pat_match = (pattern_data_in == CLK_PAT);

  wire is_sbo_match     = (pattern_data_in[4:0]   == OPC_MSG_NO_DATA) &&
                          (pattern_data_in[21:14] == MSGCODE_SBO)     &&
                          (pattern_data_in[40]    == 1'b1)            &&
                          (pattern_data_in[58:56] == DSTID_REM_PHY)   &&
                          (pattern_data_in[62]    == (^pattern_data_in[61:0]));

  // Local black-box reference tracker for 1st valid pattern occurrence
  // (Derived strictly from module input ports, independent of RTL internals)
  logic first_pat_seen;
  always_ff @(posedge sb_clk or negedge sb_sys_rst) begin
    if (!sb_sys_rst) begin
      first_pat_seen <= 1'b0;
    end else if (data_valid) begin
      if (is_clk_pat_match)
        first_pat_seen <= ~first_pat_seen;
      else
        first_pat_seen <= 1'b0;
    end
  end

  property p_reset_clears_outputs;
    @(posedge sb_clk)
    (sb_sys_rst === 1'b0) |-> (pattern_detected == 1'b0 && sb_o_detected == 1'b0);
  endproperty
  AST_reset_clears_outputs: assert property (p_reset_clears_outputs)
    else $error("[SVA_ERR][AST_reset_clears_outputs] Outputs not 0 during active-low reset!");
  COV_reset_clears_outputs: cover property (p_reset_clears_outputs);

  // A2: Outputs must never be X or Z when out of reset
  property p_no_xz_outputs;
    @(posedge sb_clk) disable iff (sb_sys_rst !== 1'b1)
    !$isunknown({pattern_detected, sb_o_detected});
  endproperty
  AST_no_xz_outputs: assert property (p_no_xz_outputs)
    else $error("[SVA_ERR][AST_no_xz_outputs] Unknown (X/Z) value detected on DUT outputs!");

  property p_data_valid_low_clears_outputs;
    @(posedge sb_clk) disable iff (sb_sys_rst !== 1'b1)
    (!data_valid) |=> (pattern_detected == 1'b0 && sb_o_detected == 1'b0);
  endproperty
  AST_data_valid_low_clears_outputs: assert property (p_data_valid_low_clears_outputs)
    else $error("[SVA_ERR][AST_data_valid_low_clears_outputs] Outputs not cleared when data_valid=0!");
  COV_data_valid_low_clears_outputs: cover property (p_data_valid_low_clears_outputs);

  property p_non_matching_valid_clears_pattern;
    @(posedge sb_clk) disable iff (sb_sys_rst !== 1'b1)
    (data_valid && !is_clk_pat_match) |=> (pattern_detected == 1'b0);
  endproperty
  AST_non_matching_valid_clears_pattern: assert property (p_non_matching_valid_clears_pattern)
    else $error("[SVA_ERR][AST_non_matching_valid_clears_pattern] pattern_detected asserted after a non-matching valid word!");
  COV_non_matching_valid_clears_pattern: cover property (p_non_matching_valid_clears_pattern);

  property p_first_valid_pattern_no_detect;
    @(posedge sb_clk) disable iff (sb_sys_rst !== 1'b1)
    (data_valid && is_clk_pat_match && !first_pat_seen) |=> (pattern_detected == 1'b0);
  endproperty
  AST_first_valid_pattern_no_detect: assert property (p_first_valid_pattern_no_detect)
    else $error("[SVA_ERR][AST_first_valid_pattern_no_detect] pattern_detected asserted on the 1st valid pattern!");
  COV_first_valid_pattern_no_detect: cover property (p_first_valid_pattern_no_detect);

  property p_two_consecutive_patterns_assert_detect;
    @(posedge sb_clk) disable iff (sb_sys_rst !== 1'b1)
    (data_valid && is_clk_pat_match && first_pat_seen) |=> (pattern_detected == 1'b1);
  endproperty
  AST_two_consecutive_patterns_assert_detect: assert property (p_two_consecutive_patterns_assert_detect)
    else $error("[SVA_ERR][AST_two_consecutive_patterns_assert_detect] pattern_detected failed to assert on 2nd consecutive valid pattern!");
  COV_two_consecutive_patterns_assert_detect: cover property (p_two_consecutive_patterns_assert_detect);

  // A7: pattern_detected can only assert for a single cycle per pair (never 2 cycles in a row)
  property p_pattern_detected_single_cycle_pulse;
    @(posedge sb_clk) disable iff (sb_sys_rst !== 1'b1)
    pattern_detected |=> !pattern_detected;
  endproperty
  AST_pattern_detected_single_cycle_pulse: assert property (p_pattern_detected_single_cycle_pulse)
    else $error("[SVA_ERR][AST_pattern_detected_single_cycle_pulse] pattern_detected stayed high for more than 1 cycle!");
  COV_pattern_detected_single_cycle_pulse: cover property (p_pattern_detected_single_cycle_pulse);

  property p_sbinit_valid_asserts_detect;
    @(posedge sb_clk) disable iff (sb_sys_rst !== 1'b1)
    (data_valid && is_sbo_match) |=> (sb_o_detected == 1'b1);
  endproperty
  AST_sbinit_valid_asserts_detect: assert property (p_sbinit_valid_asserts_detect)
    else $error("[SVA_ERR][AST_sbinit_valid_asserts_detect] sb_o_detected failed to assert on valid SBINIT out of Reset!");
  COV_sbinit_valid_asserts_detect: cover property (p_sbinit_valid_asserts_detect);

  // A9: Any invalid field or CP parity error when data_valid=1 keeps sb_o_detected == 0
  property p_sbinit_invalid_clears_detect;
    @(posedge sb_clk) disable iff (sb_sys_rst !== 1'b1)
    (data_valid && !is_sbo_match) |=> (sb_o_detected == 1'b0);
  endproperty
  AST_sbinit_invalid_clears_detect: assert property (p_sbinit_invalid_clears_detect)
    else $error("[SVA_ERR][AST_sbinit_invalid_clears_detect] False positive on sb_o_detected!");
  COV_sbinit_invalid_clears_detect: cover property (p_sbinit_invalid_clears_detect);

  property p_outputs_mutually_exclusive;
    @(posedge sb_clk) disable iff (sb_sys_rst !== 1'b1)
    !(pattern_detected && sb_o_detected);
  endproperty
  AST_outputs_mutually_exclusive: assert property (p_outputs_mutually_exclusive)
    else $error("[SVA_ERR][AST_outputs_mutually_exclusive] Both pattern_detected and sb_o_detected asserted at the same time!");
  COV_outputs_mutually_exclusive: cover property (
    @(posedge sb_clk) disable iff (sb_sys_rst !== 1'b1) (pattern_detected ^ sb_o_detected)
  );

endmodule

`endif // PATTERN_DETECTOR_SBRX_SVA_SV
