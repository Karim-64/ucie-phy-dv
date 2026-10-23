`ifndef WR_CONTROL_SBTX_WEIGHTED_SEQUENCE_ITEM_SVH
`define WR_CONTROL_SBTX_WEIGHTED_SEQUENCE_ITEM_SVH

class wr_control_sbtx_weighted_sequence_item #(parameter NC=32) extends wr_control_sbtx_sequence_item;
  `uvm_object_param_utils(wr_control_sbtx_weighted_sequence_item #(NC))

  constraint c_weighted_opcodes {
    opcode dist {
      MEM_RD_32B         := 5,
      CFG_RD_32B         := 5,
      MEM_RD_64B         := 5,
      CFG_RD_64B         := 5,

      MEM_WR_32B         := 5,
      CFG_WR_32B         := 5,
      MEM_WR_64B         := 5,
      CFG_WR_64B         := 5,

      CMPL_NO_DATA       := 8,
      CMPL_WITH_32B_DATA := 6,
      CMPL_WITH_64B_DATA := 6,

      MSG_NO_DATA        := 15,
      MSG_WITH_64B_DATA  := 15
    };
  }

  constraint c_rst_n {
    RST_n dist {
      1:=95,
      0:=5
    };
  }
  constraint c_lp_cfg_vld {
  lp_cfg_vld dist { 1 := 90, 0 := 10 };
}

  // -------------------------------------------------------------------------
  //  Weighted MsgCode Distribution (Specifically targets subscriber bins!)
  //    Ensures msgcode = 7, 8, 9, LinkMgmt, LTSM, and non-Req/Resp codes hit
  // -------------------------------------------------------------------------
constraint c_weighted_msgcodes {
    if (opcode == MSG_NO_DATA) {
      msgcode dist {
        8'h07                                      := 15, // ParityFeature.Req
        8'h08                                      := 15, // ParityFeature.Ack/Nak
        8'h09                                      := 15, // ErrMsg
        [8'h01:8'h06]                              :/ 20, // LinkMgmt Req/Rsp
        8'h85, 8'h8A, 8'h91, 8'h95, 8'h9A,
        8'hA5, 8'hAA, 8'hB5, 8'hBA, 8'hC5,
        8'hCA, 8'hD5, 8'hDA, 8'hE5, 8'hEA          :/ 25, // LTSM Req/Rsp
        8'h00, 8'hFF                               :/ 5,  // Nop.Crd & Vendor Defined
        [8'h00:8'hFF]                              :/ 5   // All other possible 8-bit values (low distribution)
      };
    }

    if (opcode == MSG_WITH_64B_DATA) {
      msgcode dist {
        8'h01, 8'h02                               :/ 25, // AdvCap / FinCap
        8'h85, 8'h8A, 8'hA5, 8'hAA, 8'hB5          :/ 50, // LTSM with Data (Req_Resp=1)
        8'h81, 8'hFF                               :/ 20, // Non-Req/Resp Msg with Data (Req_Resp=0)
        [8'h00:8'hFF]                              :/ 5   // All other possible 8-bit values (low distribution)
      };
    }
  }

  constraint c_weighted_dstid {
    if (opcode inside {MEM_RD_32B, MEM_WR_32B,
                       CFG_RD_32B, CFG_WR_32B, MEM_RD_64B, MEM_WR_64B,
                       CFG_RD_64B, CFG_WR_64B}) {
      dstid dist {
        3'b010 := 50, // Local PHY RAR
        3'b100 := 50  // Remote Die RAR
      };
    }
  }

  constraint c_weighted_idle_and_errors {
    // 70% Back-to-Back (0 idle cycles), 30% with 1 to 3 idle cycles between packets
    num_idle_cycles dist {
      0     := 70,
      [1:3] := 30
    };

    // 85% Error-Free, ~15% Control/Data Parity Error Injection (triggers UIE & Error_Handler)
    inject_cp_err dist {
      1'b0 := 75,
      1'b1 := 25
    };
    inject_dp_err dist {
      1'b0 := 75,
      1'b1 := 25
    };
  }

  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "wr_control_sbtx_weighted_sequence_item");
    super.new(name);
    c_defaults.constraint_mode(0);

  endfunction

endclass

`endif // WR_CONTROL_SBTX_WEIGHTED_SEQUENCE_ITEM_SVH