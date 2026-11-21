`ifndef GRAY_SYNCHRONIZER_SBTX_SCOREBOARD_SVH
`define GRAY_SYNCHRONIZER_SBTX_SCOREBOARD_SVH

class gray_synchronizer_sbtx_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(gray_synchronizer_sbtx_scoreboard)
  uvm_analysis_imp#(gray_synchronizer_sbtx_sequence_item, gray_synchronizer_sbtx_scoreboard) sb_aimp;

  int err = 0, pass = 0, total = 0;

  bit [DATA_SIZE-1:0] ff1, ff2;
  bit [1:0] delay = 0;

  gray_synchronizer_sbtx_sequence_item exp_txn;
  gray_synchronizer_sbtx_sequence_item temp;
  gray_synchronizer_sbtx_sequence_item in_txn[$];

  function new(string name = "gray_synchronizer_sbtx_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    exp_txn = gray_synchronizer_sbtx_sequence_item::type_id::create("exp_txn");
    sb_aimp = new("sb_aimp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  
  function void ref_model (gray_synchronizer_sbtx_sequence_item t);
    if (t == null) begin
      `uvm_error("SCB_NULL_ITEM", "Received null sequence item in Synchronizer_scoreboard")
      return;
    end
    if (!t.RST_n) begin
      exp_txn.Sync_Data <= 'b0;
      ff1 <= 'b0;
      ff2 <= 'b0;
    end
    else begin
      ff1 <= t.Async_Data;
      ff2 <= ff1;
    end
    exp_txn.Sync_Data = ff2;
  endfunction

  function void check_item (gray_synchronizer_sbtx_sequence_item act, gray_synchronizer_sbtx_sequence_item exp);
    if (act.Sync_Data != exp.Sync_Data) begin
      err++;
      `uvm_error ("GRAY_SYNC_SBTX_SCOREBOARD", "ERROR! -- ACTUAL OUT NOT EQUAL EXPECTED OUT")
      `uvm_info ("GRAY_SYNC_SBTX_SCOREBOARD", $sformatf ("ACTUAL STIM: %s, EXPCTED: 0x%h",act.convert2string, exp.Sync_Data), UVM_MEDIUM)
    end
    else begin
      pass ++;
      `uvm_info ("GRAY_SYNC_SBTX_SCOREBOARD", "PASS! -- ACTUAL EQUAL OUTPUT", UVM_HIGH)
      `uvm_info ("GRAY_SYNC_SBTX_SCOREBOARD", $sformatf ("ACTUAL STIM: %s, EXPCTED: 0x%h",act.convert2string, exp.Sync_Data), UVM_HIGH)
    end

    total ++;
  endfunction


  function void write(gray_synchronizer_sbtx_sequence_item t);
    if (t == null) begin
      `uvm_error("SCB_NULL_ITEM", "Received null sequence item in Synchronizer_scoreboard")
      return;
    end

    if (delay == 0) begin
      delay = 1;
    end
    else begin
      in_txn.push_back(t);
      if (delay == 1) begin
        delay = 2;
      end
      else begin
        
        $cast(temp, in_txn.pop_front().clone());
        ref_model (temp);
        if (t.RST_n == 0) begin
          temp.RST_n = 0;
          ref_model (temp);
        end
        check_item (temp, exp_txn);

      end
    end
  endfunction


  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("SCB_REPORT", "============================================================", UVM_NONE)
    `uvm_info("SCB_REPORT", "           GRAY SYNCHRONIZER SCOREBOARD REPORT               ", UVM_NONE)
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

`endif // GRAY_SYNCHRONIZER_SBTX_SCOREBOARD_SVH
