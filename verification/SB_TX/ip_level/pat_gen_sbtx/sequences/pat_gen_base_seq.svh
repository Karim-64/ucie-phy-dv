`ifndef PAT_GEN_BASE_SEQ_SVH
`define PAT_GEN_BASE_SEQ_SVH

class pat_gen_base_seq extends uvm_sequence #(pat_gen_sbtx_sequence_item);
  `uvm_object_utils(pat_gen_base_seq)
  `uvm_declare_p_sequencer(pat_gen_sbtx_sequencer)

  function new(string name = "pat_gen_base_seq");
    super.new(name);
  endfunction

  task drive_cycle(logic reset_n, logic enable);
    pat_gen_sbtx_sequence_item req;
    req = pat_gen_sbtx_sequence_item::type_id::create("req");
    start_item(req);
    req.RST_n = reset_n;
    req.Patt_Gen_En = enable;
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
  endtask

  task drive_burst(int unsigned cycles);
    repeat (cycles) drive_cycle(1'b1, 1'b1);
    drive_cycle(1'b1, 1'b0);
    drive_cycle(1'b1, 1'b0);
  endtask

  task body();
    // Test A and B: first active bit is one, followed by 64 alternating bits.
    drive_cycle(1'b1, 1'b0);
    drive_burst(64);

    // Directed enable boundaries with idle and active output states.
    drive_cycle(1'b1, 1'b0);
    drive_cycle(1'b1, 1'b1);
    drive_cycle(1'b1, 1'b1);
    drive_cycle(1'b1, 1'b0);
    drive_cycle(1'b1, 1'b0);
    drive_cycle(1'b1, 1'b1);
    drive_cycle(1'b1, 1'b1);
    drive_cycle(1'b1, 1'b0);

    // Test C: terminate after even and odd burst lengths.
    drive_cycle(1'b1, 1'b0);
    drive_burst(64);
    drive_cycle(1'b1, 1'b0);
    drive_burst(33);
  endtask
endclass

`endif // PAT_GEN_BASE_SEQ_SVH