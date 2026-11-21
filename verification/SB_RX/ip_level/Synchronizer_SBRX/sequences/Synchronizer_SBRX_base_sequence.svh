class Synchronizer_SBRX_reset_sequence extends uvm_sequence #(Synchronizer_SBRX_sequence_item);
  `uvm_object_utils(Synchronizer_SBRX_reset_sequence)
  `uvm_declare_p_sequencer(Synchronizer_SBRX_sequencer)

  Synchronizer_SBRX_sequence_item seq_item;

  function new(string name = "Synchronizer_SBRX_reset_sequence");
    super.new(name);
  endfunction

  task body();
    seq_item = Synchronizer_SBRX_sequence_item::type_id::create("seq_item");
      // enable rst constraint only
      seq_item.constraint_mode(0);
      seq_item.rst_n_c.constraint_mode(1);
      repeat(10)begin
        start_item(seq_item);
        if (!seq_item.randomize()) `uvm_error("Synchronizer_SBRX_reset_sequence", "Randomization failed")
        finish_item(seq_item);
        p_sequencer.seqr_aport.write(seq_item);
      end

  endtask
endclass

class Synchronizer_SBRX_stream_0_sequence extends uvm_sequence #(Synchronizer_SBRX_sequence_item);
  `uvm_object_utils(Synchronizer_SBRX_stream_0_sequence)
  `uvm_declare_p_sequencer(Synchronizer_SBRX_sequencer)

  Synchronizer_SBRX_sequence_item seq_item;

  function new(string name = "Synchronizer_SBRX_stream_0_sequence");
    super.new(name);
  endfunction

  task body();
    seq_item = Synchronizer_SBRX_sequence_item::type_id::create("seq_item");
    // enable stream_0_c constraint only
    seq_item.constraint_mode(0);
    seq_item.stream_0_c.constraint_mode(1);
      repeat(100)begin
        start_item(seq_item);
        if (!seq_item.randomize()) `uvm_error("Synchronizer_SBRX_stream_0_sequence", "Randomization failed")
        finish_item(seq_item);
        p_sequencer.seqr_aport.write(seq_item);
      end

  endtask
endclass

class Synchronizer_SBRX_stream_1_sequence extends uvm_sequence #(Synchronizer_SBRX_sequence_item);
  `uvm_object_utils(Synchronizer_SBRX_stream_1_sequence)
  `uvm_declare_p_sequencer(Synchronizer_SBRX_sequencer)

  Synchronizer_SBRX_sequence_item seq_item;

  function new(string name = "Synchronizer_SBRX_stream_1_sequence");
    super.new(name);
  endfunction

  task body();
    seq_item = Synchronizer_SBRX_sequence_item::type_id::create("seq_item");
    // enable stream_1_c constraint only
    seq_item.constraint_mode(0);
    seq_item.stream_1_c.constraint_mode(1);
      repeat(100)begin
        start_item(seq_item);
        if (!seq_item.randomize()) `uvm_error("Synchronizer_SBRX_stream_1_sequence", "Randomization failed")
        finish_item(seq_item);
        p_sequencer.seqr_aport.write(seq_item);
      end

  endtask
endclass


class Synchronizer_SBRX_toggle_sequence extends uvm_sequence #(Synchronizer_SBRX_sequence_item);
  `uvm_object_utils(Synchronizer_SBRX_toggle_sequence)
  `uvm_declare_p_sequencer(Synchronizer_SBRX_sequencer)

  Synchronizer_SBRX_sequence_item seq_item;

  function new(string name = "Synchronizer_SBRX_toggle_sequence");
    super.new(name);
  endfunction

  task body();
    seq_item = Synchronizer_SBRX_sequence_item::type_id::create("seq_item");
    // enable toggle constraint only
    seq_item.constraint_mode(0);
    seq_item.toggle_c.constraint_mode(1);
      repeat(100)begin
        start_item(seq_item);
        if (!seq_item.randomize()) `uvm_error("Synchronizer_SBRX_toggle_sequence", "Randomization failed")
        finish_item(seq_item);
        p_sequencer.seqr_aport.write(seq_item);
      end

  endtask
endclass


class Synchronizer_SBRX_random_sequence extends uvm_sequence #(Synchronizer_SBRX_sequence_item);
  `uvm_object_utils(Synchronizer_SBRX_random_sequence)
  `uvm_declare_p_sequencer(Synchronizer_SBRX_sequencer)

  Synchronizer_SBRX_sequence_item seq_item;

  function new(string name = "Synchronizer_SBRX_random_sequence");
    super.new(name);
  endfunction

  task body();
    seq_item = Synchronizer_SBRX_sequence_item::type_id::create("seq_item");
    // enable random constraint only
    seq_item.constraint_mode(0);
    seq_item.random_c.constraint_mode(1);
      repeat(100)begin
        start_item(seq_item);
        if (!seq_item.randomize()) `uvm_error("Synchronizer_SBRX_random_sequence", "Randomization failed")
        finish_item(seq_item);
        p_sequencer.seqr_aport.write(seq_item);
      end

  endtask
endclass


