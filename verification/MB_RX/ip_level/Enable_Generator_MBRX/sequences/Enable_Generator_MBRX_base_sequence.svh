class Enable_Generator_MBRX_Reset_Sequence extends uvm_sequence #(Enable_Generator_MBRX_sequence_item);
  `uvm_object_utils(Enable_Generator_MBRX_Reset_Sequence)
  `uvm_declare_p_sequencer(Enable_Generator_MBRX_sequencer)

  Enable_Generator_MBRX_sequence_item seq_item;

  
  function new(string name = "Enable_Generator_MBRX_Reset_Sequence");
    super.new(name);
  endfunction

  task body();
    seq_item = Enable_Generator_MBRX_sequence_item::type_id::create("seq_item");
    seq_item.constraint_mode(0); // Disable all constraints by default.
    seq_item.reset_c.constraint_mode(1);  // Enable the reset constraint.
    repeat(20)begin
      start_item(seq_item); 
        if (!seq_item.randomize()) `uvm_error("RESET_SEQ", "Randomization failed")
      finish_item(seq_item);
      // Send the generated transaction to the scoreboard through monitor.
      p_sequencer.seqr_ap.write(seq_item);
    end
  endtask
endclass

// Sequence to verify setting and clearing of the Chunk_Marker.
class Enable_Generator_MBRX_Chunk_Marker_Sequence extends uvm_sequence #(Enable_Generator_MBRX_sequence_item);
  `uvm_object_utils(Enable_Generator_MBRX_Chunk_Marker_Sequence)
  `uvm_declare_p_sequencer(Enable_Generator_MBRX_sequencer)
  Enable_Generator_MBRX_sequence_item seq_item;


  function new(string name = "Enable_Generator_MBRX_Chunk_Marker_Sequence");
    super.new(name);
  endfunction

  task send_data(bit valid,bit frame_error,bit detec_succ,bit comparison_done,LTSM_states state);
    seq_item = Enable_Generator_MBRX_sequence_item::type_id::create("seq_item");
    seq_item.constraint_mode(0);
    start_item(seq_item);
    if (!seq_item.randomize() with {
      seq_item.RST_n == 1; 
      seq_item.Valid == valid;
      seq_item.Valid_Frame_Error == frame_error;
      seq_item.Detec_succ == detec_succ;
      seq_item.Comparison_Done == comparison_done;
      seq_item.LTSM_State == state;
      seq_item.Width_Degrade == 3'b011;
    })`uvm_error("CHUNK_MARKER_SEQ", "Randomization failed")
    finish_item(seq_item);
    // Send the generated transaction to the scoreboard through monitor.
    p_sequencer.seqr_ap.write(seq_item);
  endtask

  task body();

    // Apply normal valid framing: 4 ui high followed by 4 ui low.
    repeat(10)begin
      repeat (2) send_data(1, 0, 0, 0, _ACTIVE);
      repeat (2) send_data(0, 0, 0, 0, _ACTIVE);
    end

    // Assert a frame error during a high phase to test marker clearing.
    repeat(10)begin
      send_data(1, 0, 0, 0, _ACTIVE);
      //send_data(1, 1, 0, 0, _ACTIVE);
      repeat (1) send_data(1, 0, 0, 0, _ACTIVE);
      repeat (2) send_data(0, 0, 0, 0, _ACTIVE);
    end

    // Assert detection success during a high phase to test marker clearing.
    repeat(10)begin
      send_data(1, 0, 0, 0, _ACTIVE);
      send_data(1, 0, 1, 0, _ACTIVE);
      //repeat (2) send_data(1, 0, 0, 0, _ACTIVE);
      repeat (2) send_data(0, 0, 0, 0, _ACTIVE);
    end

    // Change the LTSM state while the marker to test state-change clearing.
    repeat (2) send_data(1, 0, 0, 0, _ACTIVE);
    repeat (2) send_data(0, 0, 0, 0, _PHYRETRAIN);

  endtask
