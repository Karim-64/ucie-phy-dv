`ifndef PAT_GEN_RST_SEQ_SVH
`define PAT_GEN_RST_SEQ_SVH

class pat_gen_rst_seq extends uvm_sequence #(pat_gen_sbtx_sequence_item);
  `uvm_object_utils(pat_gen_rst_seq)
  `uvm_declare_p_sequencer(pat_gen_sbtx_sequencer)

  function new(string name = "pat_gen_rst_seq");
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

  task body();
    // Assert reset at startup, then exercise reset transitions while enabled.
    repeat (2) drive_cycle(1'b0, 1'b0);
    drive_cycle(1'b1, 1'b1);
    drive_cycle(1'b0, 1'b1);
    drive_cycle(1'b1, 1'b1);

    // Cover reset-active with enable turn-on, turn-off, and enabled states.
    drive_cycle(1'b1, 1'b0);
    drive_cycle(1'b0, 1'b1);
    drive_cycle(1'b0, 1'b1);
    drive_cycle(1'b0, 1'b0);
    drive_cycle(1'b1, 1'b1);

    // Cover reset assert/deassert with enable turn-on, turn-off, and enabled states.
    drive_cycle(1'b1, 1'b0);
    drive_cycle(1'b0, 1'b0);
    drive_cycle(1'b1, 1'b1);
    drive_cycle(1'b1, 1'b1);
    drive_cycle(1'b0, 1'b1);
    drive_cycle(1'b1, 1'b0);

    // Inject an asynchronous reset glitch during active generation.
    drive_async_reset(250ps, 500ps);
    drive_cycle(1'b1, 1'b1);
  endtask
endclass

`endif // PAT_GEN_RST_SEQ_SVH