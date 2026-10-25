`ifndef FIFO_RD_MBRX_SUBSCRIBER_SVH
`define FIFO_RD_MBRX_SUBSCRIBER_SVH

class fifo_rd_mbrx_subscriber extends uvm_subscriber #(fifo_rd_mbrx_sequence_item);
  `uvm_component_utils(fifo_rd_mbrx_subscriber)

  // Handle to the transaction currently being sampled.
  fifo_rd_mbrx_sequence_item cov_tr;

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
  covergroup fifo_rd_mbrx_cg;
    option.per_instance = 1;

    cp_r_rstn: coverpoint cov_tr.r_rstn;
    cp_r_inc: coverpoint cov_tr.r_inc;
    cp_sync_wr_ptr: coverpoint cov_tr.sync_wr_ptr {
      option.auto_bin_max = 16;
    }
    cp_rd_addr: coverpoint cov_tr.rd_addr {
      option.auto_bin_max = 16;
    }
    cp_empty: coverpoint cov_tr.empty;
    cp_gray_rd_ptr: coverpoint cov_tr.gray_rd_ptr {
      option.auto_bin_max = 16;
    }

    // TODO: Add iff-gated coverpoints and cross coverage specific to your DUT
    // (e.g. operation x address, data-pattern classification on valid transfers).
  endgroup : fifo_rd_mbrx_cg

  function new(string name = "fifo_rd_mbrx_subscriber", uvm_component parent = null);
    super.new(name, parent);
    fifo_rd_mbrx_cg = new();
  endfunction : new

  function void write(fifo_rd_mbrx_sequence_item t);
    if (t == null) begin
      `uvm_error("FIFO_RD_MBRX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    fifo_rd_mbrx_cg.sample();
  endfunction : write

endclass : fifo_rd_mbrx_subscriber

`endif // FIFO_RD_MBRX_SUBSCRIBER_SVH
