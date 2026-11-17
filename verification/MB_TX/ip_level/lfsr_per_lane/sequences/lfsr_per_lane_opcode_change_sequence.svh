`ifndef LFSR_PER_LANE_OPCODE_CHANGE_SEQUENCE_SVH
`define LFSR_PER_LANE_OPCODE_CHANGE_SEQUENCE_SVH

class lfsr_per_lane_opcode_change_sequence extends uvm_sequence #(lfsr_per_lane_sequence_item);
  `uvm_object_utils(lfsr_per_lane_opcode_change_sequence)
  `uvm_declare_p_sequencer(lfsr_per_lane_sequencer)

  lfsr_per_lane_sequence_item req;

  function new(string name = "lfsr_per_lane_opcode_change_sequence");
    super.new(name);
  endfunction

  task body();
    for (int mode = 0; mode < 4; mode++) begin
      for (int opcode = 0; opcode < 64; opcode++) begin
        for (int cycle = 0; cycle < 8; cycle++) begin
          req = lfsr_per_lane_sequence_item::type_id::create(
              $sformatf("req_mode_%0d_opcode_%0d_cycle_%0d", mode, opcode, cycle));
          start_item(req);
          assert (req.randomize() with {
            RST_n == 1'b1;
            Data_In == local::cycle[0];
          })
          else
            `uvm_fatal("RANDOMIZE_FAIL", "Failed to randomize lfsr_per_lane_sequence_item")
          req.Opcode_Synch = opcode[4:0];
          req.EN = mode[1];
          req.PN_EN = mode[0];
          finish_item(req);
          p_sequencer.seqr_aport.write(req);
        end
      end
    end
  endtask
endclass

`endif // LFSR_PER_LANE_OPCODE_CHANGE_SEQUENCE_SVH
