`ifndef GRAY_SYNCHRONIZER_SBTX_ERROR_INJECTION_SVH
`define GRAY_SYNCHRONIZER_SBTX_ERROR_INJECTION_SVH

class gray_synchronizer_sbtx_error_injection extends uvm_sequence #(gray_synchronizer_sbtx_sequence_item);
  `uvm_object_utils(gray_synchronizer_sbtx_error_injection)
  `uvm_declare_p_sequencer(gray_synchronizer_sbtx_sequencer)

  int num_transitions = 300;

  function new(string name = "gray_synchronizer_sbtx_error_injection");
    super.new(name);
  endfunction

  task body();
    // TODO: Implement sequence body
        bit [1:0] prev_data = 2'b00;

        repeat (num_transitions) begin
            req = gray_synchronizer_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            
            // Force input to be the direct bitwise inversion of the previous value 
            // (e.g., 00 -> 11, or 01 -> 10) to test maximum toggle stress.
            assert(req.randomize() with {
                Async_Data == ~local::prev_data;
            });
            
            finish_item(req);
            prev_data = req.Async_Data;
            p_sequencer.seqr_aport.write(req);
        end
  endtask
endclass

`endif // GRAY_SYNCHRONIZER_SBTX_ERROR_INJECTION_SVH
