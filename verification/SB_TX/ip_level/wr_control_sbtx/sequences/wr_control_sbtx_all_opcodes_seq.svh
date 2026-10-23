class wr_control_sbtx_all_opcodes_seq extends wr_control_sbtx_base_sequence;
  `uvm_object_utils(wr_control_sbtx_all_opcodes_seq)
  `uvm_declare_p_sequencer(wr_control_sbtx_sequencer)


  bit use_idle_cycles = 1; // Set to 1 for Idle in-between, 0 for Back-to-Back

  function new(string name = "wr_control_sbtx_all_opcodes_seq");
    super.new(name);
  endfunction

  virtual task body();
    wr_control_sbtx_sequence_item transaction;
    //import enum using "::"
    wr_control_sbtx_sequence_item#()::sideband_opcode_e current_op;

    transaction = wr_control_sbtx_sequence_item#()::type_id::create("transaction");
    send_reset(1);

    current_op = current_op.first();
    for (int i = 0; i < current_op.num(); i++) begin
      if (!transaction.randomize() with {
          opcode          == current_op;
          inject_cp_err   == 1'b0;
          inject_dp_err   == 1'b0;
          num_idle_cycles == (use_idle_cycles ? $urandom_range(1, 2) : 0);
      }) `uvm_error("SEQ", "Randomization failed in all_opcodes_seq")

      send_packet(transaction);
      current_op = current_op.next();
    end

  endtask
endclass