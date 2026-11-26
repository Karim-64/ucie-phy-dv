`ifndef WR_CONTROL_SBTX_COMP_TEST_SVH
`define WR_CONTROL_SBTX_COMP_TEST_SVH

// TC_04: Completion Handling Constrained-Random Test
class wr_control_sbtx_comp_test extends wr_control_sbtx_base_test;
  `uvm_component_utils(wr_control_sbtx_comp_test)

  function new(string name = "wr_control_sbtx_comp_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    wr_control_sbtx_comp_seq seq;
    seq = wr_control_sbtx_comp_seq::type_id::create("seq");

    phase.raise_objection(this);
    `uvm_info(get_type_name(), "Running TC_04: wr_control_sbtx_comp_test", UVM_LOW)
    seq.start(env.agt.seqr);
    phase.drop_objection(this);
  endtask
endclass

`endif // WR_CONTROL_SBTX_COMP_TEST_SVH

