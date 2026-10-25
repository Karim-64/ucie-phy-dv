`ifndef GRAY_SYNCHRONIZER_SBTX_RANDOM_SEQ_SVH
`define GRAY_SYNCHRONIZER_SBTX_RANDOM_SEQ_SVH

class gray_synchronizer_sbtx_random_seq extends uvm_sequence #(gray_synchronizer_sbtx_sequence_item);
    `uvm_object_utils(gray_synchronizer_sbtx_random_seq)
    `uvm_declare_p_sequencer(gray_synchronizer_sbtx_sequencer)

    int num_trans = 50;

    function new(string name = "gray_synchronizer_sbtx_random_seq");
        super.new(name);
    endfunction

    virtual task body();
        repeat (num_trans) begin
            req = gray_synchronizer_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            assert(req.randomize());
            finish_item(req);
            p_sequencer.seqr_aport.write(req);
        end
    endtask

    
endclass


`endif // GRAY_SYNCHRONIZER_SBTX_BASE_SEQUENCE_SVH
