`ifndef MEM_SEQUENCE_ITEM_SVH
`define MEM_SEQUENCE_ITEM_SVH

class mem_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(mem_sequence_item)

  // -------------------------------------------------------------------------
  //  Stimulus fields (directly driven to the DUT) - declared rand
  // -------------------------------------------------------------------------
  rand logic rst;
  rand logic cs;
  rand logic we;
  rand logic [ADDRESS_WIDTH-1:0] addr;
  rand logic [DATA_WIDTH-1:0] data_in;
  // -------------------------------------------------------------------------
  //  Response fields (sampled from the DUT) - NOT rand
  // -------------------------------------------------------------------------
  logic [DATA_WIDTH-1:0] data_out;
  logic valid_out;
  // -------------------------------------------------------------------------
  //  Constructor
  // -------------------------------------------------------------------------
  function new(string name = "mem_sequence_item");
    super.new(name);
  endfunction

  // -------------------------------------------------------------------------
  //  convert2string - human-readable representation for logs / debug
  // -------------------------------------------------------------------------
  virtual function string convert2string();
    return $sformatf("mem_seq_item: rst=%0b cs=%0b we=%0b addr=0x%0h data_in=0x%0h data_out=0x%0h valid_out=%0b",
      rst, cs, we, addr, data_in, data_out, valid_out);
  endfunction

endclass

`endif // MEM_SEQUENCE_ITEM_SVH
