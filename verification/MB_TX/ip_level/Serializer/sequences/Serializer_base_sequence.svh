class Serializer_reset_sequence extends uvm_sequence #(Serializer_sequence_item);
  `uvm_object_utils(Serializer_reset_sequence)
  `uvm_declare_p_sequencer(Serializer_sequencer)

  Serializer_sequence_item seq_item;

  function new(string name = "Serializer_reset_sequence");
    super.new(name);
  endfunction

  task body();

     seq_item = Serializer_sequence_item::type_id::create("seq_item");
     seq_item.constraint_mode(0);
     repeat(5)begin
      start_item(seq_item);
        if (!seq_item.randomize() with {seq_item.SER_EN ==0; seq_item.DATA ==0;}) `uvm_error("SEQ", "Randomization failed")
      finish_item(seq_item);
      p_sequencer.seqr_aport.write(seq_item);
     end

  endtask
endclass

class Serializer_directed_sequence extends uvm_sequence #(Serializer_sequence_item);
  `uvm_object_utils(Serializer_directed_sequence)
  `uvm_declare_p_sequencer(Serializer_sequencer)

  Serializer_sequence_item seq_item;

  function new(string name = "Serializer_directed_sequence");
    super.new(name);
  endfunction

  task body();

    seq_item = Serializer_sequence_item::type_id::create("seq_item");
    seq_item.active_c.constraint_mode(1);
    // the loop ends when the counter and i reache 8
    // try data = 8'b0000_0000
    for(int i=0;i<9;i++)begin
     start_item(seq_item);
       seq_item.counter = i; 
       if (!seq_item.randomize() with {seq_item.DATA ==8'b0000_0000;}) `uvm_error("SEQ", "Randomization failed")
     finish_item(seq_item);
     p_sequencer.seqr_aport.write(seq_item);
    end
  
    // the loop ends when the counter and i reache 8
    // try data = 8'b1111_1111
    for(int i=0;i<9;i++)begin
     start_item(seq_item);
       seq_item.counter = i; 
       if (!seq_item.randomize() with {seq_item.DATA ==8'b1111_1111;}) `uvm_error("SEQ", "Randomization failed")
     finish_item(seq_item);
     p_sequencer.seqr_aport.write(seq_item);
    end
    
    // the loop ends when the counter and i reache 8
    // try data = 8'b0101_0101
    for(int i=0;i<9;i++)begin
     start_item(seq_item);
       seq_item.counter = i; 
       if (!seq_item.randomize() with {seq_item.DATA ==8'b0101_0101;}) `uvm_error("SEQ", "Randomization failed")
     finish_item(seq_item);
     p_sequencer.seqr_aport.write(seq_item);
    end
    // the loop ends when the counter and i reache 8
    // try data = 8'b1010_1010
    for(int i=0;i<9;i++)begin
     start_item(seq_item);
       seq_item.counter = i; 
       if (!seq_item.randomize() with {seq_item.DATA ==8'b1010_1010;}) `uvm_error("SEQ", "Randomization failed")
     finish_item(seq_item);
     p_sequencer.seqr_aport.write(seq_item);
    end
    // the loop ends when the counter and i reache 8
    // try data = 8'b0000_1111
    for(int i=0;i<9;i++)begin
     start_item(seq_item);
       seq_item.counter = i; 
       if (!seq_item.randomize() with {seq_item.DATA ==8'b0000_1111;}) `uvm_error("SEQ", "Randomization failed")
     finish_item(seq_item);
     p_sequencer.seqr_aport.write(seq_item);
    end
    // the loop ends when the counter and i reache 8
    // try data = 8'b1111_0000
    for(int i=0;i<9;i++)begin
     start_item(seq_item);
       seq_item.counter = i; 
       if (!seq_item.randomize() with {seq_item.DATA ==8'b1111_0000;}) `uvm_error("SEQ", "Randomization failed")
     finish_item(seq_item);
     p_sequencer.seqr_aport.write(seq_item);
    end
  endtask
endclass


class Serializer_random_sequence extends uvm_sequence #(Serializer_sequence_item);
  `uvm_object_utils(Serializer_random_sequence)
  `uvm_declare_p_sequencer(Serializer_sequencer)

  Serializer_sequence_item seq_item;

  function new(string name = "Serializer_random_sequence");
    super.new(name);
  endfunction

  task body();

    seq_item = Serializer_sequence_item::type_id::create("seq_item");
    seq_item.active_c.constraint_mode(1);
    seq_item.DATA.rand_mode(0); // force data to remain stable throughout an active transfer.
    // the loop ends when the counter and i reache 8
    repeat(1000)begin
      seq_item.DATA = seq_item.ranomized_data;
      for(int i=0;i<9;i++)begin
        start_item(seq_item);
          seq_item.counter = i; 
          if (!seq_item.randomize()) `uvm_error("SEQ", "Randomization failed")
        finish_item(seq_item);
        p_sequencer.seqr_aport.write(seq_item);
      end
    end
    // Change DATA while SER_EN is high to verify that the captured data remains stable during serialization
    seq_item.DATA.rand_mode(1); // enable data randomization 
    repeat(1000)begin
      for(int i=0;i<9;i++)begin
        start_item(seq_item);
          seq_item.counter = i; 
          if (!seq_item.randomize()) `uvm_error("SEQ", "Randomization failed")
        finish_item(seq_item);
        p_sequencer.seqr_aport.write(seq_item);
      end
    end

  endtask
endclass

class Serializer_disabled_sequence extends uvm_sequence #(Serializer_sequence_item);
  `uvm_object_utils(Serializer_disabled_sequence)
  `uvm_declare_p_sequencer(Serializer_sequencer)

  Serializer_sequence_item seq_item;

  function new(string name = "Serializer_disabled_sequence");
    super.new(name);
  endfunction

  task body();

    seq_item = Serializer_sequence_item::type_id::create("seq_item");
    // try to serialize data when ser_enable is disabled
    seq_item.constraint_mode(0);
    repeat(100)begin
      for(int i=0;i<9;i++)begin
        start_item(seq_item);
          seq_item.counter = i; 
          if (!seq_item.randomize() with {seq_item.SER_EN == 0;}) `uvm_error("SEQ", "Randomization failed")
        finish_item(seq_item);
        p_sequencer.seqr_aport.write(seq_item);
      end
    end
  endtask
endclass

