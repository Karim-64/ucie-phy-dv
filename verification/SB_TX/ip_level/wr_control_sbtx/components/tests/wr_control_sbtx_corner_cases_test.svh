`ifndef WR_CONTROL_SBTX_CORNER_CASES_TEST_SVH
`define WR_CONTROL_SBTX_CORNER_CASES_TEST_SVH

// TC_08: BE/MsgCode Collision, Reserved Opcode & Idle Noise Test [Corner Case]
class wr_control_sbtx_corner_cases_test extends wr_control_sbtx_base_test;
  `uvm_component_utils(wr_control_sbtx_corner_cases_test)

  function new(string name = "wr_control_sbtx_corner_cases_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    wr_control_sbtx_corner_cases_seq cr_seq;
    wr_control_sbtx_directed_seq        dir_seq;

    cr_seq  = wr_control_sbtx_corner_cases_seq::type_id::create("cr_seq");
    dir_seq = wr_control_sbtx_directed_seq::type_id::create("dir_seq");

    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Running TC_08: wr_control_sbtx_corner_cases_test", UVM_LOW)
    dir_seq.start(env.agt.seqr);
    cr_seq.start(env.agt.seqr);
    phase.drop_objection(this);
  endtask
endclass

`endif // WR_CONTROL_SBTX_CORNER_CASES_TEST_SVH

