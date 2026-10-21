`ifndef UP_DOWN_COUNTER_SUBSCRIBER_SVH
`define UP_DOWN_COUNTER_SUBSCRIBER_SVH

class up_down_counter_subscriber extends uvm_component;
  `uvm_component_utils(up_down_counter_subscriber)
  uvm_analysis_export #(up_down_counter_sequence_item) exp;
  uvm_tlm_analysis_fifo #(up_down_counter_sequence_item) fifo;

  // Handle to the transaction currently being sampled
  up_down_counter_sequence_item cov_tr;

  logic [WIDTH-1:0] prev_count;

  int unsigned total_samples;


  covergroup up_down_counter_cg;
    option.per_instance = 1;
    option.name = "up_down_counter_Functional_Coverage";

    cp_sys_rst: coverpoint cov_tr.sys_rst {
      bins rst_active     = {1'b0};
      bins rst_inactive   = {1'b1};
      bins rst_asserted   = (1'b1 => 1'b0);
      bins rst_deasserted = (1'b0 => 1'b1);
    }

    cp_up: coverpoint cov_tr.up {
      bins low           = {1'b0};
      bins high          = {1'b1};
      bins trans_0_to_1  = (1'b0 => 1'b1);
      bins trans_1_to_0  = (1'b1 => 1'b0);
      bins consec_high   = (1'b1 => 1'b1);
      bins consec_low    = (1'b0 => 1'b0);
    }

    cp_down: coverpoint cov_tr.down {
      bins low           = {1'b0};
      bins high          = {1'b1};
      bins trans_0_to_1  = (1'b0 => 1'b1);
      bins trans_1_to_0  = (1'b1 => 1'b0);
      bins consec_high   = (1'b1 => 1'b1);
      bins consec_low    = (1'b0 => 1'b0);
    }

    cp_operation: coverpoint {cov_tr.up, cov_tr.down} {
      bins s0_idle = {2'b00};
      bins s1_inc  = {2'b10};
      bins s2_dec  = {2'b01};
      bins s3_dual = {2'b11};
    }


    cp_op_transitions: coverpoint {cov_tr.up, cov_tr.down} {
      bins s0_to_s0 = (2'b00 => 2'b00);
      bins s0_to_s1 = (2'b00 => 2'b10);
      bins s0_to_s2 = (2'b00 => 2'b01);
      bins s0_to_s3 = (2'b00 => 2'b11);
      bins s1_to_s0 = (2'b10 => 2'b00);
      bins s1_to_s1 = (2'b10 => 2'b10);
      bins s1_to_s2 = (2'b10 => 2'b01);
      bins s1_to_s3 = (2'b10 => 2'b11);
      bins s2_to_s0 = (2'b01 => 2'b00);
      bins s2_to_s1 = (2'b01 => 2'b10);
      bins s2_to_s2 = (2'b01 => 2'b01);
      bins s2_to_s3 = (2'b01 => 2'b11);
      bins s3_to_s0 = (2'b11 => 2'b00);
      bins s3_to_s1 = (2'b11 => 2'b10);
      bins s3_to_s2 = (2'b11 => 2'b01);
      bins s3_to_s3 = (2'b11 => 2'b11);
    }

    cp_count_values: coverpoint cov_tr.count {
      bins min_zero       = {0};
      bins min_plus_one   = {1};
      bins mid_range[]    = {[2:((1<<WIDTH)-3)]};
      bins max_minus_one  = {((1<<WIDTH)-2)};
      bins max_val        = {((1<<WIDTH)-1)};
    }

    cp_count_boundary: coverpoint cov_tr.count {
      bins at_min = {0};
      bins at_max = {((1<<WIDTH)-1)};
      bins in_mid = {[1:((1<<WIDTH)-2)]};
    }

    cp_count_parity: coverpoint (cov_tr.count[0]) {
      bins even_count = {1'b0};
      bins odd_count  = {1'b1};
    }

    cp_count_transitions: coverpoint cov_tr.count {
      bins sat_clamp_max    = (((1<<WIDTH)-1) => ((1<<WIDTH)-1));
      bins sat_clamp_min    = (0 => 0);
      bins reversal_at_max  = (((1<<WIDTH)-1) => ((1<<WIDTH)-2));
      bins reversal_at_min  = (0 => 1);
      bins step_up_to_max   = (((1<<WIDTH)-2) => ((1<<WIDTH)-1));
      bins step_down_to_min = (1 => 0);
    }

    cp_burst_patterns: coverpoint {cov_tr.up, cov_tr.down} {
      bins consecutive_inc  = (2'b10 [* 3]);
      bins consecutive_dec  = (2'b01 [* 3]);
      bins ping_pong        = (2'b10 => 2'b01 => 2'b10);
      bins alternating_hold = (2'b11 => 2'b00 => 2'b11);
      bins inc_with_gap     = (2'b10 => 2'b00 => 2'b10);
      bins dec_with_gap     = (2'b01 => 2'b00 => 2'b01);
    }

    cp_scenario_mode: coverpoint cov_tr.scenario_mode {
      bins normal        = {up_down_counter_sequence_item::SCENARIO_NORMAL};
      bins reset_assert  = {up_down_counter_sequence_item::SCENARIO_RESET_ASSERT};
      bins idle          = {up_down_counter_sequence_item::SCENARIO_IDLE};
      bins inc           = {up_down_counter_sequence_item::SCENARIO_INC};
      bins dec           = {up_down_counter_sequence_item::SCENARIO_DEC};
      bins dual          = {up_down_counter_sequence_item::SCENARIO_DUAL};
      bins up_biased     = {up_down_counter_sequence_item::SCENARIO_UP_BIASED};
      bins down_biased   = {up_down_counter_sequence_item::SCENARIO_DOWN_BIASED};
      bins dual_dominant = {up_down_counter_sequence_item::SCENARIO_DUAL_DOMINANT};
      bins random_reset  = {up_down_counter_sequence_item::SCENARIO_RANDOM_RESET};
    }

    cross_reset_x_operation: cross cp_sys_rst, cp_operation {
      bins rst_with_idle = binsof(cp_sys_rst.rst_active) && binsof(cp_operation.s0_idle);
      bins rst_with_inc  = binsof(cp_sys_rst.rst_active) && binsof(cp_operation.s1_inc);
      bins rst_with_dec  = binsof(cp_sys_rst.rst_active) && binsof(cp_operation.s2_dec);
      bins rst_with_dual = binsof(cp_sys_rst.rst_active) && binsof(cp_operation.s3_dual);
    }

    cross_boundary_x_op: cross cp_count_boundary, cp_operation iff (cov_tr.sys_rst == 1'b1) {
      bins max_sat_inc   = binsof(cp_count_boundary.at_max) && binsof(cp_operation.s1_inc);
      bins max_reversal  = binsof(cp_count_boundary.at_max) && binsof(cp_operation.s2_dec);
      bins max_dual_hold = binsof(cp_count_boundary.at_max) && binsof(cp_operation.s3_dual);
      bins max_idle_hold = binsof(cp_count_boundary.at_max) && binsof(cp_operation.s0_idle);

      bins min_sat_dec   = binsof(cp_count_boundary.at_min) && binsof(cp_operation.s2_dec);
      bins min_reversal  = binsof(cp_count_boundary.at_min) && binsof(cp_operation.s1_inc);
      bins min_dual_hold = binsof(cp_count_boundary.at_min) && binsof(cp_operation.s3_dual);
      bins min_idle_hold = binsof(cp_count_boundary.at_min) && binsof(cp_operation.s0_idle);

      bins mid_inc       = binsof(cp_count_boundary.in_mid) && binsof(cp_operation.s1_inc);
      bins mid_dec       = binsof(cp_count_boundary.in_mid) && binsof(cp_operation.s2_dec);
      bins mid_dual      = binsof(cp_count_boundary.in_mid) && binsof(cp_operation.s3_dual);
      bins mid_idle      = binsof(cp_count_boundary.in_mid) && binsof(cp_operation.s0_idle);
    }

    cross_parity_x_dual: cross cp_count_parity, cp_operation iff (cov_tr.sys_rst == 1'b1) {
      bins even_with_dual = binsof(cp_count_parity.even_count) && binsof(cp_operation.s3_dual);
      bins odd_with_dual  = binsof(cp_count_parity.odd_count)  && binsof(cp_operation.s3_dual);
    }
  endgroup : up_down_counter_cg

  function new(string name = "up_down_counter_subscriber", uvm_component parent = null);
    super.new(name, parent);
    exp   = new("exp", this);
    fifo  = new("fifo", this);
    exp.connect(fifo.analysis_export);
    up_down_counter_cg = new();
    total_samples = 0;
    prev_count    = {WIDTH{1'b1}};
  endfunction : new

  task run_phase(uvm_phase phase);
    up_down_counter_sequence_item t;
    super.run_phase(phase);
    forever begin
      fifo.get(t);
      sample_item(t);
    end
  endtask

  function void sample_item(up_down_counter_sequence_item t);
    if (t == null) begin
      `uvm_error("UP_DOWN_COUNTER_COV", "Received null transaction in up_down_counter_subscriber")
      return;
    end
    prev_count = cov_tr ? cov_tr.count : {WIDTH{1'b1}};
    cov_tr = t;
    up_down_counter_cg.sample();
    total_samples++;
  endfunction

  // ---------------------------------------------------------------------------
  // Report Phase - summarize coverage results in simulation log
  // ---------------------------------------------------------------------------
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)
    `uvm_info("COV_REPORT", "         UP_DOWN_COUNTER FUNCTIONAL COVERAGE REPORT         ", UVM_NONE)
    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf(" Total Coverage Samples Collected: %0d", total_samples), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf(" Total Coverage Achieved         : %0.2f %%", up_down_counter_cg.get_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", "------------------------------------------------------------", UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cp_sys_rst coverage            : %0.2f %%", up_down_counter_cg.cp_sys_rst.get_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cp_up coverage                 : %0.2f %%", up_down_counter_cg.cp_up.get_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cp_down coverage               : %0.2f %%", up_down_counter_cg.cp_down.get_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cp_operation coverage          : %0.2f %%", up_down_counter_cg.cp_operation.get_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cp_op_transitions coverage     : %0.2f %%", up_down_counter_cg.cp_op_transitions.get_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cp_count_values coverage       : %0.2f %%", up_down_counter_cg.cp_count_values.get_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cp_count_boundary coverage     : %0.2f %%", up_down_counter_cg.cp_count_boundary.get_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cp_count_parity coverage       : %0.2f %%", up_down_counter_cg.cp_count_parity.get_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cp_count_transitions coverage  : %0.2f %%", up_down_counter_cg.cp_count_transitions.get_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cp_burst_patterns coverage     : %0.2f %%", up_down_counter_cg.cp_burst_patterns.get_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cp_scenario_mode coverage      : %0.2f %%", up_down_counter_cg.cp_scenario_mode.get_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cross_reset_x_operation        : %0.2f %%", up_down_counter_cg.cross_reset_x_operation.get_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cross_boundary_x_op coverage   : %0.2f %%", up_down_counter_cg.cross_boundary_x_op.get_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cross_parity_x_dual coverage   : %0.2f %%", up_down_counter_cg.cross_parity_x_dual.get_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)

    if (up_down_counter_cg.get_coverage() >= 100.0)
      `uvm_info("COV_REPORT", "   *** COVERAGE GOAL: 100% ACHIEVED! ***", UVM_NONE)
    else
      `uvm_warning("COV_REPORT", $sformatf("   *** COVERAGE GOAL NOT MET: %.2f%% (see details above) ***", up_down_counter_cg.get_coverage()))
    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)
  endfunction : report_phase

endclass : up_down_counter_subscriber

`endif // UP_DOWN_COUNTER_SUBSCRIBER_SVH
