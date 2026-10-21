`ifndef PACKET_BUFFER_SBRX_SUBSCRIBER_SVH
`define PACKET_BUFFER_SBRX_SUBSCRIBER_SVH

class Packet_buffer_SBRX_subscriber extends uvm_subscriber #(Packet_buffer_SBRX_sequence_item);
  `uvm_component_utils(Packet_buffer_SBRX_subscriber)

  // Handle to the transaction currently being sampled.
  Packet_buffer_SBRX_sequence_item cov_tr;

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

  covergroup Packet_buffer_SBRX_cg;
    option.per_instance = 1;

    cp_sys_rst: coverpoint cov_tr.sys_rst;
    cp_wr_en: coverpoint cov_tr.wr_en;
    cp_rd_en: coverpoint cov_tr.rd_en;
    cp_wr_data: coverpoint cov_tr.wr_data {
      option.auto_bin_max = 16;
    }
    cp_rd_data: coverpoint cov_tr.rd_data {
      option.auto_bin_max = 16;
    }
    cp_full: coverpoint cov_tr.full;
    cp_empty: coverpoint cov_tr.empty;

    cp_full_empty: cross cp_full, cp_empty {
      illegal_bins full_and_empty = binsof(cp_full) intersect {1} && binsof(cp_empty) intersect {1};
    }

    cp_wr_full: cross cp_wr_en, cp_full;
    cp_rd_empty: cross cp_rd_en, cp_empty;
  endgroup : Packet_buffer_SBRX_cg

  function new(string name = "Packet_buffer_SBRX_subscriber", uvm_component parent = null);
    super.new(name, parent);
    Packet_buffer_SBRX_cg = new();
  endfunction : new

  function void write(Packet_buffer_SBRX_sequence_item t);
    if (t == null) begin
      `uvm_error("PACKET_BUFFER_SBRX_COV", "Received a null transaction")
      return;
    end
    cov_tr = t;
    Packet_buffer_SBRX_cg.sample();
  endfunction : write

endclass : Packet_buffer_SBRX_subscriber

`endif // PACKET_BUFFER_SBRX_SUBSCRIBER_SVH
