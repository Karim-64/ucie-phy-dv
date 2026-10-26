`ifndef BIT_SYNC_SBTX_SUBSCRIBER_SVH
`define BIT_SYNC_SBTX_SUBSCRIBER_SVH

class BIT_SYNC_SBTX_subscriber extends uvm_subscriber #(BIT_SYNC_SBTX_sequence_item);
  `uvm_component_utils(BIT_SYNC_SBTX_subscriber)

  // Handle to the transaction currently being sampled.
  BIT_SYNC_SBTX_sequence_item cov_tr;

  // Helper logic
  static function logic [BUS_WIDTH-1:0] build_alt_01();
    logic [BUS_WIDTH-1:0] val = '0;
    for (int i = 0; i < BUS_WIDTH; i++) begin
      val[i] = (i % 2 == 0) ? 1'b0 : 1'b1;
    end
    return val;
  endfunction

  static function logic [BUS_WIDTH-1:0] build_alt_10();
    logic [BUS_WIDTH-1:0] val = '0;
    for (int i = 0; i < BUS_WIDTH; i++) begin
      val[i] = (i % 2 == 0) ? 1'b1 : 1'b0;
    end
    return val;
  endfunction

  localparam logic [BUS_WIDTH-1:0] VAL_ALT_01 = build_alt_01();
  localparam logic [BUS_WIDTH-1:0] VAL_ALT_10 = build_alt_10();

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
  covergroup BIT_SYNC_SBTX_cg;
    option.per_instance = 1;

    cp_rst_n: coverpoint cov_tr.rst_n{
      bins active = {1'b0};
      bins inactive  = {1'b1};
      bins toggle[] = (1=>0), (0=>1);
    }
    cp_async: coverpoint cov_tr.async{
      bins bin_0 = { {(BUS_WIDTH){1'b0}} };
      bins bin_1 = { {(BUS_WIDTH){1'b1}} };
    }
    cp_async_alt: coverpoint cov_tr.async{
      option.weight = (BUS_WIDTH > 1) ? 1 : 0;
      bins alt_01 = { VAL_ALT_01 };
      bins alt_10 = { VAL_ALT_10 };
    }
    cp_sync: coverpoint cov_tr.sync{
      bins bin_0 = { {(BUS_WIDTH){1'b0}} };
      bins bin_1 = { {(BUS_WIDTH){1'b1}} };
    }
    cp_sync_alt: coverpoint cov_tr.sync{
      option.weight = (BUS_WIDTH > 1) ? 1 : 0;
      bins alt_01 = { VAL_ALT_01 };
      bins alt_10 = { VAL_ALT_10 };
    }
  endgroup : BIT_SYNC_SBTX_cg

  function new(string name = "BIT_SYNC_SBTX_subscriber", uvm_component parent = null);
    super.new(name, parent);
    BIT_SYNC_SBTX_cg = new();
  endfunction : new

  function void write(BIT_SYNC_SBTX_sequence_item t);
    if (t == null) begin
      `uvm_error("BIT_SYNC_SBTX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    BIT_SYNC_SBTX_cg.sample();
  endfunction : write

endclass : BIT_SYNC_SBTX_subscriber

`endif // BIT_SYNC_SBTX_SUBSCRIBER_SVH
