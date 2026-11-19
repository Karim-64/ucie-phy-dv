`ifndef CREDITS_HANDLER_SBTX_COMBINATIONS_SEQUENCE_SVH
`define CREDITS_HANDLER_SBTX_COMBINATIONS_SEQUENCE_SVH

class Credits_Handler_SBTX_combinations_sequence extends uvm_sequence #(Credits_Handler_SBTX_sequence_item);
  `uvm_object_utils(Credits_Handler_SBTX_combinations_sequence)
  `uvm_declare_p_sequencer(Credits_Handler_SBTX_sequencer)

  Credits_Handler_SBTX_sequence_item req;
  int num_txns = 30;

  function new(string name = "Credits_Handler_SBTX_combinations_sequence");
    super.new(name);
  endfunction

  task reset;
    req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
    start_item(req);
    assert (req.randomize() with {rst_n == 0;}) else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
  endtask

  task idle;
    repeat(3) begin
    start_item(req);
    assert (req.randomize() with {rst_n == 1; comp_sent == 0; credit == 0; D2D_phy_marker == 0; UIE == 0;}) else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
    end
  endtask

  task body();
    // 3 simultaneous credits -> 2 combinations
    // comp + D2D + UIE
    reset;
    req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
    start_item(req);
    assert (req.randomize() with {rst_n == 1; comp_sent == 1; credit == 0; D2D_phy_marker == 1; data_marker == 0; comp_marker == 0; UIE == 1;}) else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
    idle;

    // credit + D2D + UIE -> missing in RTL
    reset;
    req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
    start_item(req);
    assert (req.randomize() with {rst_n == 1; comp_sent == 0; credit == 1; D2D_phy_marker == 1; data_marker == 0; comp_marker == 0; UIE == 1;}) else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
    idle;

    // 2 simultaneous credits -> 6 combinations
    // comp + D2D
    reset;
    req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
    start_item(req);
    assert (req.randomize() with {rst_n == 1; comp_sent == 1; credit == 0; D2D_phy_marker == 1; data_marker == 0; comp_marker == 0; UIE == 0;}) else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
    idle;

    // comp + UIE
    reset;
    req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
    start_item(req);
    assert (req.randomize() with {rst_n == 1; comp_sent == 1; credit == 0; D2D_phy_marker == 0; UIE == 1;}) else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
    idle;

    // credit + UIE
    reset;
    req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
    start_item(req);
    assert (req.randomize() with {rst_n == 1; comp_sent == 0; credit == 1; D2D_phy_marker == 0; UIE == 1;}) else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
    idle;

    // UIE + D2D
    reset;
    req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
    start_item(req);
    assert (req.randomize() with {rst_n == 1; comp_sent == 0; credit == 0; D2D_phy_marker == 1; data_marker == 0; comp_marker == 0; UIE == 1;}) else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
    idle;

    // credit + D2D -> missing in RTL
    reset;
    req = Credits_Handler_SBTX_sequence_item::type_id::create("req");
    start_item(req);
    assert (req.randomize() with {rst_n == 1; comp_sent == 0; credit == 1; D2D_phy_marker == 1; data_marker == 0; comp_marker == 0; UIE == 0;}) else `uvm_error("SEQ", "Randomization failed")
    finish_item(req);
    p_sequencer.seqr_aport.write(req);
    idle;

    // comp + credit -> impossible because both signals orginate from decoder and are mutually exclusive

  endtask
endclass

`endif // CREDITS_HANDLER_SBTX_COMBINATIONS_SEQUENCE_SVH
