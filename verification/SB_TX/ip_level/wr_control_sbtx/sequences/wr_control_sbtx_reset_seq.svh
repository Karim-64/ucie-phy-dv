`ifndef WR_CONTROL_SBTX_RESET_SEQ_SVH
`define WR_CONTROL_SBTX_RESET_SEQ_SVH

// TC_01: Power-on reset, reset while lp_cfg_vld=1, and immediate valid packet recovery
class wr_control_sbtx_reset_seq extends wr_control_sbtx_base_sequence;
  `uvm_object_utils(wr_control_sbtx_reset_seq)
  `uvm_declare_p_sequencer(wr_control_sbtx_sequencer)

  function new(string name = "wr_control_sbtx_reset_seq");
    super.new(name);
  endfunction

  virtual task body();
    wr_control_sbtx_sequence_item pkt;
    pkt = wr_control_sbtx_sequence_item#()::type_id::create("pkt");

    `uvm_info(get_type_name(), "Starting TC_01 Reset & Initialization Sequence", UVM_LOW)

    // 1. Power-on multi-cycle reset with idle bus
    send_reset(4);

    // 2. Assert lp_cfg_vld = 1 with non-zero data while RST_n = 0 (must be ignored)
    drive_cycle(1'b0, 1'b1, 32'hFFFF_FFFF);
    drive_cycle(1'b0, 1'b1, 32'hA5A5_5A5A);

    // 3. Immediate valid 2-phase packet on the very first cycle RST_n releases
    if (!pkt.randomize() with {
      opcode          == SB_MEM_RD_64B;
      inject_cp_err   == 1'b0;
      inject_dp_err   == 1'b0;
      num_idle_cycles == 1;
    }) `uvm_error(get_type_name(), "Randomization failed")
    send_packet(pkt);

    // 4. Immediate valid 4-phase packet to confirm full pipeline readiness
    if (!pkt.randomize() with {
      opcode          == SB_MEM_WR_64B;
      inject_cp_err   == 1'b0;
      inject_dp_err   == 1'b0;
      num_idle_cycles == 2;
    }) `uvm_error(get_type_name(), "Randomization failed")
    send_packet(pkt);

    drain_pipeline(3);
  endtask
endclass

`endif // WR_CONTROL_SBTX_RESET_SEQ_SVH

