`ifndef WR_CONTROL_RESET_SEQUENCE_SVH
`define WR_CONTROL_RESET_SEQUENCE_SVH

class wr_control_reset_sequence extends uvm_sequence #(wr_control_sequence_item);
  `uvm_object_utils(wr_control_reset_sequence)
  `uvm_declare_p_sequencer(wr_control_sequencer)
  function new(string name = "wr_control_reset_sequence");
    super.new(name);
  endfunction

  task body();
    wr_control_sequence_item req;
    `uvm_info(get_type_name(), "Testing Mode: reset", UVM_LOW)
    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b0;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b011;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b0;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b011;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
  endtask
endclass

`endif // WR_CONTROL_reset_SEQUENCE_SVH