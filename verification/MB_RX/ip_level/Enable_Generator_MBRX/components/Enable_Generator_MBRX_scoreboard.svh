`ifndef ENABLE_GENERATOR_MBRX_SCOREBOARD_SVH
`define ENABLE_GENERATOR_MBRX_SCOREBOARD_SVH

import Universal_pkg::*;
class Enable_Generator_MBRX_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(Enable_Generator_MBRX_scoreboard)
  Enable_Generator_MBRX_sequence_item seq_item;
  
  uvm_analysis_export#(Enable_Generator_MBRX_sequence_item) sb_export;
  uvm_tlm_analysis_fifo #(Enable_Generator_MBRX_sequence_item) sb_analysis_fifo;

  // expected output signals.
  bit Vchk_EN_expected;
  bit Descr_EN_expected;
  bit Deserializer_EN1_expected;
  bit Deserializer_EN2_expected;
  bit Data_Comparator_EN_expected;
  bit Valid_Detected_expected;
  bit Comparison_Type_expected;
  bit LFSR_SEL_expected;

  // internal signals.
  bit delayed_valid;
  bit chunk_marker;
  bit delayed_test_resp;
  LTSM_states old_state;

  // error and correct counters.
  int error_counter;
  int correct_counter;

  function new(string name = "Enable_Generator_MBRX_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sb_export         = new("sb_export",this);
    sb_analysis_fifo  = new("sb_analysis_fifo",this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    sb_export.connect(sb_analysis_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    // drop first seq_item
    sb_analysis_fifo.get(seq_item);
    forever begin
      sb_analysis_fifo.get(seq_item);
      reference_model(seq_item);
      check_data(seq_item);
    end
  endtask
  
  task reference_model(input Enable_Generator_MBRX_sequence_item seq_item);
    // handle valid_detected logic and reset it in the reset state  .
    if (seq_item.LTSM_State == _RESET) begin
      Valid_Detected_expected = 1'b0;
    end else begin
      Valid_Detected_expected = (~delayed_valid) & seq_item.Valid;
    end

    // Vchk_EN is enabled by a valid edge or active chunk, unless terminated.
    // In non-ACTIVE states, it additionally requires a latched test response.
    if(seq_item.LTSM_State == _ACTIVE)begin
      Vchk_EN_expected = ((Valid_Detected_expected | chunk_marker ) & (~(seq_item.Valid_Frame_Error | seq_item.Detec_succ)))? 1'b1:1'b0;
    end
    else begin 
      Vchk_EN_expected = (((Valid_Detected_expected) | (chunk_marker)) & (~(seq_item.Valid_Frame_Error | seq_item.Detec_succ))) & (delayed_test_resp) ? 1'b1 : 1'b0;
    end

    // Each deserializer follows its corresponding Width_Degrade bit.
    if(seq_item.LTSM_State == _ACTIVE)begin
      Deserializer_EN1_expected = (((chunk_marker) | (Valid_Detected_expected)) & (seq_item.Width_Degrade == 1 | seq_item.Width_Degrade == 3))? 1'b1:1'b0;
      Deserializer_EN2_expected = (((chunk_marker) | (Valid_Detected_expected)) & (seq_item.Width_Degrade == 2 | seq_item.Width_Degrade == 3))? 1'b1:1'b0;
    end
    else begin
      Deserializer_EN1_expected = 1'b0;
      Deserializer_EN2_expected = 1'b0;
    end
    // The comparator is active only in supported states .
     if ((seq_item.LTSM_State     == _MBINIT_REVERSALMB) ||
             (seq_item.LTSM_State == _MBINIT_REPAIRMB) ||
             (seq_item.LTSM_State == _MBTRAIN_DATAVREF) ||
             (seq_item.LTSM_State == _MBTRAIN_DATATRAINCENTER1) ||
             (seq_item.LTSM_State == _MBTRAIN_DATATRAINVREF) ||
             (seq_item.LTSM_State == _MBTRAIN_RXDESKEW) ||
             (seq_item.LTSM_State == _MBTRAIN_DATATRAINCENTER2) ||
             (seq_item.LTSM_State == _MBTRAIN_LINKSPEED) //||
             )begin
              Data_Comparator_EN_expected = (((Valid_Detected_expected) | (chunk_marker)) & ~(seq_item.Comparison_Done)) & (delayed_test_resp) ? 1'b1 : 1'b0;
    end
    else begin
       Data_Comparator_EN_expected = 1'b0;
    end

    if(seq_item.LTSM_State == _ACTIVE)begin
      Descr_EN_expected = (((chunk_marker) | (Valid_Detected_expected)) & (~(seq_item.Valid_Frame_Error | seq_item.Detec_succ)))? 1'b1:1'b0;
      LFSR_SEL_expected = 1'b0;
    end
    else if ((seq_item.LTSM_State == _MBTRAIN_DATAVREF) ||
             (seq_item.LTSM_State == _MBTRAIN_DATATRAINCENTER1) ||
             (seq_item.LTSM_State == _MBTRAIN_DATATRAINVREF) ||
             (seq_item.LTSM_State == _MBTRAIN_RXDESKEW) ||
             (seq_item.LTSM_State == _MBTRAIN_DATATRAINCENTER2) ||
             (seq_item.LTSM_State == _MBTRAIN_LINKSPEED))begin  
              Descr_EN_expected = (((Valid_Detected_expected) | (chunk_marker)) & (~seq_item.Comparison_Done)) & (delayed_test_resp) ? 1'b1 : 1'b0;
              LFSR_SEL_expected = 1'b1;
    end
    else begin
       Descr_EN_expected = 1'b0;
       LFSR_SEL_expected = 1'b0;
    end
    // Per-lane ID pattern comparison is selected in these two MBINIT states.
    Comparison_Type_expected= ((seq_item.LTSM_State == _MBINIT_REVERSALMB || seq_item.LTSM_State == _MBINIT_REPAIRMB))? 1'b1:1'b0;

    if (!seq_item.RST_n) begin
      delayed_valid     = 1'b0;
      chunk_marker      = 1'b0;
      delayed_test_resp = 1'b0;
      old_state         = _RESET;
    end
    else begin

      // Clear the marker on termination or state change.
      if (seq_item.Comparison_Done || seq_item.Valid_Frame_Error || seq_item.Detec_succ || (seq_item.LTSM_State != old_state)) begin
        chunk_marker = 1'b0;
      end
      else if (Valid_Detected_expected) begin
        chunk_marker = 1'b1;
      end

      // Test_Resp assertion takes priority over the termination-event clear.
      if (seq_item.Test_Resp) begin
        delayed_test_resp = 1'b1;
      end
      else if (seq_item.Comparison_Done || seq_item.Valid_Frame_Error || seq_item.Detec_succ) begin
        delayed_test_resp = 1'b0;
      end

      delayed_valid = seq_item.Valid;
      old_state     = seq_item.LTSM_State;
    end
  endtask

  task check_data(input Enable_Generator_MBRX_sequence_item t);
    
    if ((t.Valid_Detected     !== Valid_Detected_expected) ||
        (t.Vchk_EN            !== Vchk_EN_expected) ||
        (t.Descr_EN           !== Descr_EN_expected) ||
        (t.Deserializer_EN1   !== Deserializer_EN1_expected) ||
        (t.Deserializer_EN2   !== Deserializer_EN2_expected) ||
        (t.Data_Comparator_EN !== Data_Comparator_EN_expected) ||
        (t.Comparison_Type    !== Comparison_Type_expected) ||
        (t.LFSR_SEL           !== LFSR_SEL_expected)
        ) begin
      `uvm_error("ENABLE_GENERATOR_MBRX_SB",
      $sformatf("Mismatch inputs: RST_n=%0b LTSM_State=%s Width_Degrade=%d Valid=%0b Comparison_Done=%0b Valid_Frame_Error=%0b Detec_succ=%0b Test_Resp=%0b\nOutputs RTL/expected: Valid_Detected=%0b/%0b Vchk_EN=%0b/%0b Descr_EN=%0b/%0b Deserializer_EN1=%0b/%0b Deserializer_EN2=%0b/%0b Data_Comparator_EN=%0b/%0b Comparison_Type=%0b/%0b LFSR_SEL=%0b/%0b",
          t.RST_n, t.LTSM_State.name(), t.Width_Degrade, t.Valid,
          t.Comparison_Done, t.Valid_Frame_Error, t.Detec_succ, t.Test_Resp,
          t.Valid_Detected, Valid_Detected_expected,
          t.Vchk_EN, Vchk_EN_expected,
          t.Descr_EN, Descr_EN_expected,
          t.Deserializer_EN1, Deserializer_EN1_expected,
          t.Deserializer_EN2, Deserializer_EN2_expected,
          t.Data_Comparator_EN, Data_Comparator_EN_expected,
          t.Comparison_Type, Comparison_Type_expected,
          t.LFSR_SEL, LFSR_SEL_expected));
      error_counter++;
    end else begin
      correct_counter++;
    end
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    $display("==================================================");
    $display("         Enable Generator SCOREBOARD SUMMARY      ");
    $display("==================================================");
    $display(" Successful Matches : %0d", correct_counter);
    $display(" Mismatches/Errors  : %0d", error_counter);
    $display("==================================================");
  endfunction

endclass

`endif // ENABLE_GENERATOR_MBRX_SCOREBOARD_SVH
