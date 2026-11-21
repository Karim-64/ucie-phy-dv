`ifndef FIFO_SBTX_SEQUENCE_ITEM_SVH
`define FIFO_SBTX_SEQUENCE_ITEM_SVH

class fifo_sbtx_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(fifo_sbtx_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic rst_n;
  rand logic wr_en;
  rand logic rd_en;
  rand logic UIE;
  rand logic [FIFO_WIDTH-1:0] data_in;
  rand logic Data_Marker;
  rand logic Reg_Acc_Marker;
  rand logic Reg_Acc_Data_Marker;
  rand logic Comp_Marker;
  rand logic Req_Resp_Marker;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [FIFO_WIDTH-1:0] data_out;
  logic Data_Marker_Out;
  logic Reg_Acc_Marker_Out;
  logic Reg_Acc_Data_Marker_Out;
  logic Comp_Marker_Out;
  logic empty;
  logic rd_ack;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "fifo_sbtx_sequence_item");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("fifo_sbtx_seq_item: rst_n=%0b wr_en=%0b rd_en=%0b UIE=%0b data_in=0x%0h Data_Marker=%0b Reg_Acc_Marker=%0b Reg_Acc_Data_Marker=%0b Comp_Marker=%0b Req_Resp_Marker=%0b data_out=0x%0h Data_Marker_Out=%0b Reg_Acc_Marker_Out=%0b Reg_Acc_Data_Marker_Out=%0b Comp_Marker_Out=%0b empty=%0b rd_ack=%0b",
      rst_n, wr_en, rd_en, UIE, data_in, Data_Marker, Reg_Acc_Marker, Reg_Acc_Data_Marker, Comp_Marker, Req_Resp_Marker, data_out, Data_Marker_Out, Reg_Acc_Marker_Out, Reg_Acc_Data_Marker_Out, Comp_Marker_Out, empty, rd_ack);
  endfunction

endclass

`endif // FIFO_SBTX_SEQUENCE_ITEM_SVH
