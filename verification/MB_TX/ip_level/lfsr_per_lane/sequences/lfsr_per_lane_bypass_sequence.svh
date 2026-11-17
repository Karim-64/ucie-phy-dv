`ifndef LFSR_PER_LANE_BYPASS_SEQUENCE_SVH
`define LFSR_PER_LANE_BYPASS_SEQUENCE_SVH

class lfsr_per_lane_bypass_sequence extends uvm_sequence #(lfsr_per_lane_sequence_item);
  `uvm_object_utils(lfsr_per_lane_bypass_sequence)
  `uvm_declare_p_sequencer(lfsr_per_lane_sequencer)

  lfsr_per_lane_sequence_item req;

  function new(string name = "lfsr_per_lane_bypass_sequence");
    super.new(name);
  endfunction

  task body();
    for (int i = 0; i < 64; i++) begin
      req = lfsr_per_lane_sequence_item::type_id::create($sformatf("req_%0d", i));
      start_item(req);
      assert (req.randomize()with {Data_In == 'b0;}) 
      else 
        `uvm_fatal("RANDOMIZE_FAIL", "Failed to randomize lfsr_per_lane_sequence_item")
      req.Opcode_Synch = 5'h15;
      req.EN = 1'b0;
      req.PN_EN = 1'b0;
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
    for (int i = 0; i < 64; i++) begin
      req = lfsr_per_lane_sequence_item::type_id::create($sformatf("req_%0d", i));
      start_item(req);
      assert (req.randomize()with {Data_In == 'b1;}) 
      else 
        `uvm_fatal("RANDOMIZE_FAIL", "Failed to randomize lfsr_per_lane_sequence_item")
      req.Opcode_Synch = 5'h15;
      req.EN = 1'b0;
      req.PN_EN = 1'b0;
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
    for (int i = 0; i < 64; i++) begin
      req = lfsr_per_lane_sequence_item::type_id::create($sformatf("req_%0d", i));
      start_item(req);
      assert (req.randomize()with {Data_In == local::i[0];}) 
      else 
        `uvm_fatal("RANDOMIZE_FAIL", "Failed to randomize lfsr_per_lane_sequence_item")
      req.Opcode_Synch = 5'h15;
      req.EN = 1'b0;
      req.PN_EN = 1'b0;
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
    for (int i = 0; i < 64; i++) begin
      req = lfsr_per_lane_sequence_item::type_id::create($sformatf("req_%0d", i));
      start_item(req);
      assert (req.randomize()) 
      else 
        `uvm_fatal("RANDOMIZE_FAIL", "Failed to randomize lfsr_per_lane_sequence_item")
      req.Opcode_Synch = 5'h15;
      req.EN = 1'b0;
      req.PN_EN = 1'b0;
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
  endtask
endclass

`endif // LFSR_PER_LANE_BYPASS_SEQUENCE_SVH
