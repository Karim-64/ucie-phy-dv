`ifndef TIMER_SBTX_SEQUENCE_ITEM_SVH
`define TIMER_SBTX_SEQUENCE_ITEM_SVH

class Timer_SBTX_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(Timer_SBTX_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic rst_n;
  rand logic start;

  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic alarm;

  constraint c_normal {
      rst_n == 1'b1;
      start dist { 1'b0 := 50, 1'b1 := 50 };
  }


  constraint c_rand_start {
      start dist { 1'b0 := 50, 1'b1 := 50 };
  }

  constraint c_rand_reset{
      rst_n dist { 1'b0 := 50, 1'b1 := 50 };
  }

  constraint c_rand {
      rst_n dist { 1'b0 := 50, 1'b1 := 50 };
      start dist { 1'b0 := 50, 1'b1 := 50 };
  }

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "Timer_SBTX_sequence_item");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("rst_n=%0b start=%0b alarm=%0b ", rst_n, start, alarm);
  endfunction

endclass

`endif // TIMER_SBTX_SEQUENCE_ITEM_SVH
