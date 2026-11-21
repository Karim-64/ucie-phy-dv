`ifndef SERIALIZER_SCOREBOARD_SVH
`define SERIALIZER_SCOREBOARD_SVH

class Serializer_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(Serializer_scoreboard)
  //uvm_analysis_imp#(Serializer_sequence_item, Serializer_scoreboard) sb_aimp;
  uvm_analysis_export #(Serializer_sequence_item) serializer_analysis_export;
  uvm_tlm_analysis_fifo #(Serializer_sequence_item) serializer_analysis_fifo;

  Serializer_sequence_item seq_item;

  // expected outputs
  logic SER_OUT_expected;

  // internal signals
  bit [7:0] shift_reg;
  bit start_shift;
  int counter;

  // error and correct counters.
  int error_counter;
  int correct_counter; 

  function new(string name = "Serializer_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    //sb_aimp = new("sb_aimp", this);
    serializer_analysis_export =  new("serializer_analysis_export",this);
    serializer_analysis_fifo   =  new("serializer_analysis_fifo",this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    serializer_analysis_export.connect(serializer_analysis_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    // drop first transaction
    serializer_analysis_fifo.get(seq_item);
    forever begin
      serializer_analysis_fifo.get(seq_item);
      reference_model(seq_item);
      check_data(seq_item);
    end
  endtask

  task reference_model(input Serializer_sequence_item seq_item);
      // when SER_EN is disabled, all signals return to thier default values
      if(seq_item.SER_EN == 1'b0)begin
        SER_OUT_expected = 1'b0;
        shift_reg        = 8'b0;
        start_shift      = 1'b1;
        counter          = 32'b0;
      end
      else begin
        if(start_shift == 1'b1)begin
          SER_OUT_expected = seq_item.DATA[0]; // sent the LSB immediatly
          shift_reg        = {1'b0,seq_item.DATA[7:1]}; // shift right logic
          start_shift      = 1'b0;
          counter          = 1;
        end
        else begin
          SER_OUT_expected = shift_reg[0];          // send the remaining bits
          shift_reg        = {1'b0,shift_reg[7:1]}; // shift right logic
          counter++;                                // increment counter for next bit

          // counter = 8 indecated that all bits are sent then make counter = 0 and start a new shift
          if(counter == 8)begin
            start_shift = 1'b1;
            counter =0;
          end

        end
      end
  endtask

  task check_data(input Serializer_sequence_item seq_item);
    if ((seq_item.SER_OUT !== SER_OUT_expected)) begin
        $display("Output mismatch: time=%t SER_EN=%0b DATA=%d,SER_OUT=%b,SER_OUT_expected=%b",
        $time,seq_item.SER_EN, seq_item.DATA, seq_item.SER_OUT,SER_OUT_expected);
      error_counter++;
    end else begin
      correct_counter++;
    end
  endtask

  //function void write(Serializer_sequence_item t);
  //  // TODO: Implement the reference model logic and output checking
  //endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    $display("==================================================");
    $display("        Serializer SCOREBOARD SUMMARY             ");
    $display("==================================================");
    $display(" Successful Matches : %0d", correct_counter);
    $display(" Mismatches/Errors  : %0d", error_counter);
    $display("==================================================");
  endfunction
endclass

`endif // SERIALIZER_SCOREBOARD_SVH
