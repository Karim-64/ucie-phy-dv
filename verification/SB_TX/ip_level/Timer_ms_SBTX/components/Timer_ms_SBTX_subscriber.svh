`ifndef TIMER_MS_SBTX_SUBSCRIBER_SVH
`define TIMER_MS_SBTX_SUBSCRIBER_SVH

class Timer_ms_SBTX_subscriber extends uvm_subscriber #(Timer_ms_SBTX_sequence_item);
  `uvm_component_utils(Timer_ms_SBTX_subscriber)

  // Handle to the transaction currently being sampled.
  Timer_ms_SBTX_sequence_item cov_tr;

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
  covergroup Timer_ms_SBTX_cg;
    option.per_instance = 1;

    cp_rst_n: coverpoint cov_tr.rst_n{
      bins active = {0};
      bins inactive = {1'b1};
      bins toggle[] = (1=>0), (0=>1);
    }
    cp_start: coverpoint cov_tr.start{
      bins active = {1'b1};
      bins inactive = {0};
      bins toggle[] = (1=>0), (0=>1);
    }
    cp_alarm: coverpoint cov_tr.alarm{
      bins active = {1'b1};
      bins inactive = {0};
      bins toggle[] = (1=>0), (0=>1);
    }
    cp_patt_alarm: coverpoint cov_tr.patt_alarm{
      bins active = {1'b1};
      bins inactive = {0};
      bins toggle[] = (1=>0), (0=>1);
    }

    cross cp_start, cp_alarm, cp_patt_alarm{
      option.cross_auto_bin_max = 0;
      bins alarm_not_start = binsof(cp_start) intersect {0} && binsof(cp_alarm) intersect {1};
      bins patt_alarm_not_start = binsof(cp_start) intersect {0} && binsof(cp_patt_alarm) intersect {1};
    }

  endgroup : Timer_ms_SBTX_cg

  function new(string name = "Timer_ms_SBTX_subscriber", uvm_component parent = null);
    super.new(name, parent);
    Timer_ms_SBTX_cg = new();
  endfunction : new

  function void write(Timer_ms_SBTX_sequence_item t);
    if (t == null) begin
      `uvm_error("TIMER_MS_SBTX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    Timer_ms_SBTX_cg.sample();
  endfunction : write

endclass : Timer_ms_SBTX_subscriber

`endif // TIMER_MS_SBTX_SUBSCRIBER_SVH