endclass


class Enable_Generator_MBRX_Vchk_EN_Sequence extends uvm_sequence #(Enable_Generator_MBRX_sequence_item);
  `uvm_object_utils(Enable_Generator_MBRX_Vchk_EN_Sequence)
  `uvm_declare_p_sequencer(Enable_Generator_MBRX_sequencer)

  Enable_Generator_MBRX_sequence_item seq_item;

  LTSM_states all_states[] = '{
    _RESET,
    _SBINIT,
    _MBINIT_PARAM,
    _MBINIT_CAL,
    _MBINIT_REPAIRCLK,
    _MBINIT_REPAIRVAL,
    _MBINIT_REVERSALMB,
    _MBINIT_REPAIRMB,
    _MBTRAIN_VALVREF,
    _MBTRAIN_DATAVREF,
    _MBTRAIN_SPEEDIDLE,
    _MBTRAIN_TXSELFCAL,
    _MBTRAIN_RXCLKCAL,
    _MBTRAIN_VALTRAINCENTER,
    _MBTRAIN_DATATRAINCENTER1,
    _MBTRAIN_DATATRAINVREF,
    _MBTRAIN_RXDESKEW,
    _MBTRAIN_DATATRAINCENTER2,
    _MBTRAIN_LINKSPEED,
    _ACTIVE
};

  function new(string name = "Enable_Generator_MBRX_Vchk_EN_Sequence");
    super.new(name);
  endfunction

  task send_data(bit valid, bit test_resp,bit frame_error, bit detec_succ,bit comparison_done, LTSM_states state,logic [2:0] width_degrade);
    seq_item = Enable_Generator_MBRX_sequence_item::type_id::create("seq_item");
    seq_item.constraint_mode(0);
    start_item(seq_item);
    if (!seq_item.randomize() with {
      seq_item.RST_n             == 1;
      seq_item.Valid             == valid;
      seq_item.Test_Resp         == test_resp;
      seq_item.Valid_Frame_Error == frame_error;
      seq_item.Detec_succ        == detec_succ;
      seq_item.Comparison_Done   == comparison_done;
      seq_item.LTSM_State        == state;
      seq_item.Width_Degrade     == width_degrade;
    })`uvm_fatal("VCHK_SEQ", "Randomization failed")
    finish_item(seq_item);
    p_sequencer.seqr_ap.write(seq_item);
  endtask

  task body();
    send_data(0,0,0,0,0,_RESET,3'b011);

    // ACTIVE: valid rising edge.
    repeat(2) send_data(1,0,0,0,0,_ACTIVE,3'b011);
    repeat(2) send_data(0,0,0,0,0,_ACTIVE,3'b011);

    // Termination events.
    send_data(1,0,1,0,0,_ACTIVE,3'b011);
    send_data(1,0,0,1,0,_ACTIVE,3'b011);
    // try Inactive states
    for(int i=0;i<19;i++)begin 
      send_data(1,1,1,0,0,all_states[i],3'b011);
    end


  endtask
endclass



class Enable_Generator_MBRX_Data_Comparator_EN_Sequence extends uvm_sequence #(Enable_Generator_MBRX_sequence_item);
  `uvm_object_utils(Enable_Generator_MBRX_Data_Comparator_EN_Sequence)
  `uvm_declare_p_sequencer(Enable_Generator_MBRX_sequencer)

  Enable_Generator_MBRX_sequence_item seq_item;
    LTSM_states all_states[] = '{
    _RESET,
    _SBINIT,
    _MBINIT_PARAM,
    _MBINIT_CAL,
    _MBINIT_REPAIRCLK,
    _MBINIT_REPAIRVAL,
    _MBINIT_REVERSALMB,
    _MBINIT_REPAIRMB,
    _MBTRAIN_VALVREF,
    _MBTRAIN_DATAVREF,
    _MBTRAIN_SPEEDIDLE,
    _MBTRAIN_TXSELFCAL,
    _MBTRAIN_RXCLKCAL,
    _MBTRAIN_VALTRAINCENTER,
    _MBTRAIN_DATATRAINCENTER1,
    _MBTRAIN_DATATRAINVREF,
    _MBTRAIN_RXDESKEW,
    _MBTRAIN_DATATRAINCENTER2,
    _MBTRAIN_LINKSPEED,
    _ACTIVE
};

  function new(string name = "Enable_Generator_MBRX_Data_Comparator_EN_Sequence");
    super.new(name);
  endfunction

  task send_data(bit rst_n, bit valid, bit test_resp,bit frame_error, bit detec_succ,bit comparison_done, LTSM_states state,logic [2:0] width_degrade);
    seq_item = Enable_Generator_MBRX_sequence_item::type_id::create("seq_item");
    seq_item.constraint_mode(0);
    start_item(seq_item);
    if (!seq_item.randomize() with {
      seq_item.RST_n              == rst_n;
      seq_item.Valid              == valid;
      seq_item.Test_Resp          == test_resp;
      seq_item.Valid_Frame_Error  == frame_error;
      seq_item.Detec_succ         == detec_succ;
      seq_item.Comparison_Done    == comparison_done;
      seq_item.LTSM_State         == state;
      seq_item.Width_Degrade      == width_degrade;
    })
      `uvm_fatal("CMP_EN_SEQ", "Randomization failed")
    finish_item(seq_item);
    p_sequencer.seqr_ap.write(seq_item);
  endtask

  task body();
    send_data(0,0,0,0,0,0,_RESET,3'b011);

    send_data(1,1,0,0,0,0,_MBINIT_REVERSALMB,3'b011);

    // Test_Resp latch enables the comparator.
    send_data(1,0,1,0,0,0,_MBINIT_REVERSALMB,3'b011);
    send_data(1,1,0,0,0,0,_MBINIT_REVERSALMB,3'b011);
    send_data(1,1,0,0,0,0,_MBINIT_REPAIRMB,3'b011);

    send_data(1,0,1,0,0,0,_MBTRAIN_DATAVREF,3'b011);
    send_data(1,1,0,0,0,0,_MBTRAIN_DATATRAINCENTER1,3'b011);
    send_data(1,1,0,0,0,0,_MBTRAIN_DATATRAINVREF,3'b011);
    send_data(1,1,0,0,0,0,_MBTRAIN_RXDESKEW,3'b011);
    send_data(1,1,0,0,0,0,_MBTRAIN_DATATRAINCENTER2,3'b011);
    send_data(1,1,0,0,0,0,_MBTRAIN_LINKSPEED,3'b011);

    // comparison_Done disables the comparator.
    send_data(1,1,0,0,0,1,_MBTRAIN_DATAVREF,3'b011);

    // unsupported state.
    for(int i=0;i<19;i++)begin 
      send_data(1,1,1,0,0,0,all_states[i],3'b011);
    end

  endtask
endclass


class Enable_Generator_MBRX_LFSR_SEL_Sequence extends uvm_sequence #(Enable_Generator_MBRX_sequence_item);
  `uvm_object_utils(Enable_Generator_MBRX_LFSR_SEL_Sequence)
  `uvm_declare_p_sequencer(Enable_Generator_MBRX_sequencer)

  Enable_Generator_MBRX_sequence_item seq_item;

  function new(string name = "Enable_Generator_MBRX_LFSR_SEL_Sequence");
    super.new(name);
  endfunction

  task send_data(bit rst_n, bit valid, bit test_resp,bit frame_error, bit detec_succ,bit comparison_done, LTSM_states state,logic [2:0] width_degrade);

    seq_item = Enable_Generator_MBRX_sequence_item::type_id::create("seq_item");
    seq_item.constraint_mode(0);

    start_item(seq_item);
    if (!seq_item.randomize() with {
      seq_item.RST_n             == rst_n;
      seq_item.Valid             == valid;
      seq_item.Test_Resp         == test_resp;
      seq_item.Valid_Frame_Error == frame_error;
      seq_item.Detec_succ        == detec_succ;
      seq_item.Comparison_Done   == comparison_done;
      seq_item.LTSM_State        == state;
      seq_item.Width_Degrade     == width_degrade;
    })`uvm_fatal("LFSR_SEL_SEQ", "Randomization failed")

    finish_item(seq_item);
    p_sequencer.seqr_ap.write(seq_item);
  endtask

  task body();

    send_data(0,0,0,0,0,0,_RESET,3'b011);

    // LFSR_SEL = 1 in the specified training states.
    send_data(1,1,1,0,0,0,_MBTRAIN_DATAVREF,3'b011);
    send_data(1,1,0,0,0,0,_MBTRAIN_DATATRAINCENTER1,3'b011);
    send_data(1,1,0,0,0,0,_MBTRAIN_DATATRAINVREF,3'b011);
    send_data(1,1,0,0,0,0,_MBTRAIN_RXDESKEW,3'b011);
    send_data(1,1,0,0,0,0,_MBTRAIN_DATATRAINCENTER2,3'b011);
    send_data(1,1,0,0,0,0,_MBTRAIN_LINKSPEED,3'b011);

    // LFSR_SEL = 0 in ACTIVE.
    send_data(1,1,0,0,0,0,_ACTIVE,3'b011);
    

  endtask
endclass


class Enable_Generator_MBRX_Descr_EN_Sequence extends uvm_sequence #(Enable_Generator_MBRX_sequence_item);
  `uvm_object_utils(Enable_Generator_MBRX_Descr_EN_Sequence)
  `uvm_declare_p_sequencer(Enable_Generator_MBRX_sequencer)

  Enable_Generator_MBRX_sequence_item seq_item;
  LTSM_states all_states[] = '{
    _RESET,
    _SBINIT,
    _MBINIT_PARAM,
    _MBINIT_CAL,
    _MBINIT_REPAIRCLK,
    _MBINIT_REPAIRVAL,
    _MBINIT_REVERSALMB,
    _MBINIT_REPAIRMB,
    _MBTRAIN_VALVREF,
    _MBTRAIN_DATAVREF,
    _MBTRAIN_SPEEDIDLE,
    _MBTRAIN_TXSELFCAL,
    _MBTRAIN_RXCLKCAL,
    _MBTRAIN_VALTRAINCENTER,
    _MBTRAIN_DATATRAINCENTER1,
    _MBTRAIN_DATATRAINVREF,
    _MBTRAIN_RXDESKEW,
    _MBTRAIN_DATATRAINCENTER2,
    _MBTRAIN_LINKSPEED,
    _ACTIVE
  };

  function new(string name = "Enable_Generator_MBRX_Descr_EN_Sequence");
    super.new(name);
  endfunction

  task send_data(bit rst_n, bit valid, bit test_resp,bit frame_error, bit detec_succ,bit comparison_done, LTSM_states state,logic [2:0] width_degrade);

    seq_item = Enable_Generator_MBRX_sequence_item::type_id::create("seq_item");
    seq_item.constraint_mode(0);

    start_item(seq_item);
    if (!seq_item.randomize() with {
      seq_item.RST_n             == rst_n;
      seq_item.Valid             == valid;
      seq_item.Test_Resp         == test_resp;
      seq_item.Valid_Frame_Error == frame_error;
      seq_item.Detec_succ        == detec_succ;
      seq_item.Comparison_Done   == comparison_done;
      seq_item.LTSM_State        == state;
      seq_item.Width_Degrade     == width_degrade;
    })`uvm_fatal("DESCR_SEQ", "Randomization failed")

    finish_item(seq_item);
    p_sequencer.seqr_ap.write(seq_item);
  endtask

  task body();

    send_data(0,0,0,0,0,0,_RESET,3'b011);

    // active descrambler enable.
    send_data(1,1,0,0,0,0,_ACTIVE,3'b011);
    send_data(1,1,0,1,0,0,_ACTIVE,3'b011);
    send_data(1,1,0,0,1,0,_ACTIVE,3'b011);

    // Test_Resp must be latched.
    send_data(1,0,1,0,0,0,_MBTRAIN_DATAVREF,3'b011);
    send_data(1,1,0,0,0,0,_MBTRAIN_DATAVREF,3'b011);
    send_data(1,1,0,0,0,1,_MBTRAIN_DATAVREF,3'b011);

    // Other states where Descr_EN is enabled.
    send_data(1,1,1,0,0,0,_MBTRAIN_DATATRAINCENTER1,3'b011);
    send_data(1,1,1,0,0,0,_MBTRAIN_DATATRAINVREF,3'b011);
    send_data(1,1,1,0,0,0,_MBTRAIN_RXDESKEW,3'b011);
    send_data(1,1,1,0,0,0,_MBTRAIN_DATATRAINCENTER2,3'b011);
    send_data(1,1,1,0,0,0,_MBTRAIN_LINKSPEED,3'b011);

    // unsupported state.
    for(int i=0;i<19;i++)begin 
      send_data(1,1,1,0,0,0,all_states[i],3'b011);
    end

  endtask
endclass


class Enable_Generator_MBRX_Comparison_Type_Sequence extends uvm_sequence #(Enable_Generator_MBRX_sequence_item);
    `uvm_object_utils(Enable_Generator_MBRX_Comparison_Type_Sequence)
    `uvm_declare_p_sequencer(Enable_Generator_MBRX_sequencer)
    Enable_Generator_MBRX_sequence_item seq_item;
      LTSM_states all_states[] = '{
    _RESET,
    _SBINIT,
    _MBINIT_PARAM,
    _MBINIT_CAL,
    _MBINIT_REPAIRCLK,
    _MBINIT_REPAIRVAL,
    _MBINIT_REVERSALMB,
    _MBINIT_REPAIRMB,
    _MBTRAIN_VALVREF,
    _MBTRAIN_DATAVREF,
    _MBTRAIN_SPEEDIDLE,
    _MBTRAIN_TXSELFCAL,
    _MBTRAIN_RXCLKCAL,
    _MBTRAIN_VALTRAINCENTER,
    _MBTRAIN_DATATRAINCENTER1,
    _MBTRAIN_DATATRAINVREF,
    _MBTRAIN_RXDESKEW,
    _MBTRAIN_DATATRAINCENTER2,
    _MBTRAIN_LINKSPEED,
    _ACTIVE
  };
    function new(string name = "Enable_Generator_MBRX_Comparison_Type_Sequence");
        super.new(name);
    endfunction
    LTSM_states STATES; 

    task send_data(bit valid,bit frame_error,bit detec_succ,bit comparison_done,LTSM_states state,logic [2:0] width_degrade);
        seq_item = Enable_Generator_MBRX_sequence_item::type_id::create("seq_item");
        seq_item.constraint_mode(0);
        start_item(seq_item);
        if (!seq_item.randomize() with {
            seq_item.RST_n              == 1 ;
            seq_item.LTSM_State         == state;
            seq_item.Valid              == valid;
            seq_item.Valid_Frame_Error  == frame_error;
            seq_item.Detec_succ         == detec_succ;
            seq_item.Comparison_Done    == comparison_done;
            seq_item.Width_Degrade      == width_degrade;
        })
            `uvm_error("COMPARISON_TYPE_SEQ", "Transaction randomization failed")
        finish_item(seq_item);
        p_sequencer.seqr_ap.write(seq_item);
    endtask
    task body();
        // Reset to a known state before starting comparison-type checks.
        send_data(0, 0, 0, 0, _RESET, 3'b000);
        // Comparison_Type = 1 in _MBINIT_REVERSALMB
        send_data(0, 0, 0, 0, _MBINIT_REVERSALMB, 3'b000);
        // Comparison_Type = 1 in _MBINIT_REPAIRMB
        send_data(0, 0, 0, 0, _MBINIT_REPAIRMB, 3'b000);
        // try other states
        for(int i=0;i<19;i++)begin
          send_data(0, 0, 0, 0, all_states[i], 3'b000);
        end  
    endtask
endclass

// Sequence to verify deserializer enables for legal Width_Degrade values.
class Enable_Generator_MBRX_Width_Degrade_Sequence extends uvm_sequence #(Enable_Generator_MBRX_sequence_item);
  `uvm_object_utils(Enable_Generator_MBRX_Width_Degrade_Sequence)
  `uvm_declare_p_sequencer(Enable_Generator_MBRX_sequencer)
  Enable_Generator_MBRX_sequence_item seq_item;
  function new(string name = "Enable_Generator_MBRX_Width_Degrade_Sequence");
    super.new(name);
  endfunction

  // Helper task to drive Valid, Width_Degrade, and LTSM state.
  task send_data(bit valid, logic [2:0] width_degrade, LTSM_states state);
    seq_item = Enable_Generator_MBRX_sequence_item::type_id::create("seq_item");
    seq_item.constraint_mode(0);
    start_item(seq_item);
    if (!seq_item.randomize() with {
      seq_item.RST_n == 1;
      seq_item.LTSM_State == state;
      seq_item.Valid == valid;
      seq_item.Width_Degrade == width_degrade;
      seq_item.Test_Resp == 0;
      seq_item.Valid_Frame_Error == 0;
      seq_item.Detec_succ == 0;
      seq_item.Comparison_Done == 0;
    })
      `uvm_error("WIDTH_SEQ", "Randomization failed")
    finish_item(seq_item);
    p_sequencer.seqr_ap.write(seq_item);
  endtask

  task body();
    seq_item = Enable_Generator_MBRX_sequence_item::type_id::create("seq_item");
    seq_item.constraint_mode(0);
    start_item(seq_item);
    if (!seq_item.randomize() with {
      RST_n == 0;
      LTSM_State == _RESET;
      Valid == 0;
      Width_Degrade == 3'b001;
      Test_Resp == 0;
      Valid_Frame_Error == 0;
      Detec_succ == 0;
      Comparison_Done == 0;
    })`uvm_error("WIDTH_SEQ", "Reset randomization failed")
    finish_item(seq_item);
    p_sequencer.seqr_ap.write(seq_item);

    // select the lower half 
    repeat (4) send_data(1, 3'b001, _ACTIVE);
    repeat (4) send_data(0, 3'b001, _ACTIVE);
    // select the upper half.
    repeat (4) send_data(1, 3'b010, _ACTIVE);
    repeat (4) send_data(0, 3'b010, _ACTIVE);
    // select both halves.
    repeat (4) send_data(1, 3'b011, _ACTIVE);
    repeat (4) send_data(0, 3'b011, _ACTIVE);
    // any other state, deserializer enables should be low.
    repeat (4) send_data(1, 3'b011, _MBTRAIN_DATATRAINVREF);
    repeat (4) send_data(0, 3'b011, _MBTRAIN_DATATRAINVREF);
    repeat (4) send_data(1, 3'b011, _MBTRAIN_DATATRAINCENTER2);
    repeat (4) send_data(0, 3'b011, _MBTRAIN_DATATRAINCENTER2);

  endtask
endclass

// Sequence to inject invalid Width_Degrade encodings and test their behavior.
class Enable_Generator_MBRX_inject_error_sequence extends uvm_sequence #(Enable_Generator_MBRX_sequence_item);
    `uvm_object_utils(Enable_Generator_MBRX_inject_error_sequence)
    `uvm_declare_p_sequencer(Enable_Generator_MBRX_sequencer)
    Enable_Generator_MBRX_sequence_item seq_item;

    function new(string name = "Enable_Generator_MBRX_inject_error_sequence");
        super.new(name);
    endfunction

    task send_data(bit valid, logic [2:0] width_degrade, LTSM_states state);
      seq_item = Enable_Generator_MBRX_sequence_item::type_id::create("seq_item");
      seq_item.constraint_mode(0);
      start_item(seq_item);
      if (!seq_item.randomize() with {
        seq_item.RST_n == 1;
        seq_item.LTSM_State == state;
        seq_item.Valid == valid;
        seq_item.Width_Degrade == width_degrade;
        seq_item.Test_Resp == 0;
        seq_item.Valid_Frame_Error == 0;
        seq_item.Detec_succ == 0;
        seq_item.Comparison_Done == 0;
      })`uvm_error("WIDTH_SEQ", "Randomization failed")
      finish_item(seq_item);
      p_sequencer.seqr_ap.write(seq_item);
    endtask

    task body();
      seq_item = Enable_Generator_MBRX_sequence_item::type_id::create("reset_item");
      seq_item.constraint_mode(0);
      start_item(seq_item);
      if (!seq_item.randomize() with {
        RST_n == 0;
        LTSM_State == _RESET;
        Valid == 0;
        Width_Degrade == 3'b001;
        Test_Resp == 0;
        Valid_Frame_Error == 0;
        Detec_succ == 0;
        Comparison_Done == 0;
      })
        `uvm_error("WIDTH_SEQ", "Reset randomization failed")
      finish_item(seq_item);
      p_sequencer.seqr_ap.write(seq_item);

      // inject invalid encoding 000.
      repeat (4) send_data(1, 3'b000, _ACTIVE);
      repeat (4) send_data(0, 3'b000, _ACTIVE);
      // inject invalid encoding 100.
      repeat (4) send_data(1, 3'b100, _ACTIVE);
      repeat (4) send_data(0, 3'b100, _ACTIVE);
      // inject invalid encoding 110.
      repeat (4) send_data(1, 3'b110, _ACTIVE);
      repeat (4) send_data(0, 3'b110, _ACTIVE);
      // inject invalid encoding 101.
      repeat (4) send_data(1, 3'b101, _ACTIVE);
      repeat (4) send_data(0, 3'b101, _ACTIVE);
      // inject invalid encoding 111.
      repeat (4) send_data(1, 3'b111, _ACTIVE);
      repeat (4) send_data(0, 3'b111, _ACTIVE);

    endtask
endclass

// Sequence to stress the DUT with repeated valid framing in ACTIVE.
class Enable_Generator_MBRX_random_stress_sequence extends uvm_sequence #(Enable_Generator_MBRX_sequence_item);
    `uvm_object_utils(Enable_Generator_MBRX_random_stress_sequence)
    `uvm_declare_p_sequencer(Enable_Generator_MBRX_sequencer)
    Enable_Generator_MBRX_sequence_item seq_item;

    function new(string name = "Enable_Generator_MBRX_random_stress_sequence");
        super.new(name);
    endfunction

    task body();
      bit valid_value;
      seq_item = Enable_Generator_MBRX_sequence_item::type_id::create("seq_item");
      seq_item.constraint_mode(0);
      seq_item.random_stress_c.constraint_mode(1);

      repeat (1000) begin
        // Generate 4 UI with Valid high, followed by 4 UI with Valid low.
        for (int i = 0; i < 8; i++) begin
          valid_value = (i);
          start_item(seq_item);
          if (!seq_item.randomize() with {seq_item.Valid == valid_value;})`uvm_error("RANDOM_STRESS","Random stress sequence item randomization failed")
          finish_item(seq_item);
          p_sequencer.seqr_ap.write(seq_item);
        end
      end
    endtask
endclass
