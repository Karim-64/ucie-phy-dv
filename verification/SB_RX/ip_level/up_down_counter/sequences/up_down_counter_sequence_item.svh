`ifndef UP_DOWN_COUNTER_SEQUENCE_ITEM_SVH
`define UP_DOWN_COUNTER_SEQUENCE_ITEM_SVH

class up_down_counter_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(up_down_counter_sequence_item)

  // -------------------------------------------------------------------------
  //  Scenario Mode Definition (mapped to Verification Plan test categories)
  // -------------------------------------------------------------------------
  typedef enum bit [3:0] {
    SCENARIO_NORMAL          = 4'd0,
    SCENARIO_RESET_ASSERT    = 4'd1,
    SCENARIO_IDLE            = 4'd2,
    SCENARIO_INC             = 4'd3,
    SCENARIO_DEC             = 4'd4,
    SCENARIO_DUAL            = 4'd5,
    SCENARIO_UP_BIASED       = 4'd6,
    SCENARIO_DOWN_BIASED     = 4'd7,
    SCENARIO_DUAL_DOMINANT   = 4'd8,
    SCENARIO_RANDOM_RESET    = 4'd9
  } scenario_mode_e;

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic sys_rst;
  rand logic up;
  rand logic down;

  // -------------------------------------------------------------------------
  //  Control Knobs & Scenario Fields
  // -------------------------------------------------------------------------
  rand scenario_mode_e scenario_mode;
  rand int unsigned    burst_cycles;
  rand int unsigned    idle_cycles;

  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [WIDTH-1:0] count;

  // -------------------------------------------------------------------------
  //  Constraints mapped to the Verification Plan (VPlan)
  // -------------------------------------------------------------------------

  // Default normal operation: reset deasserted, uniform distribution of up/down
  constraint c_default_op {
    soft sys_rst       == 1'b1;
    soft scenario_mode == SCENARIO_NORMAL;
    soft up   dist { 1'b0 := 50, 1'b1 := 50 };
    soft down dist { 1'b0 := 50, 1'b1 := 50 };
  }

  // Active-low reset assertion (sys_rst = 0)
  constraint c_reset_active {
    if (scenario_mode == SCENARIO_RESET_ASSERT) {
      sys_rst == 1'b0;
    }
  }

  // Reset deasserted during non-reset scenarios
  constraint c_reset_deasserted {
    if (scenario_mode != SCENARIO_RESET_ASSERT && scenario_mode != SCENARIO_RANDOM_RESET) {
      soft sys_rst == 1'b1;
    }
  }

  // S0: Idle hold state (up = 0, down = 0)
  constraint c_idle_hold {
    if (scenario_mode == SCENARIO_IDLE) {
      sys_rst == 1'b1;
      up      == 1'b0;
      down    == 1'b0;
    }
  }

  // S1: Increment only (up = 1, down = 0)
  constraint c_inc_only {
    if (scenario_mode == SCENARIO_INC) {
      sys_rst == 1'b1;
      up      == 1'b1;
      down    == 1'b0;
    }
  }

  // S2: Decrement only (up = 0, down = 1)
  constraint c_dec_only {
    if (scenario_mode == SCENARIO_DEC) {
      sys_rst == 1'b1;
      up      == 1'b0;
      down    == 1'b1;
    }
  }

  // S3: Simultaneous dual assertion (up = 1, down = 1)
  constraint c_dual_assert {
    if (scenario_mode == SCENARIO_DUAL) {
      sys_rst == 1'b1;
      up      == 1'b1;
      down    == 1'b1;
    }
  }

  // Burst and idle timing knobs constraint
  constraint c_burst_timing {
    soft burst_cycles inside {[1:50]};
    soft idle_cycles  inside {[1:50]};
  }

  // TC_RAND_02: Up-biased saturation stress (90% up = 1, 10% down = 1)
  constraint c_up_biased_stress {
    if (scenario_mode == SCENARIO_UP_BIASED) {
      sys_rst == 1'b1;
      up      dist { 1'b1 := 90, 1'b0 := 10 };
      down    dist { 1'b1 := 10, 1'b0 := 90 };
    }
  }

  // TC_RAND_03: Down-biased exhaustion stress (90% down = 1, 10% up = 1)
  constraint c_down_biased_stress {
    if (scenario_mode == SCENARIO_DOWN_BIASED) {
      sys_rst == 1'b1;
      down    dist { 1'b1 := 90, 1'b0 := 10 };
      up      dist { 1'b1 := 10, 1'b0 := 90 };
    }
  }

  // TC_RAND_04: Dual assertion dominant stress (80% {up=1, down=1})
  constraint c_dual_dominant_stress {
    if (scenario_mode == SCENARIO_DUAL_DOMINANT) {
      sys_rst == 1'b1;
      {up, down} dist {
        2'b11 := 80,
        2'b00 := 10,
        2'b10 := 5,
        2'b01 := 5
      };
    }
  }

  // TC_RAND_05: Random asynchronous reset injection (random traffic with periodic reset)
  constraint c_random_reset_stress {
    if (scenario_mode == SCENARIO_RANDOM_RESET) {
      sys_rst dist { 1'b1 := 90, 1'b0 := 10 };
      up      dist { 1'b0 := 50, 1'b1 := 50 };
      down    dist { 1'b0 := 50, 1'b1 := 50 };
    }
  }

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "up_down_counter_sequence_item");
    super.new(name);
    scenario_mode = SCENARIO_NORMAL;
    burst_cycles  = 1;
    idle_cycles   = 1;
  endfunction

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("up_down_counter_seq_item: mode=%s sys_rst=%0b up=%0b down=%0b count=0x%0h (burst_cycles=%0d, idle_cycles=%0d)",
      scenario_mode.name(), sys_rst, up, down, count, burst_cycles, idle_cycles);
  endfunction

endclass

`endif // UP_DOWN_COUNTER_SEQUENCE_ITEM_SVH
