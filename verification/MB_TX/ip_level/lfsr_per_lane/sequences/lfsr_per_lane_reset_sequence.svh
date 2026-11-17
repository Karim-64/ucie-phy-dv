`ifndef LFSR_PER_LANE_RESET_SEQUENCE_SVH
`define LFSR_PER_LANE_RESET_SEQUENCE_SVH

class lfsr_per_lane_reset_sequence extends uvm_sequence #(lfsr_per_lane_sequence_item);
  `uvm_object_utils(lfsr_per_lane_reset_sequence)
  `uvm_declare_p_sequencer(lfsr_per_lane_sequencer)

  lfsr_per_lane_sequence_item req;

  function new(string name = "lfsr_per_lane_reset_sequence");
    super.new(name);
  endfunction

  task body();
    for (int i = 0; i < 2; i++) begin
      req = lfsr_per_lane_sequence_item::type_id::create($sformatf("reset_req_%0d", i));
      start_item(req);
      req.RST_n = 1'b0;
      req.Opcode_Synch = 5'h15;
      req.EN = 1'b0;
      req.PN_EN = 1'b0;
      req.Data_In = 1'b0;
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // for (int i = 0; i < 64; i++) begin
    //   req = lfsr_per_lane_sequence_item::type_id::create($sformatf("reset_req_%0d", i));
    //   start_item(req);
    //   req.RST_n = 1'b0;
    //   req.Opcode_Synch = 5'h15;
    //   req.EN = 1'b0;
    //   req.PN_EN = 1'b0;
    //   req.Data_In = i[0];
    //   finish_item(req);
    //   p_sequencer.seqr_aport.write(req);
    // end

    req = lfsr_per_lane_sequence_item::type_id::create("req");
    start_item(req);
    req.RST_n = 1'b1;
    req.Opcode_Synch = 5'h15;
    req.EN = 1'b0;
    req.PN_EN = 1'b0;
    req.Data_In = 'b0;
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
  endtask
endclass

`endif // LFSR_PER_LANE_RESET_SEQUENCE_SVH
