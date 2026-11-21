`ifndef WR_CONTROL_BASE_SEQUENCE_SVH
`define WR_CONTROL_BASE_SEQUENCE_SVH

class wr_control_base_sequence extends uvm_sequence #(wr_control_sequence_item);
  `uvm_object_utils(wr_control_base_sequence)
  `uvm_declare_p_sequencer(wr_control_sequencer)
  function new(string name = "wr_control_base_sequence");
    super.new(name);
  endfunction

  task body();
    wr_control_sequence_item req;
    `uvm_info(get_type_name(), "Starting WR_Control Base Sequence", UVM_LOW)

    // =========================================================================
    // TEST 1: Full Width Mode (011) -> Requires 1 cycle to assert WR_EN
    // =========================================================================
    `uvm_info(get_type_name(), "Testing Mode: Full Width (011)", UVM_LOW)
    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b011;
      Width_Degrade_Update == 1'b1;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b011;
      Width_Degrade_Update == 1'b0;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
    

    // Idle / Pipeline flush cycle
    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with { 
      R_RST_n       == 1'b1; 
      EN            == 1'b0; 
      Deser_Done    == 1'b1; 
      Width_Degrade == 3'b011;
      Width_Degrade_Update == 1'b0;
    })
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    // =========================================================================
    // TEST 2: Degrade Lower Mode (001) -> Requires 2 cycles to assert WR_EN
    // =========================================================================
    `uvm_info(get_type_name(), "Testing Mode: Degrade Lower (001)", UVM_LOW)
    
    // Cycle 1: Caches the lower 64 bits (WR_EN should remain 0)
    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b001;
      Width_Degrade_Update == 1'b1;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b001;
      Width_Degrade_Update == 1'b0;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);


    // Cycle 2: Fetches the next lower 64 bits and pushes full 128 bits (WR_EN = 1)
    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b001;
      Width_Degrade_Update == 1'b0;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
    


    // Idle / Pipeline flush cycle
    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with { 
      R_RST_n       == 1'b1; 
      EN            == 1'b0; 
      Deser_Done    == 1'b0; 
      Width_Degrade == 3'b001;
      Width_Degrade_Update == 1'b0;
    })
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    // =========================================================================
    // TEST 3: Degrade Upper Mode (010) -> Requires 2 cycles to assert WR_EN
    // =========================================================================
    `uvm_info(get_type_name(), "Testing Mode: Degrade Upper (010)", UVM_LOW)
    
    // Cycle 1: Caches the upper 64 bits (WR_EN should remain 0)
    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b010;
      Width_Degrade_Update == 1'b1;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    // Cycle 2: Fetches the next upper 64 bits and pushes full 128 bits (WR_EN = 1)
    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b010;
      Width_Degrade_Update == 1'b0;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b010;
      Width_Degrade_Update == 1'b0;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    // =========================================================================
    // TEST 4 (NEW): Width_Degrade_Update flushes a half-captured degraded word
    // =========================================================================
    `uvm_info(get_type_name(), "Testing Mode: Width_Degrade_Update", UVM_LOW)

    //Cycle 1: Frame 1 cached
    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b010;
      Width_Degrade_Update == 1'b0;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);


    //Cycle 2: update -> flush, now lower x8 
    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b001;
      Width_Degrade_Update == 1'b1;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b001;
      Width_Degrade_Update == 1'b0;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b001;
      Width_Degrade_Update == 1'b0;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    // =========================================================================
    // TEST 5 (NEW): update after a stall between Frame 1 and Frame 2
    // =========================================================================
    `uvm_info(get_type_name(), "Testing Mode: Width_Degrade_Update after stall", UVM_LOW)

    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b010;
      Width_Degrade_Update == 1'b1;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b010;
      Width_Degrade_Update == 1'b0;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b0;
      Deser_Done    == 1'b0;
      Width_Degrade == 3'b010;
      Width_Degrade_Update == 1'b0;
    })
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b011;
      Width_Degrade_Update == 1'b1;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b011;
      Width_Degrade_Update == 1'b0;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    // =========================================================================
    // TEST 6 (NEW): update to the same width degrade
    // =========================================================================
    `uvm_info(get_type_name(), "Testing Mode: Width_Degrade_Update with the same Width_Degrade", UVM_LOW)

    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b011;
      Width_Degrade_Update == 1'b1;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b011;
      Width_Degrade_Update == 1'b0;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b011;
      Width_Degrade_Update == 1'b0;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    // =========================================================================
    // TEST 7 (NEW): reset while update width degrade
    // =========================================================================
    `uvm_info(get_type_name(), "Testing Mode:Reset With Width_Degrade_Update", UVM_LOW)

    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b0;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b001;
      Width_Degrade_Update == 1'b1;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b001;
      Width_Degrade_Update == 1'b0;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = wr_control_sequence_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {
      R_RST_n       == 1'b1;
      EN            == 1'b1;
      Deser_Done    == 1'b1;
      Width_Degrade == 3'b001;
      Width_Degrade_Update == 1'b0;
    }) 
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    `uvm_info(get_type_name(), "WR_Control Base Sequence Complete", UVM_LOW)
  endtask
endclass

`endif // WR_CONTROL_BASE_SEQUENCE_SVH