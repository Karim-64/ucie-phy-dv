`ifndef PACKETS_PKG_SV
`define PACKETS_PKG_SV
`timescale 1ns/1ps

package packets_pkg;
  // =========================================================================
  // Valid D2D Sideband Opcodes (13 D2D-supported opcodes; excludes DMS & MPM)
  // =========================================================================
  typedef enum logic [4:0] {
    // 32-bit Register Access Requests (RAR)
    SB_MEM_RD_32B         = 5'b00000, // 32b Memory Read (2 phases)
    SB_MEM_WR_32B         = 5'b00001, // 32b Memory Write (4 phases)
    SB_CFG_RD_32B         = 5'b00100, // 32b Configuration Read (2 phases)
    SB_CFG_WR_32B         = 5'b00101, // 32b Configuration Write (4 phases)

    // 64-bit Register Access Requests (RAR)
    SB_MEM_RD_64B         = 5'b01000, // 64b Memory Read (2 phases)
    SB_MEM_WR_64B         = 5'b01001, // 64b Memory Write (4 phases)
    SB_CFG_RD_64B         = 5'b01100, // 64b Configuration Read (2 phases)
    SB_CFG_WR_64B         = 5'b01101, // 64b Configuration Write (4 phases)

    // Completions
    SB_CMPL_NO_DATA       = 5'b10000, // Completion Without Data (2 phases)
    SB_CMPL_WITH_32B_DATA = 5'b10001, // Completion With 32b Data (4 phases, upper 32b padded 0)
    SB_CMPL_WITH_64B_DATA = 5'b11001, // Completion With 64b Data (4 phases)

    // Sideband Messages
    SB_MSG_NO_DATA        = 5'b10010, // Message Without Data (2 phases)
    SB_MSG_WITH_64B_DATA  = 5'b11011  // Message With 64b Data (4 phases)
  } sb_opcode_e;

  sb_opcode_e rar_packets  [8]  = '{SB_MEM_RD_32B , SB_MEM_WR_32B , SB_CFG_RD_32B , SB_CFG_WR_32B , SB_MEM_RD_64B , SB_MEM_WR_64B , SB_CFG_RD_64B , SB_CFG_WR_64B};
  sb_opcode_e comp_packets [3]  = '{SB_CMPL_NO_DATA , SB_CMPL_WITH_32B_DATA , SB_CMPL_WITH_64B_DATA};
  sb_opcode_e msg_packets  [2]  = '{SB_MSG_NO_DATA , SB_MSG_WITH_64B_DATA};
  sb_opcode_e data_packets [7]  = '{SB_MEM_WR_32B , SB_CFG_WR_32B , SB_MEM_WR_64B , SB_CFG_WR_64B , SB_CMPL_WITH_32B_DATA , SB_CMPL_WITH_64B_DATA , SB_MSG_WITH_64B_DATA};

  // =========================================================================
  // Req/Resp Message Codes (all *_req / *_resp from Universal_pkg::msgcode_e)
  // =========================================================================
  typedef enum logic [7:0] {
    SB_RDI_LINK_MGMT_REQ   = 8'h01,
    SB_RDI_LINK_MGMT_RESP  = 8'h02,
    SB_D2D0_LINK_MGMT_REQ  = 8'h03,
    SB_D2D0_LINK_MGMT_RESP = 8'h04,
    SB_D2D1_LINK_MGMT_REQ  = 8'h05,
    SB_D2D1_LINK_MGMT_RESP = 8'h06,
    SB_D2D_PARITY_FEAT_REQ = 8'h07,
    SB_PARITY_FEAT_ACK     = 8'h08,
    SB_REQ_TESTS           = 8'h85,
    SB_RESP_TESTS          = 8'h8A,
    SB_REQ_SB              = 8'h95,
    SB_RESP_SB             = 8'h9A,
    SB_REQ_MBINIT          = 8'hA5,
    SB_RESP_MBINIT         = 8'hAA,
    SB_REQ_MBTRAIN         = 8'hB5,
    SB_RESP_MBTRAIN        = 8'hBA,
    SB_PHYRETRAIN_REQ      = 8'hC5,
    SB_PHYRETRAIN_RESP     = 8'hCA,
    SB_RECAL_REQ           = 8'hD5,
    SB_RECAL_RESP          = 8'hDA,
    SB_TRAINERROR_REQ      = 8'hE5,
    SB_TRAINERROR_RESP     = 8'hEA
  } req_resp_msgcode_e;

  // =========================================================================
  // Non-Req/Resp Message Codes (all remaining codes from msgcode_e)
  // =========================================================================
  typedef enum logic [7:0] {
    SB_NOP_CREDIT          = 8'h00,
    SB_ERR_MSG             = 8'h09,
    SB_SWEEP_DONE          = 8'h81,
    SB_SB_DONE             = 8'h91,
    SB_VENDOR_DEFINED      = 8'hFF
  } non_req_resp_msgcode_e;

  req_resp_msgcode_e d2d_req_resp_msgcodes [5] = '{
    SB_D2D0_LINK_MGMT_REQ, SB_D2D0_LINK_MGMT_RESP,
    SB_D2D1_LINK_MGMT_REQ, SB_D2D1_LINK_MGMT_RESP,
    SB_D2D_PARITY_FEAT_REQ
  };

  req_resp_msgcode_e req_resp_msgcodes [22] = '{
    SB_RDI_LINK_MGMT_REQ,   SB_RDI_LINK_MGMT_RESP,
    SB_D2D0_LINK_MGMT_REQ,  SB_D2D0_LINK_MGMT_RESP,
    SB_D2D1_LINK_MGMT_REQ,  SB_D2D1_LINK_MGMT_RESP,
    SB_D2D_PARITY_FEAT_REQ, SB_PARITY_FEAT_ACK,
    SB_REQ_TESTS,           SB_RESP_TESTS,
    SB_REQ_SB,              SB_RESP_SB,
    SB_REQ_MBINIT,          SB_RESP_MBINIT,
    SB_REQ_MBTRAIN,         SB_RESP_MBTRAIN,
    SB_PHYRETRAIN_REQ,      SB_PHYRETRAIN_RESP,
    SB_RECAL_REQ,           SB_RECAL_RESP,
    SB_TRAINERROR_REQ,      SB_TRAINERROR_RESP
  };

  non_req_resp_msgcode_e non_req_resp_msgcodes [5] = '{
    SB_NOP_CREDIT, SB_ERR_MSG, SB_SWEEP_DONE, SB_SB_DONE, SB_VENDOR_DEFINED
  };

  // =========================================================================
  // RAR Header Phase Structs (32 bits each)
  // =========================================================================
  typedef struct packed {
    logic [2:0] srcid;      // [31:29] Source ID
    logic [1:0] rsvd1;      // [28:27] Reserved
    logic [4:0] tag;        // [26:22] Tag
    logic [7:0] be;         // [21:14] Byte Enables
    logic [8:0] rsvd0;      // [13:5]  Reserved
    sb_opcode_e opcode;     // [4:0]   Opcode
  } sb_rar_hdr_ph0_s;

  typedef struct packed {
    logic        dp;        // [31]    Data Parity (Header[63])
    logic        cp;        // [30]    Control Parity (Header[62])
    logic [2:0]  rsvd;      // [29:27] Reserved (Header[61:59])
    logic [2:0]  dstid;     // [26:24] Destination ID (Header[58:56])
    logic [23:0] addr;      // [23:0]  Register Address (Header[55:32])
  } sb_rar_hdr_ph1_s;

  // =========================================================================
  // Message Header Phase Structs (32 bits each)
  // =========================================================================
  typedef struct packed {
    logic [2:0] srcid;      // [31:29] Source ID
    logic [6:0] rsvd1;      // [28:22] Reserved
    logic [7:0] msgcode;    // [21:14] Message Code
    logic [8:0] rsvd0;      // [13:5]  Reserved
    sb_opcode_e opcode;     // [4:0]   Opcode
  } sb_msg_hdr_ph0_s;

  typedef struct packed {
    logic        dp;        // [31]    Data Parity (Header[63])
    logic        cp;        // [30]    Control Parity (Header[62])
    logic [2:0]  rsvd;      // [29:27] Reserved (Header[61:59])
    logic [2:0]  dstid;     // [26:24] Destination ID (Header[58:56])
    logic [15:0] msginfo;   // [23:8]  Message Info (Header[55:40])
    logic [7:0]  msgsubcode;// [7:0]   Message Subcode (Header[39:32])
  } sb_msg_hdr_ph1_s;

  // =========================================================================
  // Completion Header Phase Structs (32 bits each)
  // =========================================================================
  typedef struct packed {
    logic [2:0] srcid;      // [31:29] Source ID
    logic [1:0] rsvd1;      // [28:27] Reserved
    logic [4:0] tag;        // [26:22] Tag
    logic [7:0] be;         // [21:14] Byte Enables / Reserved
    logic [8:0] rsvd0;      // [13:5]  Reserved
    sb_opcode_e opcode;     // [4:0]   Opcode
  } sb_cmpl_hdr_ph0_s;

  typedef struct packed {
    logic        dp;        // [31]    Data Parity (Header[63])
    logic        cp;        // [30]    Control Parity (Header[62])
    logic [2:0]  rsvd;      // [29:27] Reserved (Header[61:59])
    logic [2:0]  dstid;     // [26:24] Destination ID (Header[58:56])
    logic [20:0] rsvd_hi;   // [23:3]  Reserved (Header[55:35])
    logic [2:0]  status;    // [2:0]   Completion Status (Header[34:32])
  } sb_cmpl_hdr_ph1_s;
  
endpackage

`endif // PACKETS_PKG_SV