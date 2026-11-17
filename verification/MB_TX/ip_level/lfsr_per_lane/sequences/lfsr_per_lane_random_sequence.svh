`ifndef LFSR_PER_LANE_RANDOM_SEQUENCE_SVH
`define LFSR_PER_LANE_RANDOM_SEQUENCE_SVH

class lfsr_per_lane_random_sequence extends uvm_sequence #(lfsr_per_lane_sequence_item);
  `uvm_object_utils(lfsr_per_lane_random_sequence)
  `uvm_declare_p_sequencer(lfsr_per_lane_sequencer)

  lfsr_per_lane_sequence_item req;

  function new(string name = "lfsr_per_lane_random_sequence");
    super.new(name);
  endfunction

  task body();
    for (int i = 0; i < 256; i++) begin
      req = lfsr_per_lane_sequence_item::type_id::create($sformatf("rand_req_%0d", i));
      start_item(req);

      assert (req.randomize() with {
        RST_n dist {0 := 10, 1 := 90};
        Opcode_Synch dist {5'h00 := 10, 5'h15 := 50, 5'h1A := 20, 5'h1F := 20};
        EN dist {0 := 35, 1 := 65};
        PN_EN dist {0 := 65, 1 := 35};
        Data_In dist {0 := 50, 1 := 50};
      }) else
        `uvm_fatal("RAND_SEQ", "Failed to randomize lfsr_per_lane_sequence_item")

      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
  endtask
endclass

`endif // LFSR_PER_LANE_RANDOM_SEQUENCE_SVH
