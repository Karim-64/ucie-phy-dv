`ifndef WR_CONTROL_DEGRADED_LOWER_SEQUENCE_SVH
`define WR_CONTROL_DEGRADED_LOWER_SEQUENCE_SVH

class wr_control_degraded_lower_sequence extends uvm_sequence #(wr_control_sequence_item);
  `uvm_object_utils(wr_control_degraded_lower_sequence)
  `uvm_declare_p_sequencer(wr_control_sequencer)

  int num_transactions = 20;

  function new(string name = "wr_control_degraded_lower_sequence");
    super.new(name);
  endfunction

  task body();
    wr_control_sequence_item req;
    `uvm_info(get_type_name(), "Starting Degraded Lower Mode Sequence (3'b001)", UVM_LOW)

    repeat (num_transactions) begin
      // Frame 1: Caches lower 64 bits (WR_EN should remain 0)
      req = wr_control_sequence_item::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        R_RST_n       == 1'b1;
        EN            == 1'b1;
        Deser_Done    == 1'b1;
        Width_Degrade == 3'b001;
      }) else `uvm_error("SEQ", "Randomization failed for Frame 1")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);

      // Optional randomized stall cycle between Frame 1 and Frame 2
      if ($urandom_range(0, 1)) begin
        req = wr_control_sequence_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
          R_RST_n       == 1'b1;
          EN            == 0;
          Deser_Done    == 0;
          Width_Degrade == 3'b001;
        }) else `uvm_error("SEQ", "Randomization failed for stall cycle")
        finish_item(req);
        p_sequencer.seqr_aport.write(req);
      end

      // Frame 2: Completes 128-bit word assembly (WR_EN asserts 1)
      req = wr_control_sequence_item::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {
        R_RST_n       == 1'b1;
        EN            == 1'b1;
        Deser_Done    == 1'b1;
        Width_Degrade == 3'b001;
      }) else `uvm_error("SEQ", "Randomization failed for Frame 2")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    `uvm_info(get_type_name(), "Degraded Lower Mode Sequence Complete", UVM_LOW)
  endtask
endclass

`endif // WR_CONTROL_DEGRADED_LOWER_SEQUENCE_SVH