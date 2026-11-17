`ifndef LFSR_PER_LANE_SCOREBOARD_SVH
`define LFSR_PER_LANE_SCOREBOARD_SVH

class lfsr_per_lane_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(lfsr_per_lane_scoreboard)
  uvm_analysis_imp#(lfsr_per_lane_sequence_item, lfsr_per_lane_scoreboard) sb_aimp;


  int err = 0, pass = 0, total = 0;

  bit [1:0] delay = 0;

  lfsr_per_lane_sequence_item exp_txn;
  lfsr_per_lane_sequence_item prev_txn;

  bit have_prev = 0;

  function new(string name = "lfsr_per_lane_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    exp_txn = lfsr_per_lane_sequence_item::type_id::create("exp_txn");
    prev_txn = lfsr_per_lane_sequence_item::type_id::create("prev_txn");
    sb_aimp = new("sb_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

  function void cal_new_seq (ref bit [WIDTH-1:0] curr_seq);
      const bit [WIDTH-1:0] tap_points = 23'h210124;
      bit [WIDTH-1:0] new_seq;
      bit m = curr_seq[22];
      new_seq[0] = m;
      for (int j = 1 ; j < 23 ; j ++) begin
        if (tap_points[j]) 
          new_seq [j] = curr_seq[j-1] ^ m;
        else 
          new_seq [j] = curr_seq[j-1];
      end
      curr_seq = new_seq;
  endfunction

  function void ref_model (lfsr_per_lane_sequence_item cur);
    static bit [WIDTH-1:0] curr_seq;
    static bit data_out_reg;

    static bit [7:0] Valid_reg;
    static bit VLD_SER_EN_reg;

    static bit [4:0] Opcode_Synch_old;


  // Sequential

    if (!cur.RST_n) begin
      Opcode_Synch_old = 'b0;
      data_out_reg= 'b0;
      curr_seq = 23'h1DBFBC;
      Valid_reg = 'b0;
      VLD_SER_EN_reg = 'b0;
    end
    else if (!have_prev || !prev_txn.RST_n) begin
      curr_seq = 23'h1DBFBC; 
      data_out_reg = 0; 
      Valid_reg = 0;
      VLD_SER_EN_reg = 0; 
      Opcode_Synch_old = 0;
    end
    else if (have_prev) begin
      if (Opcode_Synch_old != prev_txn.Opcode_Synch) begin
        curr_seq = 23'h1DBFBC;
        data_out_reg = 'b0;
        Opcode_Synch_old = prev_txn.Opcode_Synch; 
      end
      else if (prev_txn.EN) begin
        if (prev_txn.PN_EN) begin
          data_out_reg = prev_txn.Data_In ^ curr_seq[22];
          Valid_reg = 8'h0F;
          VLD_SER_EN_reg = 1'b1;
        end  
        else begin
          Valid_reg = 8'h00;
          VLD_SER_EN_reg = 1'b0;
        end
        cal_new_seq(curr_seq);
      end
      else begin
        Valid_reg = 8'h00;
        VLD_SER_EN_reg = 1'b0;
        data_out_reg = 'b0;
      end
    end

    // Combinational
    if (cur.PN_EN) begin
      exp_txn.Data_Out = data_out_reg; 
      `uvm_info("LFSR_PER_LANE_SCB", $sformatf("Scrambling: m=%0b, Data_In=%0b, LFSR=%0h, Data_Out=%0b", curr_seq[22], cur.Data_In, curr_seq, exp_txn.Data_Out), UVM_HIGH)
    end
    else if (cur.EN) begin
      exp_txn.Data_Out = cur.Data_In ^ curr_seq[22];
      `uvm_info("LFSR_PER_LANE_SCB", $sformatf("Scrambling: m=%0b, Data_In=%0b, LFSR=%0h, Data_Out=%0b", curr_seq[22], cur.Data_In, curr_seq, exp_txn.Data_Out), UVM_HIGH)
    end
    else begin
      exp_txn.Data_Out = cur.Data_In;
    end

    exp_txn.Valid = Valid_reg;
    exp_txn.VLD_SER_EN = VLD_SER_EN_reg;
  endfunction

function void self_check(lfsr_per_lane_sequence_item t);
    total++;

    if ((t.Data_Out !== exp_txn.Data_Out) ||
        (t.Valid !== exp_txn.Valid) ||
        (t.VLD_SER_EN !== exp_txn.VLD_SER_EN)) begin
      err++;
      `uvm_error("LFSR_PER_LANE_SCB",
        $sformatf("Mismatch #%0d: RST_n=%0b Opcode_Synch=0x%0h EN=%0b PN_EN=%0b Data_In=%0b | Data_Out expected=%0b actual=%0b, Valid expected=0x%0h actual=0x%0h, VLD_SER_EN expected=%0b actual=%0b",
          total, t.RST_n, t.Opcode_Synch, t.EN, t.PN_EN, t.Data_In,
          exp_txn.Data_Out, t.Data_Out, exp_txn.Valid, t.Valid,
          exp_txn.VLD_SER_EN, t.VLD_SER_EN))
    end
    else begin
      pass++;
      `uvm_info("LFSR_PER_LANE_SCB",
        $sformatf("Transaction #%0d matched", total), UVM_HIGH)
    end
endfunction

function void write(lfsr_per_lane_sequence_item t);
  if (t == null) return;

  ref_model(t);        // prev_txn must still be the PREVIOUS cycle here
  self_check(t);

  prev_txn.copy(t);    // NOW advance history
  have_prev = 1'b1;
endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
    `uvm_info("SCB_REPORT", "              LFSR PERLANE SCOREBOARD REPORT                ", UVM_NONE)
    `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total Transactions Received : %0d", total), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total Matches               : %0d", pass), UVM_NONE)
    `uvm_info("SCB_REPORT", $sformatf(" Total Mismatches            : %0d", err), UVM_NONE)
    `uvm_info("SCB_REPORT", "------------------------------------------------------------", UVM_NONE)

    if (err == 0 && total > 0) begin
      `uvm_info("SCB_REPORT", "        *** [TEST PASSED] ALL CHECKS MATCHED! ***           ", UVM_NONE)
    end else if (total == 0) begin
      `uvm_warning("SCB_REPORT", "    *** [TEST INCOMPLETE] NO TRANSACTIONS RECEIVED! ***    ")
    end else begin
      `uvm_error("SCB_REPORT", $sformatf("    *** [TEST FAILED] %0d MISMATCHES DETECTED! ***      ", err))
    end
    `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
  endfunction
endclass

`endif // LFSR_PER_LANE_SCOREBOARD_SVH
