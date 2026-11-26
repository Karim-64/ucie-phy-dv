`ifndef WR_CONTROL_SBTX_RESET_TEST_SVH
`define WR_CONTROL_SBTX_RESET_TEST_SVH

// TC_01: Reset & Initialization Test [Corner Case]
class wr_control_sbtx_reset_test extends wr_control_sbtx_base_test;
  `uvm_component_utils(wr_control_sbtx_reset_test)

  function new(string name = "wr_control_sbtx_reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    wr_control_sbtx_reset_seq seq;
    seq = wr_control_sbtx_reset_seq::type_id::create("seq");

    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Running TC_01: wr_control_sbtx_reset_test", UVM_LOW)
    seq.start(env.agt.seqr);
    phase.drop_objection(this);
  endtask
endclass

`endif // WR_CONTROL_SBTX_RESET_TEST_SVH

