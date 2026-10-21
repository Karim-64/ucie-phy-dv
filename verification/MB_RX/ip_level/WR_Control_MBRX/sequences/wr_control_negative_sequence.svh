`ifndef WR_CONTROL_NEGATIVE_SEQUENCE_SVH
`define WR_CONTROL_NEGATIVE_SEQUENCE_SVH

class wr_control_negative_sequence extends uvm_sequence #(wr_control_sequence_item);
  `uvm_object_utils(wr_control_negative_sequence)
  `uvm_declare_p_sequencer(wr_control_sequencer)

  function new(string name = "wr_control_negative_sequence");
    super.new(name);
  endfunction

  task body();
    wr_control_sequence_item req;
    `uvm_info(get_type_name(), "Starting Negative & Corner-Case Sequence", UVM_LOW)

    // Test 1: Disabled Gating (EN=0 or Deser_Done=0)
    repeat (10) begin
      req = wr_control_sequence_item::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
        R_RST_n       == 1'b1;
        (EN == 0 || Deser_Done == 0);
        Width_Degrade inside {3'b001, 3'b010, 3'b011};
      }) `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // Test 2: Unmapped / Illegal Width_Degrade Codes (000, 100, 101, 110, 111)
    repeat (15) begin
      req = wr_control_sequence_item::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
        R_RST_n       == 1'b1;
        EN            == 1'b1;
        Deser_Done    == 1'b1;
        Width_Degrade inside {3'b000, 3'b100, 3'b101, 3'b110, 3'b111};
      }) `uvm_error("SEQ", "Randomization failed for illegal width degrade")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    `uvm_info(get_type_name(), "Negative & Corner-Case Sequence Complete", UVM_LOW)
  endtask
endclass

`endif // WR_CONTROL_NEGATIVE_SEQUENCE_SVH