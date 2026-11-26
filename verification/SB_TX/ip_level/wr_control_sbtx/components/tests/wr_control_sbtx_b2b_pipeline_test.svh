`ifndef WR_CONTROL_SBTX_B2B_PIPELINE_TEST_SVH
`define WR_CONTROL_SBTX_B2B_PIPELINE_TEST_SVH

// TC_06: Back-to-Back Pipelining Constrained-Random Test [Corner Case]
class wr_control_sbtx_b2b_pipeline_test extends wr_control_sbtx_base_test;
  `uvm_component_utils(wr_control_sbtx_b2b_pipeline_test)

  function new(string name = "wr_control_sbtx_b2b_pipeline_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    wr_control_sbtx_b2b_pipeline_seq b2b_seq;
    wr_control_sbtx_all_opcodes_seq     b2b_all_op_seq;

    b2b_seq     = wr_control_sbtx_b2b_pipeline_seq::type_id::create("b2b_seq");
    b2b_all_op_seq = wr_control_sbtx_all_opcodes_seq::type_id::create("b2b_all_op_seq");
    b2b_all_op_seq.use_idle_cycles = 0;

    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Running TC_06: wr_control_sbtx_b2b_pipeline_test", UVM_LOW)
    b2b_all_op_seq.start(env.agt.seqr);
    b2b_seq.start(env.agt.seqr);
    phase.drop_objection(this);
  endtask
endclass

`endif // WR_CONTROL_SBTX_B2B_PIPELINE_TEST_SVH

