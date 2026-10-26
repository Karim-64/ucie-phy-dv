`ifndef TIMER_MS_SBTX_SEQUENCE_ITEM_SVH
`define TIMER_MS_SBTX_SEQUENCE_ITEM_SVH

class Timer_ms_SBTX_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(Timer_ms_SBTX_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic rst_n;
  rand logic start;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic alarm;
  logic patt_alarm;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "Timer_ms_SBTX_sequence_item");
    super.new(name);
  endfunction
  
  // -------------------------------------------------------------------------
  //  Constraints
  // -------------------------------------------------------------------------
  constraint c_rst_n{
    rst_n dist {0:=1, 1:=9};
  }
  
  constraint c_start{
    start dist {0:=4, 1:=6};
  }


  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("Timer_ms_SBTX_seq_item: rst_n=%0b start=%0b alarm=%0b patt_alarm=%0b",
      rst_n, start, alarm, patt_alarm);
  endfunction

endclass

`endif // TIMER_MS_SBTX_SEQUENCE_ITEM_SVH
