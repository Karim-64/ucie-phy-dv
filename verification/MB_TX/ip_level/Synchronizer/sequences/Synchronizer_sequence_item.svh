`ifndef SYNCHRONIZER_SEQUENCE_ITEM_SVH
`define SYNCHRONIZER_SEQUENCE_ITEM_SVH



class Synchronizer_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(Synchronizer_sequence_item)

  // -------------------------------------------------------------------------
  //  Scenario Mode Definition (mapped to Verification Plan test categories)
  // -------------------------------------------------------------------------
  typedef enum bit [2:0] {
    SCENARIO_NORMAL       = 3'b000,
    SCENARIO_RESET_ASSERT = 3'b001,
    SCENARIO_STEADY_LOW   = 3'b010,
    SCENARIO_STEADY_HIGH  = 3'b011,
    SCENARIO_TOGGLE       = 3'b100,
    SCENARIO_STRESS_RAND  = 3'b101 
  } scenario_mode_e;

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic           rst_n;
  rand logic           signal_src;

  // -------------------------------------------------------------------------
  //  Control Knobs & Scenario Fields
  // -------------------------------------------------------------------------
  rand scenario_mode_e scenario_mode;
  rand int unsigned    pulse_cycles;  // Width of high pulse in cycles (TC_CDC_01, TC_SYNC_05)
  rand int unsigned    idle_cycles;   // Spacing between pulses in cycles (TC_STR_03)

  // State tracker for toggle sequences
  bit                  prev_signal_src;

  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic                signal_dst;

  // -------------------------------------------------------------------------
  //  Constraints mapped to the Verification Plan (VPlan)
  // -------------------------------------------------------------------------


  constraint c_default_op {
    soft rst_n         == 1'b1;
    soft scenario_mode == SCENARIO_NORMAL;
    soft signal_src dist { 1'b0 := 50, 1'b1 := 50 };
  }

  constraint c_reset_active {
    if (scenario_mode == SCENARIO_RESET_ASSERT) {
      rst_n == 1'b0;
    }
  }

  
  constraint c_reset_deasserted {
    if (scenario_mode != SCENARIO_RESET_ASSERT && scenario_mode != SCENARIO_STRESS_RAND) {
      soft rst_n == 1'b1;
    }
  }

  constraint c_steady_low {
    if (scenario_mode == SCENARIO_STEADY_LOW) {
      rst_n      == 1'b1;
      signal_src == 1'b0;
    }
  }

  constraint c_steady_high {
    if (scenario_mode == SCENARIO_STEADY_HIGH) {
      rst_n      == 1'b1;
      signal_src == 1'b1;
    }
  }

  constraint c_toggle_pattern {
    if (scenario_mode == SCENARIO_TOGGLE) {
      rst_n      == 1'b1;
      signal_src == ~prev_signal_src;
    }
  }


  constraint c_pulse_timing {
    soft pulse_cycles inside {[1:20]};
    soft idle_cycles  inside {[1:20]};
  }

  constraint c_stress_dist {
    if (scenario_mode == SCENARIO_STRESS_RAND) {
      rst_n      dist { 1'b1 := 95, 1'b0 := 5 };
      signal_src dist { 1'b0 := 50, 1'b1 := 50 };
    }
  }

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "Synchronizer_sequence_item");
    super.new(name);
    prev_signal_src = 1'b0;
  endfunction

  // -------------------------------------------------------------------------
  //  post_randomize - update history for toggle/pattern generation
  // -------------------------------------------------------------------------
  function void post_randomize();
    prev_signal_src = signal_src;
  endfunction

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("Synchronizer_seq_item: mode=%s rst_n=%0b signal_src=%0b signal_dst=%0b (pulse_cycles=%0d, idle_cycles=%0d)",
      scenario_mode.name(), rst_n, signal_src, signal_dst, pulse_cycles, idle_cycles);
  endfunction

endclass

`endif // SYNCHRONIZER_SEQUENCE_ITEM_SVH
