`ifndef LFSR_PER_LANE_SUBSCRIBER_SVH
`define LFSR_PER_LANE_SUBSCRIBER_SVH

class lfsr_per_lane_subscriber extends uvm_subscriber #(lfsr_per_lane_sequence_item);
  `uvm_component_utils(lfsr_per_lane_subscriber)

  // Handle to the transaction currently being sampled.
  lfsr_per_lane_sequence_item cov_tr;

  // ---------------------------------------------------------------------
  // Registered-output context.
  //
  // Valid and VLD_SER_EN are updated by the flops at the edge that starts
  // the current cycle.  They therefore reflect the PREVIOUS cycle's control
  // inputs, and they hold their value through an opcode-change cycle.
  // These signals reconstruct that context from the sampled input stream.
  // ---------------------------------------------------------------------
  bit       prev_RST_n  = 1'b0;
  bit       prev_EN     = 1'b0;
  bit       prev_PN_EN  = 1'b0;
  bit [4:0] prev_opcode = 5'h00;
  bit [4:0] ltsm_state  = 5'h00;  // mirrors DUT prev_LTSM_state

  bit       train_d;              // previous cycle was EN && PN_EN
  bit       hold_d;               // current edge was an opcode change

  // ---------------------------------------------------------------------
  // Functional Coverage
  //
  // One coverpoint per interface signal, sampling its raw value with
  // default binning (auto_bin_max for multi-bit fields). This is
  // intentionally semantics-free: it does NOT know which combinations
  // matter for your DUT (e.g. "only sample address on a valid read").
  // Add `iff` gates and `cross` coverage by hand for anything that
  // needs DUT-specific context.
  // ---------------------------------------------------------------------
  covergroup lfsr_per_lane_cg;
    option.per_instance = 1;

    cp_RST_n: coverpoint cov_tr.RST_n {
      bins high = {1'b1};
      bins low = {1'b0};
      bins toggle_01 = (0 => 1);
      bins toggle_10 = (1 => 0);
    }

    cp_Opcode_Synch: coverpoint cov_tr.Opcode_Synch {
      bins pattern = {5'h15};
      bins zero = {5'h00};
      bins ones = {5'h1F};
      bins transition = ([5'h00:5'h1F] => [5'h00:5'h1F]);
      option.auto_bin_max = 16;
    }

    cp_EN: coverpoint cov_tr.EN{
      bins high = {1'b1};
      bins low = {1'b0};
      bins toggle_01 = (0 => 1);
      bins toggle_10 = (1 => 0);
    }

    cp_PN_EN: coverpoint cov_tr.PN_EN{
      bins high = {1'b1};
      bins low = {1'b0};
      bins toggle_01 = (0 => 1);
      bins toggle_10 = (1 => 0);
    }

    cp_Data_In: coverpoint cov_tr.Data_In{
      bins high = {1'b1};
      bins low = {1'b0};
      bins toggle_01 = (0 => 1);
      bins toggle_10 = (1 => 0);
    }

    cp_Data_Out: coverpoint cov_tr.Data_Out{
      bins high = {1'b1};
      bins low = {1'b0};
      bins toggle_01 = (0 => 1);
      bins toggle_10 = (1 => 0);
    }

    cp_Valid: coverpoint cov_tr.Valid {
      bins pattern = {8'h0F};
      bins zero = {8'h00};
      bins toggle_01 = (8'h00 => 8'h0F);
      bins toggle_10 = (8'h0F => 8'h00);

      illegal_bins other = default;
      option.auto_bin_max = 16;
    }

    cp_VLD_SER_EN: coverpoint cov_tr.VLD_SER_EN {
      bins high = {1'b1};
      bins low = {1'b0};
      bins toggle_01 = (0 => 1);
      bins toggle_10 = (1 => 0);
    }

    // Previous-cycle training and opcode-change context, used by the
    // registered-output checks below.  Reset cycles are handled by the
    // dedicated cx_RST_n_* crosses.
    cp_train_d: coverpoint train_d iff (cov_tr.RST_n) {
      bins no  = {1'b0};
      bins yes = {1'b1};
    }

    cp_hold_d: coverpoint hold_d iff (cov_tr.RST_n) {
      bins no  = {1'b0};
      bins yes = {1'b1};
    }

    cx_EN_PN_EN: cross cp_EN, cp_PN_EN;

    cx_EN_Data_In: cross cp_EN, cp_Data_In;
    cx_EN_Data_Out: cross cp_EN, cp_Data_Out;

    cx_PN_EN_Data_In: cross cp_PN_EN, cp_Data_In;
    cx_PN_EN_Data_Out: cross cp_PN_EN, cp_Data_Out;

    cx_Data_In_Data_Out: cross cp_Data_In, cp_Data_Out;

    cx_Valid: cross cp_Valid, cp_EN, cp_PN_EN {
      illegal_bins tog_high = (binsof(cp_Valid.toggle_01) || binsof(cp_Valid.pattern)) && (binsof(cp_EN.toggle_10)) && (binsof(cp_PN_EN.toggle_01));
      illegal_bins tog_10_EN = (binsof(cp_Valid.toggle_01) || binsof(cp_Valid.pattern)) && (binsof(cp_EN.toggle_01));
      illegal_bins tog_10_PN_EN = (binsof(cp_Valid.toggle_01) || binsof(cp_Valid.pattern)) && (binsof(cp_PN_EN.toggle_01));
    }
    cx_VLD_SER_EN: cross cp_VLD_SER_EN, cp_EN, cp_PN_EN{
      illegal_bins tog_high = (binsof(cp_VLD_SER_EN.toggle_01) || binsof(cp_VLD_SER_EN.high)) && (binsof(cp_EN.toggle_10)) && (binsof(cp_PN_EN.toggle_01));
      illegal_bins tog_10_EN = (binsof(cp_VLD_SER_EN.toggle_01) || binsof(cp_VLD_SER_EN.high)) && (binsof(cp_EN.toggle_01));
      illegal_bins tog_10_PN_EN = (binsof(cp_VLD_SER_EN.toggle_01) || binsof(cp_VLD_SER_EN.high)) && (binsof(cp_PN_EN.toggle_01));
    }
    // Real registered-output invariants:
    //   train_d=1, hold_d=0 -> the edge was a training edge, so the flops
    //                          MUST have loaded Valid=0x0F and VLD_SER_EN=1.
    //   train_d=0, hold_d=0 -> neither a training edge nor an opcode-change
    //                          hold, so the flops MUST have loaded 0.
    //   hold_d=1            -> opcode-change branch: Valid/VLD_SER_EN hold,
    //                          so either value is legal.
    cx_Valid_src: cross cp_Valid, cp_train_d, cp_hold_d {
      illegal_bins no_source  = binsof(cp_Valid.pattern) && binsof(cp_train_d.no) && binsof(cp_hold_d.no);
      illegal_bins train_zero = binsof(cp_Valid.zero) && binsof(cp_train_d.yes) && binsof(cp_hold_d.no);
      illegal_bins toggle_01_hold = binsof(cp_Valid.toggle_01) && binsof(cp_hold_d.yes);
      illegal_bins toggle_10_hold = binsof(cp_Valid.toggle_10) && binsof(cp_hold_d.yes);
      illegal_bins toggle_01_train = binsof(cp_Valid.toggle_01) && binsof(cp_train_d.no);
      illegal_bins toggle_10_train = binsof(cp_Valid.toggle_10) && binsof(cp_train_d.yes);
      illegal_bins vld_high_train_hold = binsof(cp_Valid.pattern) && binsof(cp_train_d.no) && binsof(cp_hold_d.yes);
    }

    cx_VLD_src: cross cp_VLD_SER_EN, cp_train_d, cp_hold_d {
      illegal_bins no_source = binsof(cp_VLD_SER_EN.high) && binsof(cp_train_d.no) && binsof(cp_hold_d.no);
      illegal_bins train_low = binsof(cp_VLD_SER_EN.low) && binsof(cp_train_d.yes) && binsof(cp_hold_d.no);
      illegal_bins toggle_01_hold = binsof(cp_VLD_SER_EN.toggle_01) && binsof(cp_hold_d.yes);
      illegal_bins toggle_10_hold = binsof(cp_VLD_SER_EN.toggle_10) && binsof(cp_hold_d.yes);
      illegal_bins toggle_01_train = binsof(cp_VLD_SER_EN.toggle_01) && binsof(cp_train_d.no);
      illegal_bins toggle_10_train = binsof(cp_VLD_SER_EN.toggle_10) && binsof(cp_train_d.yes);
      illegal_bins vld_high_train_hold = binsof(cp_VLD_SER_EN.high) && binsof(cp_train_d.no) && binsof(cp_hold_d.yes);
    }


    cx_Valid_VLD_SER_EN: cross cp_Valid, cp_VLD_SER_EN {
      illegal_bins pattern1 = binsof(cp_Valid.pattern)    && binsof(cp_VLD_SER_EN.low);
      illegal_bins pattern2 = binsof(cp_Valid.zero)       && binsof(cp_VLD_SER_EN.high);
      illegal_bins pattern3 = binsof(cp_Valid.toggle_01)  && binsof(cp_VLD_SER_EN.low);
      illegal_bins pattern4 = binsof(cp_Valid.toggle_10)  && binsof(cp_VLD_SER_EN.high);
      illegal_bins pattern5 = binsof(cp_Valid.toggle_01)  && binsof(cp_VLD_SER_EN.toggle_10);
      illegal_bins pattern6 = binsof(cp_Valid.toggle_10)  && binsof(cp_VLD_SER_EN.toggle_01);
      illegal_bins pattern7 = binsof(cp_Valid.pattern)    && binsof(cp_VLD_SER_EN.toggle_10);
      illegal_bins pattern8 = binsof(cp_Valid.zero)  && binsof(cp_VLD_SER_EN.toggle_01);
    }

    cx_RST_n_out: cross cp_RST_n, cp_Data_Out;

    cx_RST_n_Valid: cross cp_RST_n, cp_Valid {
      illegal_bins pattern1 = binsof(cp_RST_n.low) && binsof(cp_Valid.pattern);
      illegal_bins pattern2 = binsof(cp_RST_n.low) && binsof(cp_Valid.toggle_01);
      illegal_bins pattern3 = binsof(cp_RST_n.toggle_10) && binsof(cp_Valid.pattern);
      illegal_bins pattern8 = binsof(cp_RST_n.toggle_10) && binsof(cp_Valid.toggle_01);
      illegal_bins pattern4 = binsof(cp_RST_n.toggle_01) && binsof(cp_Valid.pattern);
      illegal_bins pattern5 = binsof(cp_RST_n.toggle_01) && binsof(cp_Valid.toggle_10);
      illegal_bins pattern6 = binsof(cp_RST_n.toggle_01) && binsof(cp_Valid.toggle_01);
    }

    cx_RST_n_VLD_SER_EN: cross cp_RST_n, cp_VLD_SER_EN {
      illegal_bins pattern1 = binsof(cp_RST_n.low) && binsof(cp_VLD_SER_EN.high);
      illegal_bins pattern2 = binsof(cp_RST_n.toggle_10) && binsof(cp_VLD_SER_EN.high);
      illegal_bins pattern3 = binsof(cp_RST_n.toggle_01) && binsof(cp_VLD_SER_EN.high);
      illegal_bins pattern4 = binsof(cp_RST_n.toggle_10) && binsof(cp_VLD_SER_EN.toggle_01);
      illegal_bins pattern5 = binsof(cp_RST_n.toggle_01) && binsof(cp_VLD_SER_EN.toggle_01);
      illegal_bins pattern6 = binsof(cp_RST_n.toggle_01) && binsof(cp_VLD_SER_EN.toggle_10);
      illegal_bins pattern7 = binsof(cp_RST_n.low) && binsof(cp_VLD_SER_EN.toggle_01);
    }

  endgroup : lfsr_per_lane_cg

  function new(string name = "lfsr_per_lane_subscriber", uvm_component parent = null);
    super.new(name, parent);
    lfsr_per_lane_cg = new();
  endfunction : new

  function void write(lfsr_per_lane_sequence_item t);
    if (t == null) begin
      `uvm_error("LFSR_PER_LANE_COV", "Received a null transaction")
      return;
    end
    // Reconstruct the control context that produced this cycle's registered
    // outputs.  The flops sample the PREVIOUS cycle's inputs at the edge that
    // starts this cycle, and Valid/VLD_SER_EN hold through an opcode change.
    train_d = prev_RST_n && prev_EN && prev_PN_EN;
    hold_d  = prev_RST_n && (prev_opcode != ltsm_state);

    // Mirror the DUT's prev_LTSM_state update.
    if (!prev_RST_n)
      ltsm_state = 5'h00;
    else if (hold_d)
      ltsm_state = prev_opcode;

    cov_tr = t;
    lfsr_per_lane_cg.sample();

    // Remember this cycle's inputs for the next sample.
    prev_RST_n  = t.RST_n;
    prev_EN     = t.EN;
    prev_PN_EN  = t.PN_EN;
    prev_opcode = t.Opcode_Synch;
  endfunction : write

endclass : lfsr_per_lane_subscriber

`endif // LFSR_PER_LANE_SUBSCRIBER_SVH
