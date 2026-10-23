`ifndef WR_CONTROL_SBTX_SEQUENCE_ITEM_SVH
`define WR_CONTROL_SBTX_SEQUENCE_ITEM_SVH

class wr_control_sbtx_sequence_item #(parameter NC=32) extends uvm_sequence_item;
  `uvm_object_utils(wr_control_sbtx_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic RST_n;
  rand logic lp_cfg_vld;
  rand logic [NC-1:0] lp_cfg;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [2*NC-1:0] Interface_Message;
  logic Data_Marker;
  logic Reg_Acc_Marker;
  logic Reg_Acc_Data_Marker;
  logic Comp_Marker;
  logic Req_Resp_Marker;
  logic Error_Handler;
  logic FIFO_WR;
  logic UIE;

  logic [2*NC-1:0] Interface_Message_exp;
  logic Data_Marker_exp;
  logic Reg_Acc_Marker_exp;
  logic Reg_Acc_Data_Marker_exp;
  logic Comp_Marker_exp;
  logic Req_Resp_Marker_exp;
  logic Error_Handler_exp;
  logic FIFO_WR_exp;
  logic UIE_exp;

  // -------------------------------------------------------------------------
  // Packet-Level Rand Fields  (Used by Sequence to build packets)
  // -------------------------------------------------------------------------
  typedef enum logic [4:0] {
    MEM_RD_32B           = 5'b00000, // 32b Memory Read
    MEM_WR_32B           = 5'b00001, // 32b Memory Write
    CFG_RD_32B           = 5'b00100, // 32b Configuration Read
    CFG_WR_32B           = 5'b00101, // 32b Configuration Write
    MEM_RD_64B           = 5'b01000, // 64b Memory Read
    MEM_WR_64B           = 5'b01001, // 64b Memory Write
    CFG_RD_64B           = 5'b01100, // 64b Configuration Read
    CFG_WR_64B           = 5'b01101, // 64b Configuration Write
    CMPL_NO_DATA         = 5'b10000, // Completion without Data
    CMPL_WITH_32B_DATA   = 5'b10001, // Completion with 32b Data
    MSG_NO_DATA          = 5'b10010, // Message without Data
    CMPL_WITH_64B_DATA   = 5'b11001, // Completion with 64b Data
    MSG_WITH_64B_DATA    = 5'b11011 // Message with 64b Data
  } sideband_opcode_e;

  rand sideband_opcode_e opcode;
  rand logic [2:0]       srcid;
  rand logic [2:0]       dstid;
  rand logic             ep;
  rand logic             cr;
  rand logic [4:0]       tag;
  rand logic [7:0]       be;
  rand logic [23:0]      addr;
  rand logic [2:0]       cmpl_status;
  rand logic [7:0]       msgcode;
  rand logic [7:0]       msgsubcode;
  rand logic [15:0]      msginfo;
  rand logic [63:0]      data_payload;

  // Control Knobs for Error Injection & Idle Cycles
  rand bit               inject_cp_err;
  rand bit               inject_dp_err;
  rand int               num_idle_cycles;

  // Packed 64-bit Header & Data Flag (Calculated automatically in post_randomize)
  logic [63:0]           full_header;
  bit                    has_data;

  // -------------------------------------------------------------------------
  // Chapter 7 Constraints (Soft defaults so any sequence can override them)
  // -------------------------------------------------------------------------
  constraint c_defaults {
    soft RST_n           == 1'b1;
    soft inject_cp_err   == 1'b0;
    soft inject_dp_err   == 1'b0;
    soft num_idle_cycles == 0;
  }

  constraint c_src_dst_ids {
    soft srcid inside {3'b000, 3'b001, 3'b011, 3'b100};
    if (opcode inside {MEM_RD_32B, MEM_WR_32B,
                       CFG_RD_32B, CFG_WR_32B, MEM_RD_64B, MEM_WR_64B,
                       CFG_RD_64B, CFG_WR_64B}) {
      soft dstid inside {3'b010, 3'b100};
    } else if (opcode inside {CMPL_NO_DATA, CMPL_WITH_32B_DATA, CMPL_WITH_64B_DATA}) {
      soft dstid == 3'b101;
    } else {
      soft dstid inside {3'b010, 3'b101, 3'b110, 3'b111};
    }
  }

  constraint c_rar_rules {
    if (opcode inside {MEM_RD_32B, MEM_WR_32B, CFG_RD_32B, CFG_WR_32B}) {
      soft addr[1:0] == 2'b00;
      soft be[7:4]   == 4'b0000;
    }
    if (opcode inside {MEM_RD_64B, MEM_WR_64B, CFG_RD_64B, CFG_WR_64B}) {
      soft addr[2:0] == 3'b000;
    }
    if (opcode inside {MEM_WR_32B,CFG_WR_32B, CMPL_WITH_32B_DATA}) {
      soft data_payload[63:32] == 32'h0000_0000;
    }
  }

  constraint c_msg_encodings {
    if (opcode == MSG_NO_DATA) {
      soft msgcode inside {[8'h01:8'h09], 8'h85, 8'h8A, 8'hA5, 8'hAA, 8'hB5, 8'hBA, 8'hC5, 8'hCA, 8'hD5, 8'hDA, 8'hE5, 8'hEA, 8'hFF};
    }
    if (opcode == MSG_WITH_64B_DATA) {
      soft msgcode inside {8'h01, 8'h02, 8'h81, 8'h85, 8'h8A, 8'hA5, 8'hAA, 8'hB5, 8'hFF};
    }
  }

  // -------------------------------------------------------------------------
  // Post-Randomize: Pack 64-bit Header and Compute Parity (CP & DP)
  // -------------------------------------------------------------------------
  function void post_randomize();
    bit cp_calc, dp_calc;

    has_data = (opcode inside {
      MEM_WR_32B, CFG_WR_32B,
      MEM_WR_64B, CFG_WR_64B,
      CMPL_WITH_32B_DATA, CMPL_WITH_64B_DATA, MSG_WITH_64B_DATA
    });

    full_header = 64'h0;

    if (opcode inside {MEM_RD_32B, MEM_WR_32B, CFG_RD_32B, CFG_WR_32B,
                       MEM_RD_64B, MEM_WR_64B, CFG_RD_64B, CFG_WR_64B}) begin
      full_header[4:0]   = opcode;
      full_header[5]     = ep;
      full_header[21:14] = be;
      full_header[26:22] = tag;
      full_header[31:29] = srcid;
      full_header[55:32] = addr;
      full_header[58:56] = dstid;
      full_header[61]    = cr;
    end else if (opcode inside {CMPL_NO_DATA, CMPL_WITH_32B_DATA, CMPL_WITH_64B_DATA}) begin
      full_header[4:0]   = opcode;
      full_header[5]     = ep;
      full_header[21:14] = be;
      full_header[26:22] = tag;
      full_header[31:29] = srcid;
      full_header[34:32] = cmpl_status;
      full_header[58:56] = dstid;
      full_header[61]    = cr;
    end else begin
      full_header[4:0]   = opcode;
      full_header[21:14] = msgcode;
      full_header[31:29] = srcid;
      full_header[39:32] = msgsubcode;
      full_header[55:40] = msginfo;
      full_header[58:56] = dstid;
    end

    if (!has_data) begin
      data_payload = 64'h0;
      dp_calc      = 1'b0;
    end else begin
      dp_calc      = ^data_payload;
    end
    cp_calc = ^full_header[61:0];

    // Assign parity (or flip bit if error injection is enabled)
    full_header[62] = cp_calc ^ inject_cp_err;
    full_header[63] = dp_calc ^ inject_dp_err;
  endfunction

  // Helper to manually edit full_header bits after randomize()
  function void recompute_parity();
    full_header[62] = (^full_header[61:0]) ^ inject_cp_err;
    full_header[63] = (has_data ? (^data_payload) : 1'b0) ^ inject_dp_err;
  endfunction

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "wr_control_sbtx_sequence_item");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("wr_control_sbtx_seq_item: RST_n=%0b lp_cfg_vld=%0b lp_cfg=0x%0h Interface_Message=0x%0h Data_Marker=%0b Reg_Acc_Marker=%0b Reg_Acc_Data_Marker=%0b Comp_Marker=%0b Req_Resp_Marker=%0b Error_Handler=%0b FIFO_WR=%0b UIE=%0b",
      RST_n, lp_cfg_vld, lp_cfg, Interface_Message, Data_Marker, Reg_Acc_Marker, Reg_Acc_Data_Marker, Comp_Marker, Req_Resp_Marker, Error_Handler, FIFO_WR, UIE);
  endfunction

endclass

`endif // WR_CONTROL_SBTX_SEQUENCE_ITEM_SVH
