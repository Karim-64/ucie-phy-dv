`ifndef WR_CONTROL_SBTX_MID_PKT_RST_TEST_SVH
`define WR_CONTROL_SBTX_MID_PKT_RST_TEST_SVH

// TC_07: Mid-Packet Async Reset Test [Corner Case]
class wr_control_sbtx_mid_pkt_rst_test extends wr_control_sbtx_base_test;
  `uvm_component_utils(wr_control_sbtx_mid_pkt_rst_test)

  function new(string name = "wr_control_sbtx_mid_pkt_rst_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    wr_control_sbtx_mid_pkt_rst_seq seq;
    seq = wr_control_sbtx_mid_pkt_rst_seq::type_id::create("seq");

    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Running TC_07: wr_control_sbtx_mid_pkt_rst_test", UVM_LOW)
    seq.start(env.agt.seqr);
    phase.drop_objection(this);
  endtask
endclass

`endif // WR_CONTROL_SBTX_MID_PKT_RST_TEST_SVH

