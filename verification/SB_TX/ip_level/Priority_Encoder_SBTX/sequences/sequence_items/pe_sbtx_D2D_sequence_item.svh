`ifndef PE_SBTX_D2D_SEQUENCE_ITEM_SVH
`define PE_SBTX_D2D_SEQUENCE_ITEM_SVH

class pe_sbtx_D2D_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(pe_sbtx_D2D_sequence_item)

  // Stimulus fields (driven to D2D interface)
  rand logic                  en;
  rand logic                  data_marker;
  rand logic                  comp_marker;
  rand logic [DATA_WIDTH-1:0] data;

  // Response fields (sampled from D2D interface)
  logic                       resend_req;

  function new(string name = "pe_sbtx_D2D_sequence_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("pe_sbtx_D2D_seq_item: en=%0b data_marker=%0b comp_marker=%0b data=0x%0h resend_req=%0b",
      en, data_marker, comp_marker, data, resend_req);
  endfunction
endclass

`endif // PE_SBTX_D2D_SEQUENCE_ITEM_SVH
