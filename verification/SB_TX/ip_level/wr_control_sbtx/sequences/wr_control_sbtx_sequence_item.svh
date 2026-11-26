`ifndef WR_CONTROL_SBTX_SEQUENCE_ITEM_SVH
`define WR_CONTROL_SBTX_SEQUENCE_ITEM_SVH

class wr_control_sbtx_sequence_item #(parameter NC=32) extends uvm_sequence_item;
  `uvm_object_param_utils(wr_control_sbtx_sequence_item #(NC))

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
  // Packet-Level Rand Fields (Uses sb_opcode_e & msgcodes from packets_pkg)
  // -------------------------------------------------------------------------
  rand sb_opcode_e       opcode;
  rand bit               use_raw_opcode;
  rand logic [4:0]       raw_opcode;
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
  // Default Soft Constraints (Overridable by any test/sequence)
  // -------------------------------------------------------------------------
  constraint c_defaults {
    soft RST_n          == 1'b1;
    soft lp_cfg_vld     == 1'b1;
    soft use_raw_opcode == 1'b0;
  }

  constraint c_default_no_err {
    soft inject_cp_err == 1'b0;
    soft inject_dp_err == 1'b0;
  }

  constraint c_default_no_idle {
    soft num_idle_cycles == 0;
  }

  constraint c_idle_bounds {
    solve opcode before srcid, dstid, addr, be, msgcode, data_payload;
    num_idle_cycles inside {[0:10]};
  }

  constraint c_src_dst_ids {
    soft srcid inside {3'b001, 3'b010};
    if (opcode inside {rar_packets}) {
      soft dstid inside {3'b010, 3'b100};
    } else if (opcode inside {comp_packets}) {
      soft dstid == 3'b101;
    } else {
      soft dstid inside {3'b010, 3'b101, 3'b110, 3'b111};
    }
  }

  constraint c_rar_rules {
    if (opcode inside {SB_MEM_RD_32B, SB_MEM_WR_32B, SB_CFG_RD_32B, SB_CFG_WR_32B}) {
      soft addr[1:0] == 2'b00;
      soft be[7:4]   == 4'b0000;
    }
    if (opcode inside {SB_MEM_RD_64B, SB_MEM_WR_64B, SB_CFG_RD_64B, SB_CFG_WR_64B}) {
      soft addr[2:0] == 3'b000;
    }
    if (opcode inside {SB_MEM_WR_32B, SB_CFG_WR_32B, SB_CMPL_WITH_32B_DATA}) {
      soft data_payload[63:32] == 32'h0000_0000;
    }
  }

  constraint c_msg_encodings {
    if (opcode inside {msg_packets}) {
      soft msgcode inside {req_resp_msgcodes, non_req_resp_msgcodes};
    }
  }

  // -------------------------------------------------------------------------
  // Post-Randomize: Pack 64-bit Header directly from class fields & Compute Parity
  // -------------------------------------------------------------------------
  function void post_randomize();
    bit         cp_calc, dp_calc;
    logic [4:0] eff_op;

    eff_op   = use_raw_opcode ? raw_opcode : opcode;
    has_data = (!use_raw_opcode) && (opcode inside {data_packets});

    full_header = 64'h0;

    if (!use_raw_opcode && (opcode inside {rar_packets})) begin
      full_header[4:0]   = eff_op;
      full_header[5]     = ep;
      full_header[21:14] = be;
      full_header[26:22] = tag;
      full_header[31:29] = srcid;
      full_header[55:32] = addr;
      full_header[58:56] = dstid;
      full_header[61]    = cr;
    end else if (!use_raw_opcode && (opcode inside {comp_packets})) begin
      full_header[4:0]   = eff_op;
      full_header[5]     = ep;
      full_header[21:14] = be;
      full_header[26:22] = tag;
      full_header[31:29] = srcid;
      full_header[34:32] = cmpl_status;
      full_header[58:56] = dstid;
      full_header[61]    = cr;
    end else begin
      full_header[4:0]   = eff_op;
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

    full_header[62] = cp_calc ^ inject_cp_err;
    full_header[63] = dp_calc ^ inject_dp_err;
  endfunction

  function void recompute_parity();
    full_header[62] = (^full_header[61:0]) ^ inject_cp_err;
    full_header[63] = (has_data ? (^data_payload) : 1'b0) ^ inject_dp_err;
  endfunction

  function new(string name = "wr_control_sbtx_sequence_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf(
      "wr_control_sbtx_seq_item: RST_n=%0b lp_cfg_vld=%0b lp_cfg=0x%08h Interface_Message=0x%016h Data_Marker=%0b Reg_Acc_Marker=%0b Reg_Acc_Data_Marker=%0b Comp_Marker=%0b Req_Resp_Marker=%0b Error_Handler=%0b FIFO_WR=%0b UIE=%0b",
      RST_n, lp_cfg_vld, lp_cfg, Interface_Message, Data_Marker, Reg_Acc_Marker,
      Reg_Acc_Data_Marker, Comp_Marker, Req_Resp_Marker, Error_Handler, FIFO_WR, UIE
    );
  endfunction

endclass

`endif // WR_CONTROL_SBTX_SEQUENCE_ITEM_SVH
