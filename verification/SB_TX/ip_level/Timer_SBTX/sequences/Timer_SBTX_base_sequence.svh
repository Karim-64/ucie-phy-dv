`ifndef TIMER_SBTX_BASE_SEQUENCE_SVH
`define TIMER_SBTX_BASE_SEQUENCE_SVH


class Timer_SBTX_base_sequence extends uvm_sequence #(Timer_SBTX_sequence_item);
  `uvm_object_utils(Timer_SBTX_base_sequence)
  `uvm_declare_p_sequencer(Timer_SBTX_sequencer)

  int unsigned n          = NO_OF_CYCLES;
  int unsigned term_cnt   = NO_OF_CYCLES - 1;
  int unsigned op_margin  = NO_OF_CYCLES + 2;

  function new(string name = "Timer_SBTX_base_sequence");
    super.new(name);
  endfunction

  // ===================================================================================================================
  //  Helper Methods
  // ===================================================================================================================

  // Drive one directed cycle (all item constraints disabled)
  task send_item_direct(logic rst, logic st);
    Timer_SBTX_sequence_item item;
    item = Timer_SBTX_sequence_item::type_id::create("item");
    start_item(item);
    item.constraint_mode(0);
    if (!item.randomize() with {
      rst_n == rst;
      start == st;
    }) `uvm_error("SEQ", "Randomization failed in send_item_direct")
    finish_item(item);
    p_sequencer.seqr_aport.write(item);
  endtask

  task send_item_random_reset(logic st);
    Timer_SBTX_sequence_item item;
    item = Timer_SBTX_sequence_item::type_id::create("item");
    start_item(item);
    item.constraint_mode(0);
    item.c_rand_reset.constraint_mode(0);
    if (!item.randomize() with {
      start == st;
    }) `uvm_error("SEQ", "Randomization failed in send_random_reset_item")
    finish_item(item);
    p_sequencer.seqr_aport.write(item);
  endtask

  task send_item_random_start(logic rst);
    Timer_SBTX_sequence_item item;
    item = Timer_SBTX_sequence_item::type_id::create("item");
    start_item(item);
    item.constraint_mode(0);
    item.c_rand_reset.constraint_mode(0);
    if (!item.randomize() with {
      rst_n == rst;
    }) `uvm_error("SEQ", "Randomization failed in send_random_start_item")
    finish_item(item);
    p_sequencer.seqr_aport.write(item);
  endtask


task send_item_random();
    Timer_SBTX_sequence_item item;
    item = Timer_SBTX_sequence_item::type_id::create("item");
    start_item(item);
    item.constraint_mode(0);
    item.c_rand.constraint_mode(0);
    if (!item.randomize()) `uvm_error("SEQ", "Randomization failed in send_random_item")
    finish_item(item);
    p_sequencer.seqr_aport.write(item);
  endtask


  task body();
    bit          toggle;
    int unsigned idle_gap;

    // =================================================================================================================
    // 1. Reset & Initialization Verification (Active-Low Asynchronous rst_n)
    // =================================================================================================================

    // TC_RST_01
      `uvm_info(get_type_name(), "Starting TC_RST_01: Reset Asserted", UVM_LOW)
      for(int i = 0 ; i < 10 ; i++) begin
        send_item_direct(1'b0, 1'b0);
      end
    // TC_RST_02
      `uvm_info(get_type_name(), "Starting TC_RST_02: test_reset_priority_over_start", UVM_LOW)
      for(int i = 0 ; i < op_margin ; i++) begin
        send_item_direct(1'b0, 1'b1);
      end
    // TC_RST_03
      `uvm_info(get_type_name(), "Starting TC_RST_03: test_async_reset", UVM_LOW)
        send_item_direct(1'b0, 1'b1);
        send_item_direct(1'b1, 1'b1);
        send_item_direct(1'b0, 1'b1);
    // TC_RST_04
      `uvm_info(get_type_name(), "Starting TC_RST_04: test_idle_after_reset_release", UVM_LOW)
        send_item_direct(1'b0, 1'b1);
        send_item_direct(1'b1, 1'b0);
        for(int i = 0 ; i < 3*n ; i++) begin
          send_item_direct(1'b1, 1'b0);
        end
    // TC_RST_05
      `uvm_info(get_type_name(), "Starting TC_RST_05: test_start_coincident_with_reset_release", UVM_LOW)
        send_item_direct(1'b0, 1'b1);
        send_item_direct(1'b1, 1'b1);
        for(int i = 0 ; i < op_margin; i++) begin
          send_item_direct(1'b1, 1'b0);
        end
    // TC_RST_06
      `uvm_info(get_type_name(), "Starting TC_RST_06: test_multiple_back_to_back_resets", UVM_LOW)
        send_item_direct(1'b0, 1'b0);
        send_item_direct(1'b1, 1'b0);
        send_item_direct(1'b0, 1'b0);
        send_item_direct(1'b0, 1'b0);
        send_item_direct(1'b0, 1'b0);
        send_item_direct(1'b1, 1'b0);
        send_item_direct(1'b1, 1'b0);
        send_item_direct(1'b0, 1'b0);
    // TC_RST_07
      `uvm_info(get_type_name(), "Starting TC_RST_07: test_long_reset_with_random_start", UVM_LOW)
        for(int i = 0; i < 200 ; i++) begin
          send_item_random_start(0);
        end

    // =================================================================================================================
    // 2. Basic Start & Counting Operation
    // =================================================================================================================

    // TC_BAS_01
      `uvm_info(get_type_name(), "Starting TC_BAS_01: test_single_start_pulse", UVM_LOW)
        send_item_direct(1'b0, 1'b0);
        send_item_direct(1'b1, 1'b1);
        for(int i = 0 ; i < n ; i++) begin
          send_item_random_start(1);
        end
    // TC_BAS_02
      `uvm_info(get_type_name(), "Starting TC_BAS_02: test_start_held_whole_operation_then_low", UVM_LOW)
        send_item_direct(1'b0, 1'b0);
        send_item_direct(1'b1, 1'b1);
        for(int i = 0 ; i < n-1 ; i++) begin
          send_item_direct(1'b1, 1'b1);
        end
        send_item_direct(1'b1, 1'b0);

    // TC_BAS_03
      `uvm_info(get_type_name(), "Starting TC_BAS_03: test_return_to_idle_after_completion", UVM_LOW)
        send_item_direct(1'b0, 1'b0);
        send_item_direct(1'b1, 1'b1);
        for(int i = 0 ; i < n ; i++) begin
          send_item_direct(1'b1, 1'b0);
        end
        for(int i = 0 ; i < 5*n ; i++) begin
          send_item_direct(1'b1, 1'b0);
        end 

    // TC_BAS_04
      `uvm_info(get_type_name(), "Starting TC_BAS_04: test_two_operations_with_idle_gap", UVM_LOW)
        send_item_direct(1'b0, 1'b0);
        send_item_direct(1'b1, 1'b1);
        for(int i = 0 ; i < n ; i++) begin
          send_item_direct(1'b1, 1'b0);
        end
        for(int i = 0 ; i < 10 ; i++) begin
          send_item_direct(1'b1, 1'b0);
        end
        send_item_direct(1'b1, 1'b1);
        for(int i = 0 ; i < n ; i++) begin
          send_item_direct(1'b1, 1'b0);
        end
        send_item_direct(1'b1, 1'b0);

    // =================================================================================================================
    // 3. Start Request Corner Cases (Re-Assertion While Busy, Sampling, Glitches)
    // =================================================================================================================

    // TC_STR_01
      `uvm_info(get_type_name(), "Starting TC_STR_01: test_start_reassert_mid_count", UVM_LOW)
        send_item_direct(1'b0, 1'b0);
        send_item_direct(1'b1, 1'b1);
        for(int i = 0 ; i < n/2 ; i++) begin
          send_item_direct(1'b1, 1'b0);
        end
        send_item_direct(1'b0, 1'b0);
    // TC_STR_02
      `uvm_info(get_type_name(), "Starting TC_STR_02: test_start_reassert_at_count_1", UVM_LOW)
        send_item_direct(1'b0, 1'b0);
        send_item_direct(1'b1, 1'b1);
          send_item_direct(1'b1, 1'b0);
        send_item_direct(1'b0, 1'b0);
    // TC_STR_03
      `uvm_info(get_type_name(), "Starting TC_STR_03: test_start_reassert_at_count_1", UVM_LOW)
        send_item_direct(1'b0, 1'b0);
        send_item_direct(1'b1, 1'b1);
        for(int i = 0 ; i < n-2 ; i++) begin
          send_item_direct(1'b1, 1'b0);
        end
        send_item_direct(1'b0, 1'b0);
    // TC_STR_04
      `uvm_info(get_type_name(), "Starting TC_STR_04: test_start_pulse_during_alarm_cycle", UVM_LOW)
        send_item_direct(1'b0, 1'b0);
        send_item_direct(1'b1, 1'b1);
        for(int i = 0 ; i < n-2 ; i++) begin
          send_item_direct(1'b1, 1'b0);
        end
        send_item_direct(1'b1, 1'b1);
    // TC_STR_05
      `uvm_info(get_type_name(), "Starting TC_STR_05: test_start_toggling_every_cycle_while_busy", UVM_LOW)
        send_item_direct(1'b0, 1'b0);
        send_item_direct(1'b1, 1'b1);
        toggle = 0;
        for(int i = 0 ; i < n-1 ; i++) begin
          send_item_direct(1'b1, toggle);
          toggle = ~toggle;
        end
        send_item_direct(1'b0, 1'b0);
    // TC_STR_06
      `uvm_info(get_type_name(), "Starting TC_STR_06: test_start_never_asserted", UVM_LOW)
        send_item_direct(1'b0, 1'b0);
        for(int i = 0 ; i < 1000 ; i++) begin
          send_item_direct(1'b1, 0);
        end

    // =================================================================================================================
    // 4. Reset During Counting (Abort Operation)
    // =================================================================================================================

    // TC_RDC_01
      `uvm_info(get_type_name(), "Starting TC_RDC_01: test_start_never_asserted", UVM_LOW)
        send_item_direct(1'b0, 1'b0);
        send_item_direct(1'b0, 1'b1);
        for(int i = 0 ; i < n-2 ; i++) begin
          send_item_direct(1'b1, 0);
        end
        send_item_direct(1'b1, 1'b0);
    // TC_RDC_02
      `uvm_info(get_type_name(), "Starting TC_RDC_02: test_reset_at_every_count_value", UVM_LOW)
        send_item_direct(1'b0, 1'b0);
        send_item_direct(1'b0, 1'b1);
        for(int i = 0 ; i < n-1 ; i++) begin
          for(int k = 0 ; k < n-1 ; k++) begin
            if(i == k) send_item_direct(1'b0, 1'b0);
            else send_item_direct(1'b1, 1'b0);
          end
        end
        send_item_direct(1'b0, 1'b0);

    // =================================================================================================================
    // 5. Back-to-Back, Constrained-Random & Stress Verification
    // =================================================================================================================

    // TC_STS_01
      `uvm_info(get_type_name(), "Starting TC_STS_01: test_reset_at_every_count_value", UVM_LOW)
        send_item_direct(1'b0, 1'b0);
        send_item_direct(1'b0, 1'b1);
        for(int i = 0 ; i < 100 ; i++) begin
          send_item_direct(1'b0, 1'b1);
          for(int k = 0 ; k < n-1 ; k++) begin
            send_item_direct(1'b1, 1'b0);
          end
        end
        send_item_direct(1'b0, 1'b0);

    // TC_STS_02
      `uvm_info(get_type_name(), "Starting TC_STS_02: test_random_gaps_between_operations", UVM_LOW)
        send_item_direct(1'b0, 1'b0);
        send_item_direct(1'b0, 1'b1);
        for(int i = 0 ; i < 100 ; i++) begin
          send_item_direct(1'b0, 1'b1);
          for(int k = 0 ; k < n-1 ; k++) begin
            send_item_direct(1'b1, 1'b0);
          end

          idle_gap = $urandom_range(n, 0);
          for(int j = 0 ; j < idle_gap ; j++) begin
            send_item_direct(1'b1, 1'b0);
          end
        end
        send_item_direct(1'b0, 1'b0);

    `uvm_info(get_type_name(), "Completed all verification plan test cases successfully!", UVM_LOW)
  endtask

endclass

`endif // TIMER_SBTX_BASE_SEQUENCE_SVH
