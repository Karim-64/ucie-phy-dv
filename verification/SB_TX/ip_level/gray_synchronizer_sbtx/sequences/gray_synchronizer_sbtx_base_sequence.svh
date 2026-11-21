`ifndef GRAY_SYNCHRONIZER_SBTX_BASE_SEQUENCE_SVH
`define GRAY_SYNCHRONIZER_SBTX_BASE_SEQUENCE_SVH

class gray_synchronizer_sbtx_base_sequence extends uvm_sequence #(gray_synchronizer_sbtx_sequence_item);
  `uvm_object_utils(gray_synchronizer_sbtx_base_sequence)
  `uvm_declare_p_sequencer(gray_synchronizer_sbtx_sequencer)

  gray_synchronizer_sbtx_error_injection err_seq;
  gray_synchronizer_sbtx_exhaustive_seq extv_seq;
  gray_synchronizer_sbtx_random_seq rand_seq;


  function new(string name = "gray_synchronizer_sbtx_base_sequence");
    super.new(name);
  endfunction

  task pre_body();
    err_seq = gray_synchronizer_sbtx_error_injection::type_id::create("err_seq");
    extv_seq = gray_synchronizer_sbtx_exhaustive_seq::type_id::create("extv_seq");
    rand_seq = gray_synchronizer_sbtx_random_seq::type_id::create("rand_seq");
  endtask

  task body();
    gray_synchronizer_sbtx_sequence_item req;

    repeat (2) begin
      req = gray_synchronizer_sbtx_sequence_item::type_id::create("req");
      start_item(req);
      req.RST_n = 'b0;
      req.Async_Data = 'b0;
      finish_item(req);
      p_sequencer.seqr_aport.write(req);
    end


    extv_seq.start(p_sequencer);
    rand_seq.start(p_sequencer);
    err_seq.start(p_sequencer);
  endtask
endclass

`endif // GRAY_SYNCHRONIZER_SBTX_BASE_SEQUENCE_SVH
