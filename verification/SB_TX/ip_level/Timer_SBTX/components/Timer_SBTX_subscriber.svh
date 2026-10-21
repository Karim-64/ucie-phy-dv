`ifndef TIMER_SBTX_SUBSCRIBER_SVH
`define TIMER_SBTX_SUBSCRIBER_SVH

class Timer_SBTX_subscriber extends uvm_component;
  `uvm_component_utils(Timer_SBTX_subscriber)

  // Handle to the transaction currently being sampled.
  Timer_SBTX_sequence_item cov_tr;
  uvm_analysis_export #(Timer_SBTX_sequence_item) exp;
  uvm_tlm_analysis_fifo #(Timer_SBTX_sequence_item) fifo;

  int unsigned total_samples;

  // ---------------------------------------------------------------------
  // Functional Coverage
  //
  // Simple signal-based coverage of the three interface signals:
  //   - Base coverpoints : value of rst_n, start and alarm.
  //   - Transition points: edges / back-to-back values of each signal
  //                        (kept separate because transition bins cannot
  //                         be used in a cross).
  //   - Base crosses     : every combination of the base coverpoints.
  // ---------------------------------------------------------------------
  covergroup Timer_SBTX_cg;
    option.per_instance = 1;
    option.name         = "Timer_SBTX_Functional_Coverage";

    // ---------------- Base coverpoints (signal values) ----------------
    cp_rst_n: coverpoint cov_tr.rst_n {
      bins asserted   = {1'b0};   // reset active (active-low)
      bins deasserted = {1'b1};   // reset inactive
    }

    cp_start: coverpoint cov_tr.start {
      bins low  = {1'b0};
      bins high = {1'b1};
    }

    cp_alarm: coverpoint cov_tr.alarm {
      bins low  = {1'b0};
      bins high = {1'b1};         // terminal count reached
    }

    // ---------------- Transition coverpoints ----------------
    cp_rst_n_trans: coverpoint cov_tr.rst_n {
      bins assert_edge   = (1'b1 => 1'b0);
      bins deassert_edge = (1'b0 => 1'b1);
      bins held_asserted = (1'b0 => 1'b0);
      bins held_released = (1'b1 => 1'b1);
    }

    cp_start_trans: coverpoint cov_tr.start {
      bins rise      = (1'b0 => 1'b1);
      bins fall      = (1'b1 => 1'b0);
      bins held_high = (1'b1 => 1'b1);
      bins held_low  = (1'b0 => 1'b0);
    }

    cp_alarm_trans: coverpoint cov_tr.alarm {
      bins rise      = (1'b0 => 1'b1);
      bins fall      = (1'b1 => 1'b0);
      bins held_low  = (1'b0 => 1'b0);
    }

    cross_rst_n_x_start: cross cp_rst_n, cp_start;

    // alarm can never be high while reset is asserted (spec 4.1: alarm must be
    // low once reset takes effect) - this combination is unreachable on a
    // correct DUT and is checked by the scoreboard, so exclude it from coverage.
    cross_rst_n_x_alarm: cross cp_rst_n, cp_alarm {
      ignore_bins rst_asserted_alarm_high =
        binsof(cp_rst_n.asserted) && binsof(cp_alarm.high);
    }

    cross_start_x_alarm: cross cp_start, cp_alarm;

    cross_rst_n_x_start_x_alarm: cross cp_rst_n, cp_start, cp_alarm {
      ignore_bins rst_asserted_alarm_high =
        binsof(cp_rst_n.asserted) && binsof(cp_alarm.high);
    }
  endgroup : Timer_SBTX_cg

  function new(string name = "Timer_SBTX_subscriber", uvm_component parent = null);
    super.new(name, parent);
    Timer_SBTX_cg = new();
    exp   = new("exp", this);
    fifo  = new("fifo", this);
    exp.connect(fifo.analysis_export);
    total_samples = 0;
  endfunction : new

  task run_phase(uvm_phase phase);
    Timer_SBTX_sequence_item t;
    super.run_phase(phase);
    forever begin
      fifo.get(t);
      sample_item(t);
    end
  endtask

  function void sample_item(Timer_SBTX_sequence_item t);
    if (t == null) begin
      `uvm_error("TIMER_SBTX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    Timer_SBTX_cg.sample();
    total_samples++;
  endfunction : sample_item

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)
    `uvm_info("COV_REPORT", "          TIMER_SBTX FUNCTIONAL COVERAGE REPORT             ", UVM_NONE)
    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf(" Total Samples Collected    : %0d", total_samples), UVM_NONE)
    `uvm_info("COV_REPORT", "------------------------------------------------------------", UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf(" Overall Coverage           : %6.2f %%", Timer_SBTX_cg.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", "------------------------------------------------------------", UVM_NONE)
    `uvm_info("COV_REPORT", " Coverpoints (values):", UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cp_rst_n                 : %6.2f %%", Timer_SBTX_cg.cp_rst_n.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cp_start                 : %6.2f %%", Timer_SBTX_cg.cp_start.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cp_alarm                 : %6.2f %%", Timer_SBTX_cg.cp_alarm.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", " Coverpoints (transitions):", UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cp_rst_n_trans           : %6.2f %%", Timer_SBTX_cg.cp_rst_n_trans.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cp_start_trans           : %6.2f %%", Timer_SBTX_cg.cp_start_trans.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   cp_alarm_trans           : %6.2f %%", Timer_SBTX_cg.cp_alarm_trans.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", " Crosses:", UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   rst_n x start            : %6.2f %%", Timer_SBTX_cg.cross_rst_n_x_start.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   rst_n x alarm            : %6.2f %%", Timer_SBTX_cg.cross_rst_n_x_alarm.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   start x alarm            : %6.2f %%", Timer_SBTX_cg.cross_start_x_alarm.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   rst_n x start x alarm    : %6.2f %%", Timer_SBTX_cg.cross_rst_n_x_start_x_alarm.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", "------------------------------------------------------------", UVM_NONE)

    if (total_samples == 0)
      `uvm_warning("COV_REPORT", "    *** [COVERAGE INCOMPLETE] NO SAMPLES COLLECTED! ***    ")
    else if (Timer_SBTX_cg.get_inst_coverage() >= 100.0)
      `uvm_info("COV_REPORT", "        *** [COVERAGE GOAL MET] 100% FUNCTIONAL COVERAGE ***", UVM_NONE)
    else
      `uvm_info("COV_REPORT", "        *** [COVERAGE GOAL NOT MET] HOLES REMAIN ***        ", UVM_NONE)
    `uvm_info("COV_REPORT", "============================================================", UVM_NONE)
  endfunction : report_phase

endclass : Timer_SBTX_subscriber

`endif // TIMER_SBTX_SUBSCRIBER_SVH