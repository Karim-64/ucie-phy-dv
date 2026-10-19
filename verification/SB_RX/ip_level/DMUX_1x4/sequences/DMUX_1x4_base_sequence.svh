`ifndef DMUX_1X4_BASE_SEQUENCE_SVH
`define DMUX_1X4_BASE_SEQUENCE_SVH

class DMUX_1x4_base_sequence extends uvm_sequence #(DMUX_1x4_sequence_item);
  `uvm_object_utils(DMUX_1x4_base_sequence)
  `uvm_declare_p_sequencer(DMUX_1x4_sequencer)

  function new(string name = "DMUX_1x4_base_sequence");
    super.new(name);
  endfunction

  task body();
    // -------------------------------------------------------------------------
    // 1. Normal Random Stimulus
    // -------------------------------------------------------------------------
    for (int i = 0; i < 2000; i++) begin
      req = DMUX_1x4_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.normal.constraint_mode(1);
      if (!req.randomize())
        `uvm_error("SEQ", "Randomization failed for normal constraint");
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // -------------------------------------------------------------------------
    // 2. Consecutive Zeros Pattern
    // -------------------------------------------------------------------------
    for (int i = 0; i < 100; i++) begin
      req = DMUX_1x4_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.consecutive_zeros.constraint_mode(1);
      if (!req.randomize())
        `uvm_error("SEQ", "Randomization failed for consecutive_zeros constraint");
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // -------------------------------------------------------------------------
    // 3. Consecutive Ones Pattern
    // -------------------------------------------------------------------------
    for (int i = 0; i < 100; i++) begin
      req = DMUX_1x4_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.consecutive_ones.constraint_mode(1);
      if (!req.randomize())
        `uvm_error("SEQ", "Randomization failed for consecutive_ones constraint");
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // -------------------------------------------------------------------------
    // 4. Toggle Patterns
    // -------------------------------------------------------------------------
    for (int i = 0; i < 100; i++) begin
      req = DMUX_1x4_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.toogles.constraint_mode(1);
      if (!req.randomize())
        `uvm_error("SEQ", "Randomization failed for toogles constraint");
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // -------------------------------------------------------------------------
    // 5. Walking One Pattern
    // -------------------------------------------------------------------------
    for (int i = 0; i < 200; i++) begin
      req = DMUX_1x4_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.walking_one.constraint_mode(1);
      if (!req.randomize())
        `uvm_error("SEQ", "Randomization failed for walking_one constraint");
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // -------------------------------------------------------------------------
    // 6. Walking Zeros Pattern
    // -------------------------------------------------------------------------
    for (int i = 0; i < 100; i++) begin
      req = DMUX_1x4_sequence_item::type_id::create("req");
      start_item(req);
      req.constraint_mode(0);
      req.walking_zeros.constraint_mode(1);
      if (!req.randomize())
        `uvm_error("SEQ", "Randomization failed for walking_zeros constraint");
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end

    // -------------------------------------------------------------------------
    // 7. Dynamic Channel Switching 
    // -------------------------------------------------------------------------
    for (int rep = 0; rep < 4; rep++) begin
      for (int ch = 0; ch < 4; ch++) begin
        req = DMUX_1x4_sequence_item::type_id::create("req");
        start_item(req);
        req.constraint_mode(0);
        if (!req.randomize() with { sel == ch; })
          `uvm_error("SEQ", $sformatf("Randomization failed for dynamic switching sel=%0d", ch));
        finish_item(req);
        p_sequencer.seqr_aport.write(req);
      end
    end
  endtask
endclass

`endif // DMUX_1X4_BASE_SEQUENCE_SVH
