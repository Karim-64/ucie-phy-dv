`ifndef CLK_GATE_SBTX_BASE_SEQUENCE_SVH
`define CLK_GATE_SBTX_BASE_SEQUENCE_SVH

class clk_gate_sbtx_base_sequence extends uvm_sequence #(clk_gate_sbtx_sequence_item);
  `uvm_object_utils(clk_gate_sbtx_base_sequence)
  `uvm_declare_p_sequencer(clk_gate_sbtx_sequencer)

  clk_gate_sbtx_sequence_item req;

  function new(string name = "clk_gate_sbtx_base_sequence");
    super.new(name);
  endfunction

  task body();
    // TODO: Implement sequence body
    repeat(50)begin
      req = clk_gate_sbtx_sequence_item::type_id::create("req");
      start_item(req);
      if (!req.randomize() ) `uvm_error("SEQ", "Randomization failed")
      finish_item(req); 
      p_sequencer.seqr_aport.write(req);     
    end
  endtask
endclass

`endif // CLK_GATE_SBTX_BASE_SEQUENCE_SVH
