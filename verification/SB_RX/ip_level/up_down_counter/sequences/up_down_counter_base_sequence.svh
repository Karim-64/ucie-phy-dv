`ifndef UP_DOWN_COUNTER_BASE_SEQUENCE_SVH
`define UP_DOWN_COUNTER_BASE_SEQUENCE_SVH

class up_down_counter_base_sequence extends uvm_sequence #(up_down_counter_sequence_item);
  `uvm_object_utils(up_down_counter_base_sequence)
  `uvm_declare_p_sequencer(up_down_counter_sequencer)

  // Max count value derived from WIDTH parameter (default WIDTH = 5 -> MAX = 31)
  int unsigned max_count = (1 << WIDTH) - 1;

  function new(string name = "up_down_counter_base_sequence");
    super.new(name);
  endfunction
  //  Helper Method
  task send_item_direct(logic rst, logic u, logic d);
    up_down_counter_sequence_item item;
    item = up_down_counter_sequence_item::type_id::create("item");
    start_item(item);
    item.constraint_mode(0);
    if (!item.randomize() with {
      sys_rst == rst;
      up      == u;
      down    == d;
    }) `uvm_error("SEQ", "Randomization failed in send_item_direct")
    finish_item(item);
    p_sequencer.seqr_aport.write(item);
  endtask

  task send_item_random(logic rst);
    up_down_counter_sequence_item item;
    item = up_down_counter_sequence_item::type_id::create("item");
    start_item(item);
    item.constraint_mode(0);
    if (!item.randomize() with {
      sys_rst == rst;
    }) `uvm_error("SEQ", "Randomization failed in send_item_direct")
    finish_item(item);
    p_sequencer.seqr_aport.write(item);
  endtask

  task send_item_scenario(up_down_counter_sequence_item::scenario_mode_e mode);
    up_down_counter_sequence_item item;
    item = up_down_counter_sequence_item::type_id::create("item");
    start_item(item);
    item.constraint_mode(0);
    case (mode)
      up_down_counter_sequence_item::SCENARIO_NORMAL:        item.c_default_op.constraint_mode(1);
      up_down_counter_sequence_item::SCENARIO_RESET_ASSERT:  item.c_reset_active.constraint_mode(1);
      up_down_counter_sequence_item::SCENARIO_IDLE:          item.c_idle_hold.constraint_mode(1);
      up_down_counter_sequence_item::SCENARIO_INC:           item.c_inc_only.constraint_mode(1);
      up_down_counter_sequence_item::SCENARIO_DEC:           item.c_dec_only.constraint_mode(1);
      up_down_counter_sequence_item::SCENARIO_DUAL:          item.c_dual_assert.constraint_mode(1);
      up_down_counter_sequence_item::SCENARIO_UP_BIASED:     item.c_up_biased_stress.constraint_mode(1);
      up_down_counter_sequence_item::SCENARIO_DOWN_BIASED:   item.c_down_biased_stress.constraint_mode(1);
      up_down_counter_sequence_item::SCENARIO_DUAL_DOMINANT: item.c_dual_dominant_stress.constraint_mode(1);
      up_down_counter_sequence_item::SCENARIO_RANDOM_RESET:  item.c_random_reset_stress.constraint_mode(1);
      default:                                               item.c_default_op.constraint_mode(1);
    endcase
    if (!item.randomize() with { scenario_mode == mode; })
      `uvm_error("SEQ", $sformatf("Randomization failed for scenario %s", mode.name()))
    finish_item(item);
    p_sequencer.seqr_aport.write(item);
  endtask

  task reset_dut();
    send_item_direct(1'b0, 1'b0, 1'b0);
    send_item_direct(1'b1, 1'b0, 1'b0);
  endtask

  task set_counter_to_mid();
    reset_dut();
    for (int i = 0; i < (max_count / 2); i++) begin
      send_item_direct(1'b1, 1'b0, 1'b1);
    end
    send_item_direct(1'b1, 1'b0, 1'b0);
  endtask

  task decrement_to_zero();
    for (int i = 0; i <= max_count; i++) begin
      send_item_direct(1'b1, 1'b0, 1'b1);
    end
    send_item_direct(1'b1, 1'b0, 1'b0);
  endtask

  task body();

    // =========================================================================
    // SECTION 1: Reset & Initialization Verification (Active-Low Asynchronous sys_rst)
    // =========================================================================

    // TC_RST_01: test_async_reset_power_on
    `uvm_info(get_type_name(), "Executing TC_RST_01: test_async_reset_power_on", UVM_LOW)
    for (int i = 0; i < 5; i++) begin
      send_item_direct(1'b0, 1'b0, 1'b0);
    end
    send_item_direct(1'b1, 1'b0, 1'b0);

    // TC_RST_02: test_reset_priority_over_up
    `uvm_info(get_type_name(), "Executing TC_RST_02: test_reset_priority_over_up", UVM_LOW)
    for (int i = 0; i < 5; i++) begin
      send_item_direct(1'b0, 1'b1, 1'b0);
    end
    send_item_direct(1'b1, 1'b1, 1'b0);

    // TC_RST_03: test_reset_priority_over_down
    `uvm_info(get_type_name(), "Executing TC_RST_03: test_reset_priority_over_down", UVM_LOW)
    for (int i = 0; i < 5; i++) begin
      send_item_direct(1'b0, 1'b0, 1'b1);
    end
    send_item_direct(1'b1, 1'b0, 1'b1);

    // TC_RST_04: test_reset_priority_over_dual_assert
    `uvm_info(get_type_name(), "Executing TC_RST_04: test_reset_priority_over_dual_assert", UVM_LOW)
    for (int i = 0; i < 5; i++) begin
      send_item_direct(1'b0, 1'b1, 1'b1);
    end
    send_item_direct(1'b1, 1'b1, 1'b1);

    // TC_RST_05: test_async_reset_assertion_during_operation
    `uvm_info(get_type_name(), "Executing TC_RST_05: test_async_reset_assertion_during_operation", UVM_LOW)
    reset_dut();
    fork
      begin
        send_item_direct(1'b1, 1'b0, 1'b1);
      end
      #1 send_item_direct(1'b0, 1'b0, 1'b0);
    join
    send_item_direct(1'b1, 1'b0, 1'b0);
    

    // TC_RST_06: test_async_reset_at_zero_credit
    `uvm_info(get_type_name(), "Executing TC_RST_06: test_async_reset_at_zero_credit", UVM_LOW)
    decrement_to_zero();
    send_item_direct(1'b0, 1'b0, 1'b0);
    send_item_direct(1'b1, 1'b0, 1'b0);

    // TC_RST_07: test_reset_deassertion_recovery
    `uvm_info(get_type_name(), "Executing TC_RST_07: test_reset_deassertion_recovery", UVM_LOW)
    send_item_direct(1'b0, 1'b0, 1'b0);
    for (int i = 0; i < 5; i++) begin
      send_item_direct(1'b1, 1'b0, 1'b0);
    end

    // TC_RST_08: test_narrow_reset_glitch_immunity.
    `uvm_info(get_type_name(), "Executing TC_RST_08: test_narrow_reset_glitch_immunity", UVM_LOW)
    send_item_direct(1'b1, 1'b0, 1'b1);
    send_item_direct(1'b0, 1'b0, 1'b0);
    send_item_direct(1'b1, 1'b0, 1'b0);

    // TC_RST_09: test_extended_reset_assertion
    `uvm_info(get_type_name(), "Executing TC_RST_09: test_extended_reset_assertion", UVM_LOW)
    for (int i = 0; i < 110; i++) begin
      send_item_random(1'b0);
    end
    send_item_direct(1'b1, 1'b0, 1'b0);

    // =========================================================================
    // SECTION 2: Basic Single-Cycle Counting Operations (Truth Table Coverage)
    // =========================================================================

    // TC_NORM_01: test_idle_hold_state
    `uvm_info(get_type_name(), "Executing TC_NORM_01: test_idle_hold_state", UVM_LOW)
    set_counter_to_mid();
    send_item_direct(1'b1, 1'b0, 1'b0);

    // TC_NORM_02: test_single_step_increment
    `uvm_info(get_type_name(), "Executing TC_NORM_02: test_single_step_increment", UVM_LOW)
    send_item_direct(1'b1, 1'b1, 1'b0);
    send_item_direct(1'b1, 1'b0, 1'b0);

    // TC_NORM_03: test_single_step_decrement
    `uvm_info(get_type_name(), "Executing TC_NORM_03: test_single_step_decrement", UVM_LOW)
    send_item_direct(1'b1, 1'b0, 1'b1);
    send_item_direct(1'b1, 1'b0, 1'b0);

    // TC_NORM_04: test_single_step_simultaneous_up_down
    `uvm_info(get_type_name(), "Executing TC_NORM_04: test_single_step_simultaneous_up_down", UVM_LOW)
    send_item_direct(1'b1, 1'b1, 1'b1);
    send_item_direct(1'b1, 1'b0, 1'b0);

    // TC_NORM_05: test_single_step_increment_then_decrement
    `uvm_info(get_type_name(), "Executing TC_NORM_05: test_single_step_increment_then_decrement", UVM_LOW)
    send_item_direct(1'b1, 1'b1, 1'b0);
    send_item_direct(1'b1, 1'b0, 1'b1);

    // =========================================================================
    // SECTION 3: Boundary & Saturation Corner Cases (Credit Bounds Protection)
    // =========================================================================

    // TC_BOUND_01: test_upper_boundary_initial_increment_saturation
    `uvm_info(get_type_name(), "Executing TC_BOUND_01: test_upper_boundary_initial_increment_saturation", UVM_LOW)
    reset_dut();
    send_item_direct(1'b1, 1'b1, 1'b0);

    // TC_BOUND_02: test_upper_boundary_sustained_increment_saturation
    `uvm_info(get_type_name(), "Executing TC_BOUND_02: test_upper_boundary_sustained_increment_saturation", UVM_LOW)
    for (int i = 0; i < 20; i++) begin
      send_item_direct(1'b1, 1'b1, 1'b0);
    end

    // TC_BOUND_03: test_reach_max_boundary_from_max_minus_one
    `uvm_info(get_type_name(), "Executing TC_BOUND_03: test_reach_max_boundary_from_max_minus_one", UVM_LOW)
    reset_dut();
    send_item_direct(1'b1, 1'b0, 1'b1); // 31 -> 30
    send_item_direct(1'b1, 1'b1, 1'b0); // 30 -> 31
    send_item_direct(1'b1, 1'b1, 1'b0); // 31 -> 31 (saturation clamp)

    // TC_BOUND_04: test_lower_boundary_decrement_saturation
    `uvm_info(get_type_name(), "Executing TC_BOUND_04: test_lower_boundary_decrement_saturation", UVM_LOW)
    decrement_to_zero();
    send_item_direct(1'b1, 1'b0, 1'b1);

    // TC_BOUND_05: test_lower_boundary_sustained_decrement_saturation
    `uvm_info(get_type_name(), "Executing TC_BOUND_05: test_lower_boundary_sustained_decrement_saturation", UVM_LOW)
    for (int i = 0; i < 20; i++) begin
      send_item_direct(1'b1, 1'b0, 1'b1);
    end

    // TC_BOUND_06: test_reach_min_boundary_from_one
    `uvm_info(get_type_name(), "Executing TC_BOUND_06: test_reach_min_boundary_from_one", UVM_LOW)
    decrement_to_zero();
    send_item_direct(1'b1, 1'b1, 1'b0); // 0 -> 1
    send_item_direct(1'b1, 1'b0, 1'b1); // 1 -> 0
    send_item_direct(1'b1, 1'b0, 1'b1); // 0 -> 0 (clamp)

    // TC_BOUND_07: test_boundary_immediate_reversal_at_max
    `uvm_info(get_type_name(), "Executing TC_BOUND_07: test_boundary_immediate_reversal_at_max", UVM_LOW)
    reset_dut();
    for (int i = 0; i < 3; i++) begin
      send_item_direct(1'b1, 1'b1, 1'b0);
    end
    send_item_direct(1'b1, 1'b0, 1'b1);

    // TC_BOUND_08: test_boundary_immediate_reversal_at_min
    `uvm_info(get_type_name(), "Executing TC_BOUND_08: test_boundary_immediate_reversal_at_min", UVM_LOW)
    decrement_to_zero();
    for (int i = 0; i < 3; i++) begin
      send_item_direct(1'b1, 1'b0, 1'b1);
    end
    send_item_direct(1'b1, 1'b1, 1'b0);

    // TC_BOUND_09: test_simultaneous_up_down_at_max_boundary
    `uvm_info(get_type_name(), "Executing TC_BOUND_09: test_simultaneous_up_down_at_max_boundary", UVM_LOW)
    reset_dut();
    for (int i = 0; i < 3; i++) begin
      send_item_direct(1'b1, 1'b1, 1'b1);
    end

    // TC_BOUND_10: test_simultaneous_up_down_at_min_boundary
    `uvm_info(get_type_name(), "Executing TC_BOUND_10: test_simultaneous_up_down_at_min_boundary", UVM_LOW)
    decrement_to_zero();
    for (int i = 0; i < 3; i++) begin
      send_item_direct(1'b1, 1'b1, 1'b1);
    end

    // =========================================================================
    // SECTION 4: Consecutive State-to-State Transitions (All 16 Directed Pairs Between S0, S1, S2, S3)
    // S0 = {up=0, down=0}, S1 = {up=1, down=0}, S2 = {up=0, down=1}, S3 = {up=1, down=1}
    // =========================================================================

    // TC_TRANS_01: test_consecutive_idle_to_idle
    `uvm_info(get_type_name(), "Executing TC_TRANS_01: test_consecutive_idle_to_idle", UVM_LOW)
    set_counter_to_mid();
    send_item_direct(1'b1, 1'b0, 1'b0); // Cycle 1: S0
    send_item_direct(1'b1, 1'b0, 1'b0); // Cycle 2: S0

    // TC_TRANS_02: test_consecutive_idle_to_inc
    `uvm_info(get_type_name(), "Executing TC_TRANS_02: test_consecutive_idle_to_inc", UVM_LOW)
    send_item_direct(1'b1, 1'b0, 1'b0); // Cycle 1: S0
    send_item_direct(1'b1, 1'b1, 1'b0); // Cycle 2: S1

    // TC_TRANS_03: test_consecutive_idle_to_dec
    `uvm_info(get_type_name(), "Executing TC_TRANS_03: test_consecutive_idle_to_dec", UVM_LOW)
    send_item_direct(1'b1, 1'b0, 1'b0); // Cycle 1: S0
    send_item_direct(1'b1, 1'b0, 1'b1); // Cycle 2: S2

    // TC_TRANS_04: test_consecutive_idle_to_dual
    `uvm_info(get_type_name(), "Executing TC_TRANS_04: test_consecutive_idle_to_dual", UVM_LOW)
    send_item_direct(1'b1, 1'b0, 1'b0); // Cycle 1: S0
    send_item_direct(1'b1, 1'b1, 1'b1); // Cycle 2: S3

    // TC_TRANS_05: test_consecutive_inc_to_idle
    `uvm_info(get_type_name(), "Executing TC_TRANS_05: test_consecutive_inc_to_idle", UVM_LOW)
    send_item_direct(1'b1, 1'b1, 1'b0); // Cycle 1: S1
    send_item_direct(1'b1, 1'b0, 1'b0); // Cycle 2: S0

    // TC_TRANS_06: test_consecutive_inc_to_inc
    `uvm_info(get_type_name(), "Executing TC_TRANS_06: test_consecutive_inc_to_inc", UVM_LOW)
    send_item_direct(1'b1, 1'b1, 1'b0); // Cycle 1: S1
    send_item_direct(1'b1, 1'b1, 1'b0); // Cycle 2: S1

    // TC_TRANS_07: test_consecutive_inc_to_dec
    `uvm_info(get_type_name(), "Executing TC_TRANS_07: test_consecutive_inc_to_dec", UVM_LOW)
    send_item_direct(1'b1, 1'b1, 1'b0); // Cycle 1: S1
    send_item_direct(1'b1, 1'b0, 1'b1); // Cycle 2: S2

    // TC_TRANS_08: test_consecutive_inc_to_dual
    `uvm_info(get_type_name(), "Executing TC_TRANS_08: test_consecutive_inc_to_dual", UVM_LOW)
    send_item_direct(1'b1, 1'b1, 1'b0); // Cycle 1: S1
    send_item_direct(1'b1, 1'b1, 1'b1); // Cycle 2: S3

    // TC_TRANS_09: test_consecutive_dec_to_idle
    `uvm_info(get_type_name(), "Executing TC_TRANS_09: test_consecutive_dec_to_idle", UVM_LOW)
    send_item_direct(1'b1, 1'b0, 1'b1); // Cycle 1: S2
    send_item_direct(1'b1, 1'b0, 1'b0); // Cycle 2: S0

    // TC_TRANS_10: test_consecutive_dec_to_inc
    `uvm_info(get_type_name(), "Executing TC_TRANS_10: test_consecutive_dec_to_inc", UVM_LOW)
    send_item_direct(1'b1, 1'b0, 1'b1); // Cycle 1: S2
    send_item_direct(1'b1, 1'b1, 1'b0); // Cycle 2: S1

    // TC_TRANS_11: test_consecutive_dec_to_dec
    `uvm_info(get_type_name(), "Executing TC_TRANS_11: test_consecutive_dec_to_dec", UVM_LOW)
    send_item_direct(1'b1, 1'b0, 1'b1); // Cycle 1: S2
    send_item_direct(1'b1, 1'b0, 1'b1); // Cycle 2: S2

    // TC_TRANS_12: test_consecutive_dec_to_dual
    `uvm_info(get_type_name(), "Executing TC_TRANS_12: test_consecutive_dec_to_dual", UVM_LOW)
    send_item_direct(1'b1, 1'b0, 1'b1); // Cycle 1: S2
    send_item_direct(1'b1, 1'b1, 1'b1); // Cycle 2: S3

    // TC_TRANS_13: test_consecutive_dual_to_idle
    `uvm_info(get_type_name(), "Executing TC_TRANS_13: test_consecutive_dual_to_idle", UVM_LOW)
    send_item_direct(1'b1, 1'b1, 1'b1); // Cycle 1: S3
    send_item_direct(1'b1, 1'b0, 1'b0); // Cycle 2: S0

    // TC_TRANS_14: test_consecutive_dual_to_inc
    `uvm_info(get_type_name(), "Executing TC_TRANS_14: test_consecutive_dual_to_inc", UVM_LOW)
    send_item_direct(1'b1, 1'b1, 1'b1); // Cycle 1: S3
    send_item_direct(1'b1, 1'b1, 1'b0); // Cycle 2: S1

    // TC_TRANS_15: test_consecutive_dual_to_dec
    `uvm_info(get_type_name(), "Executing TC_TRANS_15: test_consecutive_dual_to_dec", UVM_LOW)
    send_item_direct(1'b1, 1'b1, 1'b1); // Cycle 1: S3
    send_item_direct(1'b1, 1'b0, 1'b1); // Cycle 2: S2

    // TC_TRANS_16: test_consecutive_dual_to_dual
    `uvm_info(get_type_name(), "Executing TC_TRANS_16: test_consecutive_dual_to_dual", UVM_LOW)
    send_item_direct(1'b1, 1'b1, 1'b1); // Cycle 1: S3
    send_item_direct(1'b1, 1'b1, 1'b1); // Cycle 2: S3

    // =========================================================================
    // SECTION 5: Multi-Cycle Consecutive Patterns & Burst Operations
    // =========================================================================

    // TC_BURST_01: test_full_range_consecutive_ramp_down
    `uvm_info(get_type_name(), "Executing TC_BURST_01: test_full_range_consecutive_ramp_down", UVM_LOW)
    reset_dut();
    for (int i = 0; i <= max_count; i++) begin
      send_item_direct(1'b1, 1'b0, 1'b1);
    end

    // TC_BURST_02: test_full_range_consecutive_ramp_up
    `uvm_info(get_type_name(), "Executing TC_BURST_02: test_full_range_consecutive_ramp_up", UVM_LOW)
    decrement_to_zero();
    for (int i = 0; i <= max_count; i++) begin
      send_item_direct(1'b1, 1'b1, 1'b0);
    end

    // TC_BURST_03: test_rapid_consecutive_ping_pong_oscillations
    `uvm_info(get_type_name(), "Executing TC_BURST_03: test_rapid_consecutive_ping_pong_oscillations", UVM_LOW)
    set_counter_to_mid();
    for (int i = 0; i < 25; i++) begin
      send_item_direct(1'b1, 1'b1, 1'b0);
      send_item_direct(1'b1, 1'b0, 1'b1);
    end

    // TC_BURST_04: test_alternating_dual_hold_and_idle_hold
    `uvm_info(get_type_name(), "Executing TC_BURST_04: test_alternating_dual_hold_and_idle_hold", UVM_LOW)
    reset_dut();
    for (int i = 0; i < (max_count - 20); i++) begin
      send_item_direct(1'b1, 1'b0, 1'b1); // reach 20
    end
    for (int i = 0; i < 15; i++) begin
      send_item_direct(1'b1, 1'b1, 1'b1);
      send_item_direct(1'b1, 1'b0, 1'b0);
    end

    // TC_BURST_05: test_staircase_burst_increments
    `uvm_info(get_type_name(), "Executing TC_BURST_05: test_staircase_burst_increments", UVM_LOW)
    decrement_to_zero();
    for (int rep = 0; rep < 4; rep++) begin
      for (int i = 0; i < 3; i++) send_item_direct(1'b1, 1'b1, 1'b0);
      for (int i = 0; i < 3; i++) send_item_direct(1'b1, 1'b0, 1'b0);
    end

    // TC_BURST_06: test_staircase_burst_decrements
    `uvm_info(get_type_name(), "Executing TC_BURST_06: test_staircase_burst_decrements", UVM_LOW)
    reset_dut();
    for (int rep = 0; rep < 4; rep++) begin
      for (int i = 0; i < 3; i++) send_item_direct(1'b1, 1'b0, 1'b1);
      for (int i = 0; i < 3; i++) send_item_direct(1'b1, 1'b0, 1'b0);
    end

    // TC_BURST_07: test_consecutive_up_pulses_with_single_cycle_gap.
    `uvm_info(get_type_name(), "Executing TC_BURST_07: test_consecutive_up_pulses_with_single_cycle_gap", UVM_LOW)
    decrement_to_zero();
    for (int i = 0; i < 10; i++) begin
      send_item_direct(1'b1, 1'b1, 1'b0);
      send_item_direct(1'b1, 1'b0, 1'b0);
    end

    // TC_BURST_08: test_consecutive_down_pulses_with_single_cycle_gap
    `uvm_info(get_type_name(), "Executing TC_BURST_08: test_consecutive_down_pulses_with_single_cycle_gap", UVM_LOW)
    reset_dut();
    for (int i = 0; i < 10; i++) begin
      send_item_direct(1'b1, 1'b0, 1'b1);
      send_item_direct(1'b1, 1'b0, 1'b0);
    end

    // =========================================================================
    // SECTION 6: Simultaneous Assertion (Conflict & Race Condition) Corner Cases
    // =========================================================================

    // TC_CONF_01: test_simultaneous_assertion_at_all_even_counts
    `uvm_info(get_type_name(), "Executing TC_CONF_01: test_simultaneous_assertion_at_all_even_counts", UVM_LOW)
    decrement_to_zero(); // count = 0
    for (int c = 0; c <= max_count; c += 2) begin
      for (int i = 0; i < 3; i++) begin
        send_item_direct(1'b1, 1'b1, 1'b1);
      end
      if (c + 2 <= max_count) begin
        send_item_direct(1'b1, 1'b1, 1'b0);
        send_item_direct(1'b1, 1'b1, 1'b0);
      end
    end

    // TC_CONF_02: test_simultaneous_assertion_at_all_odd_counts
    `uvm_info(get_type_name(), "Executing TC_CONF_02: test_simultaneous_assertion_at_all_odd_counts", UVM_LOW)
    decrement_to_zero();
    send_item_direct(1'b1, 1'b1, 1'b0); // count = 1
    for (int c = 1; c <= max_count; c += 2) begin
      for (int i = 0; i < 3; i++) begin
        send_item_direct(1'b1, 1'b1, 1'b1);
      end
      if (c + 2 <= max_count) begin
        send_item_direct(1'b1, 1'b1, 1'b0);
        send_item_direct(1'b1, 1'b1, 1'b0);
      end
    end

    // TC_CONF_03: test_asymmetric_duration_overlapping_pulses_up_leads
    `uvm_info(get_type_name(), "Executing TC_CONF_03: test_asymmetric_duration_overlapping_pulses_up_leads", UVM_LOW)
    set_counter_to_mid();
    send_item_direct(1'b1, 1'b1, 1'b0); // Cycle 1: up=1, down=0
    send_item_direct(1'b1, 1'b1, 1'b1); // Cycle 2: up=1, down=1
    send_item_direct(1'b1, 1'b1, 1'b1); // Cycle 3: up=1, down=1
    send_item_direct(1'b1, 1'b0, 1'b1); // Cycle 4: up=0, down=1

    // TC_CONF_04: test_asymmetric_duration_overlapping_pulses_down_leads
    `uvm_info(get_type_name(), "Executing TC_CONF_04: test_asymmetric_duration_overlapping_pulses_down_leads", UVM_LOW)
    set_counter_to_mid();
    send_item_direct(1'b1, 1'b0, 1'b1); // Cycle 1: up=0, down=1
    send_item_direct(1'b1, 1'b1, 1'b1); // Cycle 2: up=1, down=1
    send_item_direct(1'b1, 1'b1, 1'b1); // Cycle 3: up=1, down=1
    send_item_direct(1'b1, 1'b1, 1'b0); // Cycle 4: up=1, down=0

    // TC_CONF_05: test_long_sustained_simultaneous_assertion
    `uvm_info(get_type_name(), "Executing TC_CONF_05: test_long_sustained_simultaneous_assertion", UVM_LOW)
    set_counter_to_mid();
    for (int i = 0; i < 500; i++) begin
      send_item_direct(1'b1, 1'b1, 1'b1);
    end

    // =========================================================================
    // SECTION 7: Asynchronous Reset Interleaving & Timing Corner Cases
    // =========================================================================

    // TC_TIME_01: test_async_reset_asserted_coincident_with_lclk_posedge
    `uvm_info(get_type_name(), "Executing TC_TIME_01: test_async_reset_asserted_coincident_with_lclk_posedge", UVM_LOW)
    reset_dut();
    for (int i = 0; i <= (max_count - 5); i++) begin
      send_item_direct(1'b1, 1'b0, 1'b1); // step down to 5
    end
    send_item_direct(1'b0, 1'b0, 1'b0); // assert reset
    send_item_direct(1'b1, 1'b0, 1'b0);

    // TC_TIME_02: test_async_reset_asserted_at_lclk_negedge
    `uvm_info(get_type_name(), "Executing TC_TIME_02: test_async_reset_asserted_at_lclk_negedge", UVM_LOW)
    fork
      send_item_direct(1'b1, 1'b0, 1'b1);
      #1 send_item_direct(1'b0, 1'b0, 1'b1);
    join
    send_item_direct(1'b1, 1'b0, 1'b0);

    // =========================================================================
    // SECTION 8: Constrained-Random & High-Stress Verification
    // =========================================================================

    // TC_RAND_01: test_uniform_random_stimulus
    `uvm_info(get_type_name(), "Executing TC_RAND_01: test_uniform_random_stimulus", UVM_LOW)
    for (int i = 0; i < 1000; i++) begin
      send_item_scenario(up_down_counter_sequence_item::SCENARIO_NORMAL);
    end

    // TC_RAND_02: test_up_biased_saturation_stress
    `uvm_info(get_type_name(), "Executing TC_RAND_02: test_up_biased_saturation_stress", UVM_LOW)
    for (int i = 0; i < 500; i++) begin
      send_item_scenario(up_down_counter_sequence_item::SCENARIO_UP_BIASED);
    end

    // TC_RAND_03: test_down_biased_exhaustion_stress
    `uvm_info(get_type_name(), "Executing TC_RAND_03: test_down_biased_exhaustion_stress", UVM_LOW)
    for (int i = 0; i < 500; i++) begin
      send_item_scenario(up_down_counter_sequence_item::SCENARIO_DOWN_BIASED);
    end

    // TC_RAND_04: test_dual_assertion_dominant_stress
    `uvm_info(get_type_name(), "Executing TC_RAND_04: test_dual_assertion_dominant_stress", UVM_LOW)
    for (int i = 0; i < 500; i++) begin
      send_item_scenario(up_down_counter_sequence_item::SCENARIO_DUAL_DOMINANT);
    end

    // TC_RAND_05: test_random_asynchronous_reset_injection
    `uvm_info(get_type_name(), "Executing TC_RAND_05: test_random_asynchronous_reset_injection", UVM_LOW)
    for (int i = 0; i < 500; i++) begin
      send_item_scenario(up_down_counter_sequence_item::SCENARIO_RANDOM_RESET);
    end

    // TC_RAND_06: test_reset_assert_scenario
    `uvm_info(get_type_name(), "Executing TC_SCEN_01: test_reset_assert_scenario", UVM_LOW)
    for (int i = 0; i < 500; i++) begin
      send_item_scenario(up_down_counter_sequence_item::SCENARIO_RESET_ASSERT);
    end
    send_item_direct(1'b1, 1'b0, 1'b0); // deassert reset after scenario

    // TC_RAND_07: test_idle_scenario
    `uvm_info(get_type_name(), "Executing TC_SCEN_02: test_idle_scenario", UVM_LOW)
    set_counter_to_mid();
    for (int i = 0; i < 500; i++) begin
      send_item_scenario(up_down_counter_sequence_item::SCENARIO_IDLE);
    end

    // TC_RAND_08: test_inc_scenario
    `uvm_info(get_type_name(), "Executing TC_SCEN_03: test_inc_scenario", UVM_LOW)
    for (int i = 0; i < 500; i++) begin
      send_item_scenario(up_down_counter_sequence_item::SCENARIO_INC);
    end

    // TC_RAND_09: test_dec_scenario
    `uvm_info(get_type_name(), "Executing TC_SCEN_04: test_dec_scenario", UVM_LOW)
    for (int i = 0; i < 500; i++) begin
      send_item_scenario(up_down_counter_sequence_item::SCENARIO_DEC);
    end

    // TC_RAND_10: test_dual_scenario
    `uvm_info(get_type_name(), "Executing TC_SCEN_05: test_dual_scenario", UVM_LOW)
    set_counter_to_mid();
    for (int i = 0; i < 500; i++) begin
      send_item_scenario(up_down_counter_sequence_item::SCENARIO_DUAL);
    end

    `uvm_info(get_type_name(), "Completed all verification plan test cases successfully!", UVM_LOW)
  endtask

endclass

`endif // UP_DOWN_COUNTER_BASE_SEQUENCE_SVH
