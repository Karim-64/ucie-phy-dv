`ifndef MEM_SUBSCRIBER_SVH
`define MEM_SUBSCRIBER_SVH

class mem_subscriber extends uvm_subscriber #(mem_sequence_item);
  `uvm_component_utils(mem_subscriber)

  // Handle to the transaction currently being sampled.
  mem_sequence_item cov_tr;

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
  covergroup mem_cg;
    option.per_instance = 1;

    cp_rst: coverpoint cov_tr.rst;
    cp_cs: coverpoint cov_tr.cs;
    cp_we: coverpoint cov_tr.we;
    cp_addr: coverpoint cov_tr.addr {
      option.auto_bin_max = 16;
    }
    cp_data_in: coverpoint cov_tr.data_in {
      option.auto_bin_max = 16;
    }
    cp_data_out: coverpoint cov_tr.data_out {
      option.auto_bin_max = 16;
    }
    cp_valid_out: coverpoint cov_tr.valid_out;

    // TODO: Add iff-gated coverpoints and cross coverage specific to your DUT
    // (e.g. operation x address, data-pattern classification on valid transfers).
  endgroup : mem_cg

  function new(string name = "mem_subscriber", uvm_component parent = null);
    super.new(name, parent);
    mem_cg = new();
  endfunction : new

  function void write(mem_sequence_item t);
    if (t == null) begin
      `uvm_error("MEM_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    mem_cg.sample();
  endfunction : write

endclass : mem_subscriber

`endif // MEM_SUBSCRIBER_SVH
