`ifndef WR_CONTROL_RANDOM_SEQUENCE_SVH
`define WR_CONTROL_RANDOM_SEQUENCE_SVH

class wr_control_random_sequence extends uvm_sequence #(wr_control_sequence_item);
  `uvm_object_utils(wr_control_random_sequence)
  `uvm_declare_p_sequencer(wr_control_sequencer)

  int num_transactions = 200;

  function new(string name = "wr_control_random_sequence");
    super.new(name);
  endfunction

  task body();
    wr_control_sequence_item req;
    `uvm_info(get_type_name(), "Starting Random Sequence", UVM_LOW)

    repeat(num_transactions) begin
      req = wr_control_sequence_item::type_id::create("req");
      start_item(req);
      req.wd_change_c.constraint_mode(1);    // on for this item only
      req.normal_wd_flow_c.constraint_mode(0);
      assert(req.randomize()) else `uvm_error("SEQ", "Randomization failed for Frame 1")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    `uvm_info(get_type_name(), "Random Sequence Complete", UVM_LOW)
  endtask
endclass

`endif // WR_CONTROL_RANDOM_SEQUENCE_SVH