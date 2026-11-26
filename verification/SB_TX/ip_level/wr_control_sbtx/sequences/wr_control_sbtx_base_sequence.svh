`ifndef WR_CONTROL_SBTX_BASE_SEQUENCE_SVH
`define WR_CONTROL_SBTX_BASE_SEQUENCE_SVH

class wr_control_sbtx_base_sequence extends uvm_sequence #(wr_control_sbtx_sequence_item);
  `uvm_object_utils(wr_control_sbtx_base_sequence)
  `uvm_declare_p_sequencer(wr_control_sbtx_sequencer)

  function new(string name = "wr_control_sbtx_base_sequence");
    super.new(name);
  endfunction

  // Drive a single LCLK cycle onto the DUT via sequencer + monitor TLM port
  virtual task drive_cycle(logic rst_n, logic vld, logic [31:0] cfg_data);
    wr_control_sbtx_sequence_item cycle_req;
    cycle_req = wr_control_sbtx_sequence_item#()::type_id::create("cycle_req");
    start_item(cycle_req);
    cycle_req.RST_n      = rst_n;
    cycle_req.lp_cfg_vld = vld;
    cycle_req.lp_cfg     = cfg_data;
    finish_item(cycle_req);
    p_sequencer.seqr_aport.write(cycle_req);
  endtask

  // Assert active-low reset for reset_cycles clocks
  virtual task send_reset(int reset_cycles = 2);
    repeat (reset_cycles) begin
      drive_cycle(1'b0, 1'b0, 32'h0000_0000);
    end
  endtask

  // Flush trailing pipeline cycles so 4-phase Header+Data outputs complete before test ends
  virtual task drain_pipeline(int drain_cycles = 3);
    repeat (drain_cycles) begin
      drive_cycle(1'b1, 1'b0, 32'h0000_0000);
    end
  endtask

  // Drive a randomized wr_control_sbtx_sequence_item (2-phase or 4-phase + optional idle gap)
  virtual task send_packet(wr_control_sbtx_sequence_item pkt, logic [31:0] idle_bus_val = 32'h0000_0000);
    // 1. Header Phase 0 & Phase 1
    drive_cycle(1'b1, 1'b1, pkt.full_header[31:0]);
    drive_cycle(1'b1, 1'b1, pkt.full_header[63:32]);

    // 2. Data Phase 0 & Phase 1 (if packet carries 64-bit data payload)
    if (pkt.has_data) begin
      drive_cycle(1'b1, 1'b1, pkt.data_payload[31:0]);
      drive_cycle(1'b1, 1'b1, pkt.data_payload[63:32]);
    end

    // 3. Inter-packet idle cycles (num_idle_cycles == 0 -> immediate back-to-back)
    repeat (pkt.num_idle_cycles) begin
      drive_cycle(1'b1, 1'b0, idle_bus_val);
    end
  endtask

  // Legacy helper kept for backward compatibility
  task send_sideband_packet(logic [4:0] opcode, logic [7:0] msgcode, bit has_data);
    logic [63:0] header;
    logic [63:0] data_payload;
    bit          cp_calc;
    bit          dp_calc;

    header        = '0;
    header[4:0]   = opcode;
    header[21:14] = msgcode;

    if (has_data) begin
      if (opcode inside {SB_MEM_WR_32B, SB_CFG_WR_32B, SB_CMPL_WITH_32B_DATA})
        data_payload = 64'h0000_0000_CAFE_BABE;
      else
        data_payload = 64'hDEAD_BEEF_CAFE_BABE;
      dp_calc = ^data_payload;
    end else begin
      data_payload = 64'h0;
      dp_calc      = 1'b0;
    end

    cp_calc    = ^header[61:0];
    header[62] = cp_calc;
    header[63] = dp_calc;

    drive_cycle(1'b1, 1'b1, header[31:0]);
    drive_cycle(1'b1, 1'b1, header[63:32]);
    if (has_data) begin
      drive_cycle(1'b1, 1'b1, data_payload[31:0]);
      drive_cycle(1'b1, 1'b1, data_payload[63:32]);
    end
    drive_cycle(1'b1, 1'b0, 32'h0);
  endtask

  virtual task body();
    `uvm_info("SEQ", "Starting wr_control_sbtx_base_sequence...", UVM_LOW)
    send_reset(2);

    send_sideband_packet(SB_MSG_NO_DATA,       SB_REQ_TESTS,  1'b0);
    send_sideband_packet(SB_MSG_WITH_64B_DATA, SB_RESP_TESTS, 1'b1);
    send_sideband_packet(SB_CFG_WR_64B,        SB_NOP_CREDIT, 1'b1);
    send_sideband_packet(SB_CMPL_NO_DATA,      SB_NOP_CREDIT, 1'b0);

    drain_pipeline(3);
    `uvm_info("SEQ", "Finished wr_control_sbtx_base_sequence.", UVM_LOW)
  endtask
endclass

`endif // WR_CONTROL_SBTX_BASE_SEQUENCE_SVH
