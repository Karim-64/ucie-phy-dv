`ifndef CREDITS_HANDLER_SBTX_PROTOCOL_SEQUENCE_SVH
`define CREDITS_HANDLER_SBTX_PROTOCOL_SEQUENCE_SVH

class Credits_Handler_SBTX_protocol_sequence extends uvm_sequence #(Credits_Handler_SBTX_sequence_item);
  `uvm_object_utils(Credits_Handler_SBTX_protocol_sequence)
  `uvm_declare_p_sequencer(Credits_Handler_SBTX_sequencer)

  Credits_Handler_SBTX_sequence_item req;

  function new(string name = "Credits_Handler_SBTX_protocol_sequence");
    super.new(name);
  endfunction

  task body();
  // 128-bit D2D message (header, data, completion, comp_sent from decoder)
  // only one credit sshould be generated
    req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
    start_item(req);
    assert (req.randomize()
    with {rst_n == 1;
          D2D_phy_marker == 1;
          data_marker == 0;
          comp_marker == 0;
          credit == 0;
          comp_sent == 0;
          UIE == 0;
          }) 
          else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
    start_item(req);
    assert (req.randomize()
    with {rst_n == 1;
          D2D_phy_marker == 1;
          data_marker == 1;
          comp_marker == 0;
          credit == 0;
          comp_sent == 0;
          UIE == 0;
          }) 
          else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
    start_item(req);
    assert (req.randomize()
    with {rst_n == 1;
          D2D_phy_marker == 1;
          data_marker == 0;
          comp_marker == 1;
          credit == 0;
          comp_sent == 0;
          UIE == 0;
          }) 
          else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    // held comp_sent -> 1 credit only for risiing edge
    req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
    start_item(req);
    assert (req.randomize()
    with {rst_n == 1;
          D2D_phy_marker == 0;
          data_marker == 0;
          comp_marker == 0;
          credit == 0;
          comp_sent == 1;
          UIE == 0;
          }) 
          else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);

    req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
    start_item(req);
    assert (req.randomize()
    with {rst_n == 1;
          D2D_phy_marker == 0;
          data_marker == 0;
          comp_marker == 0;
          credit == 0;
          comp_sent == 1;
          UIE == 0;
          }) 
          else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
  endtask
endclass

`endif // CREDITS_HANDLER_SBTX_PROTOCOL_SEQUENCE_SVH
