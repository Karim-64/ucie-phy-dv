`ifndef CREDITS_HANDLER_SBTX_CONCURRENT_BURST_AND_DRAIN_SEQUENCE_SVH
`define CREDITS_HANDLER_SBTX_CONCURRENT_BURST_AND_DRAIN_SEQUENCE_SVH

//====================================================================
// This sequence fails : due to saved credit reset every cycle in DUT
//====================================================================

class Credits_Handler_SBTX_concurrent_burst_and_drain_sequence extends uvm_sequence #(Credits_Handler_SBTX_sequence_item);
  `uvm_object_utils(Credits_Handler_SBTX_concurrent_burst_and_drain_sequence)
  `uvm_declare_p_sequencer(Credits_Handler_SBTX_sequencer)

  Credits_Handler_SBTX_sequence_item req;

  function new(string name = "Credits_Handler_SBTX_concurrent_burst_and_drain_sequence");
    super.new(name);
  endfunction

  task body();
  // 3 sources for credit asserted, 2 sources asserted the next cycle, expected 5 cycles of high output (including the second cycle)
    req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
    start_item(req);
    assert (req.randomize()
    with { rst_n == 1;
          D2D_phy_marker == 1;
          data_marker == 0;
          comp_marker == 0;
          credit == 1;
          UIE == 1;
          }) 
          else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
    start_item(req);
    assert (req.randomize()
    with { rst_n == 1;
          D2D_phy_marker == 0;
          data_marker == 0;
          comp_marker == 0;
          credit == 0;
          comp_sent == 1;
          UIE == 1;
          }) 
          else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    repeat(5) begin
      req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
      start_item(req);
      assert (req.randomize()
      with { rst_n == 1;
            D2D_phy_marker == 0;
            data_marker == 0;
            comp_marker == 0;
            credit == 0;
            comp_sent == 0;
            UIE == 0;
            }) 
            else `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end
  endtask
endclass

`endif // CREDITS_HANDLER_SBTX_CONCURRENT_BURST_AND_DRAIN_SEQUENCE_SVH
