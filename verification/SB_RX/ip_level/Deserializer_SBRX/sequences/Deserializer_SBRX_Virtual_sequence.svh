`ifndef DESERIALIZER_SBRX_VIRTUAL_SEQUENCE_SVH
`define DESERIALIZER_SBRX_VIRTUAL_SEQUENCE_SVH

class Deserializer_SBRX_Virtual_sequence extends uvm_sequence;
    `uvm_object_utils(Deserializer_SBRX_Virtual_sequence)
    `uvm_declare_p_sequencer(Deserializer_SBRX_Virtual_sequencer)
    Deserializer_SBRX_base_sequence base_seq;
    Deserializer_SBRX_base_sequence base_seq2;

    function new(string name = "Deserializer_SBRX_Virtual_sequence");
        super.new(name);
    endfunction

    task pre_body();
        base_seq   = Deserializer_SBRX_base_sequence::type_id::create("base_seq");
        base_seq2  = Deserializer_SBRX_base_sequence::type_id::create("base_seq2");
    endtask

    task body();
        fork
            begin
                base_seq.start(p_sequencer.seqr);
            end
            begin
                base_seq2.start(p_sequencer.seqr2);
            end
        join
    endtask
endclass

`endif // DESERIALIZER_SBRX_VIRTUAL_SEQUENCE_SVH