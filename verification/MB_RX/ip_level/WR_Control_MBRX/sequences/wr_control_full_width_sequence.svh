`ifndef WR_CONTROL_FULL_WIDTH_SEQUENCE_SVH
`define WR_CONTROL_FULL_WIDTH_SEQUENCE_SVH

class wr_control_full_width_sequence extends uvm_sequence #(wr_control_sequence_item);
  `uvm_object_utils(wr_control_full_width_sequence)
  `uvm_declare_p_sequencer(wr_control_sequencer)

  int burst_length = 50;

  function new(string name = "wr_control_full_width_sequence");
    super.new(name);
  endfunction

  task body();
    wr_control_sequence_item req;
    `uvm_info(get_type_name(), $sformatf("Starting Full Width Stress Sequence (Burst Length: %0d)", burst_length), UVM_LOW)

    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    if (!req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b011;
      Width_Degrade_Update == 1'b1;
    }) `uvm_error("SEQ", "Randomization failed for Full Width item")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    repeat (burst_length) begin
      req = wr_control_sequence_item::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
        R_RST_n       == 1'b1;
        EN            == 1'b1;
        Deser_Done    == 1'b1;
        Width_Degrade == 3'b011;
        Width_Degrade_Update == 1'b0;
      }) `uvm_error("SEQ", "Randomization failed for Full Width item")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    `uvm_info(get_type_name(), "Full Width Stress Sequence Complete", UVM_LOW)
  endtask
endclass

`endif // WR_CONTROL_FULL_WIDTH_SEQUENCE_SVH