`ifndef WR_CONTROL_SCOREBOARD_SVH
`define WR_CONTROL_SCOREBOARD_SVH

class wr_control_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(wr_control_scoreboard)
  uvm_analysis_export#(wr_control_sequence_item) sb_aexp;
  uvm_tlm_analysis_fifo#(wr_control_sequence_item) sb_fifo;
  
  wr_control_sequence_item item;
  bit delay = 0;
  int pass_count = 0;
  int error_count = 0;

  ////////////////////////////////////////////////////////////////////
  // Reference model signals and expected outputs
  ////////////////////////////////////////////////////////////////////

  // reference model signals
  var bit ref_rst_n;
  var bit [W_D_SIZE-1:0] ref_Ip_Bytes;
  var bit ref_EN;
  var bit ref_Deser_Done;
  var bit [WIDTH_DEGRADE_LENGTH-1:0] ref_Width_Degrade;

  // expected outputs 
  var bit [W_D_SIZE-1:0] exp_WR_DATA;
  var bit exp_WR_EN;

  // internal signals
  var bit [W_D_SIZE-1:0] ref_buffer;
  var bit ref_counter;
  ////////////////////////////////////////////////////////////////////

  function new(string name = "wr_control_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sb_aexp = new("sb_aexp", this);
    sb_fifo = new("sb_fifo", this);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    // skip the first item since it's full of unkown values
    sb_fifo.get(item);

    forever begin
      sb_fifo.get(item); // Get the next item from the FIFO
      if (item.R_RST_n == 1'b0) begin
        ref_model(item);    // Clears internal buffers and expected outputs
        check_values(item); // Check that the DUT outputs are reset to 0
      end      
      else begin
        check_values(item);
        ref_model(item);
      end
    end
  endtask

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    sb_aexp.connect(sb_fifo.analysis_export);
  endfunction


  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info(get_type_name(), "==================================================", UVM_NONE)
    `uvm_info(get_type_name(), "             MB_RX WR_CONTROL SCOREBOARD REPORT   ", UVM_NONE)
    `uvm_info(get_type_name(), "==================================================", UVM_NONE)
    `uvm_info(get_type_name(), $sformatf(" Total Successful Comparisons : %0d", pass_count), UVM_NONE)
    `uvm_info(get_type_name(), $sformatf(" Total Errors                 : %0d", error_count), UVM_NONE)
    `uvm_info(get_type_name(), "==================================================", UVM_NONE)
  endfunction

task ref_model(wr_control_sequence_item item);
    get_values(item);
    
    if(ref_rst_n == 0) begin
      exp_WR_EN             = 1'b0;
      exp_WR_DATA           = 'b0;
      ref_counter           = 1'b0;
      ref_buffer            = 'b0;
    end 
    else begin
      exp_WR_EN = 1'b0; // Default to 0 unless conditions are met

      if(ref_EN == 1'b1 && ref_Deser_Done == 1'b1) begin
        if(ref_Width_Degrade == 3'b001) begin
            if(ref_counter == 1'b0) begin 
                ref_buffer[(W_D_SIZE/2)-1:0] = ref_Ip_Bytes[(W_D_SIZE/2)-1:0];
                ref_counter = 1'b1;
            end
            else begin 
                ref_buffer[W_D_SIZE-1:(W_D_SIZE/2)] = ref_Ip_Bytes[(W_D_SIZE/2)-1:0];
                exp_WR_DATA = ref_buffer;
                exp_WR_EN = 1'b1;
                ref_counter = 1'b0;
            end
        end
        else if(ref_Width_Degrade == 3'b010) begin 
            if(ref_counter == 1'b0) begin 
                ref_buffer[(W_D_SIZE/2)-1:0] = ref_Ip_Bytes[W_D_SIZE-1:(W_D_SIZE/2)];
                ref_counter = 1'b1;
            end
            else begin 
                ref_buffer[W_D_SIZE-1:(W_D_SIZE/2)] = ref_Ip_Bytes[W_D_SIZE-1:(W_D_SIZE/2)];
                exp_WR_DATA = ref_buffer;
                exp_WR_EN = 1'b1;
                ref_counter = 1'b0;
            end
        end
        else if(ref_Width_Degrade == 3'b011) begin
            exp_WR_DATA = ref_Ip_Bytes;
            exp_WR_EN = 1'b1;
            ref_counter = 1'b0;
        end
      end
    end
  endtask

  task get_values(wr_control_sequence_item item);
    ref_rst_n         = item.R_RST_n;
    ref_Ip_Bytes      = item.Ip_Bytes;
    ref_EN            = item.EN;
    ref_Deser_Done    = item.Deser_Done;
    ref_Width_Degrade = item.Width_Degrade;
  endtask

  // task update_reg();
  //   ref_Ip_Bytes = ref_Ip_Bytes;
  //   ref_EN = ref_EN;
  //   ref_Deser_Done = ref_Deser_Done;
  //   ref_Width_Degrade = ref_Width_Degrade;
  // endtask

  task check_values(wr_control_sequence_item item);
    if(item.WR_EN !== exp_WR_EN || item.WR_DATA !== exp_WR_DATA) begin
      `uvm_error("WR_CONTROL_SCOREBOARD", $sformatf("expected WR_EN: %0b, got: %0b || expected WR_DATA: %0h, got: %0h", exp_WR_EN, item.WR_EN, exp_WR_DATA, item.WR_DATA))
      error_count++;
    end
    else
      pass_count++;
  endtask
endclass

`endif // WR_CONTROL_SCOREBOARD_SVH
