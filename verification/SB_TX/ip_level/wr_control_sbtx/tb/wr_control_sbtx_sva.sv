module wr_ctrl_sbtx_sva (
    wr_control_sbtx_if wr_control_sbtx_if_inst 
);

  always_comb begin
    if (~wr_control_sbtx_if_inst.RST_n) begin
      assert final ({wr_control_sbtx_if_inst.Interface_Message, wr_control_sbtx_if_inst.UIE, wr_control_sbtx_if_inst.Error_Handler, wr_control_sbtx_if_inst.FIFO_WR,
                     wr_control_sbtx_if_inst.Comp_Marker, wr_control_sbtx_if_inst.Data_Marker, wr_control_sbtx_if_inst.Req_Resp_Marker,
                     wr_control_sbtx_if_inst.Reg_Acc_Data_Marker, wr_control_sbtx_if_inst.Reg_Acc_Marker} == '0);
      cover final  ({wr_control_sbtx_if_inst.Interface_Message, wr_control_sbtx_if_inst.UIE, wr_control_sbtx_if_inst.Error_Handler, wr_control_sbtx_if_inst.FIFO_WR,
                     wr_control_sbtx_if_inst.Comp_Marker, wr_control_sbtx_if_inst.Data_Marker, wr_control_sbtx_if_inst.Req_Resp_Marker,
                     wr_control_sbtx_if_inst.Reg_Acc_Data_Marker, wr_control_sbtx_if_inst.Reg_Acc_Marker} == '0);
    end
  end

  property UIE_assert;
    @(posedge wr_control_sbtx_if_inst.CLK) disable iff(~wr_control_sbtx_if_inst.RST_n)
    (wr_control_sbtx_if_inst.UIE) |-> wr_control_sbtx_if_inst.FIFO_WR;
  endproperty
  assert property (UIE_assert);
  cover property (UIE_assert);

  property Error_Handler_assert;
    @(posedge wr_control_sbtx_if_inst.CLK) disable iff(~wr_control_sbtx_if_inst.RST_n)
    (wr_control_sbtx_if_inst.Error_Handler) |-> (wr_control_sbtx_if_inst.FIFO_WR && wr_control_sbtx_if_inst.UIE);
  endproperty
  assert property (Error_Handler_assert);
  cover property (Error_Handler_assert);

  property Marker_flags_assert;
    @(posedge wr_control_sbtx_if_inst.CLK) disable iff(~wr_control_sbtx_if_inst.RST_n)
    (wr_control_sbtx_if_inst.Comp_Marker | wr_control_sbtx_if_inst.Data_Marker | wr_control_sbtx_if_inst.Req_Resp_Marker | wr_control_sbtx_if_inst.Reg_Acc_Data_Marker | wr_control_sbtx_if_inst.Reg_Acc_Marker) |-> (wr_control_sbtx_if_inst.FIFO_WR);
  endproperty
  assert property (Marker_flags_assert);
  cover property (Marker_flags_assert);

  // Helper function to check if the opcode in Header Phase 0 carries a 64-bit data payload
  //   function automatic bit has_data_opcode(logic [4:0] op);
  //     return (op inside {5'b00001, 5'b00011, 5'b00101, 5'b01001, 5'b01011, 5'b01101,
  //                        5'b10001, 5'b11001, 5'b11011});
  //   endfunction

  //     When lp_cfg_vld rises, if opcode has no data -> high for at least 2 cycles;
  //     if opcode has data -> high for at least 4 cycles.
    function automatic bit has_data_opcode(logic [4:0] op);
     return (op inside {5'b00001, 5'b00011, 5'b00101, 5'b01001, 5'b01011, 5'b01101,
                       5'b10001, 5'b11001, 5'b11011});
    endfunction

  property lp_cfg_vld_2_or_4_cycles_assert;
    @(posedge wr_control_sbtx_if_inst.CLK) disable iff(~wr_control_sbtx_if_inst.RST_n)
    $rose(wr_control_sbtx_if_inst.lp_cfg_vld) |->
      ( (!has_data_opcode(wr_control_sbtx_if_inst.lp_cfg[4:0]) and wr_control_sbtx_if_inst.lp_cfg_vld[*2]) or
        ( has_data_opcode(wr_control_sbtx_if_inst.lp_cfg[4:0]) and wr_control_sbtx_if_inst.lp_cfg_vld[*4]) );
  endproperty
  assert property (lp_cfg_vld_2_or_4_cycles_assert);
  cover property (lp_cfg_vld_2_or_4_cycles_assert);

  //lp_cfg_vld should be constantly high for an even number of cycles only
  // ---------------------------------------------------------------------------
  // SVA Sequence Method: Any high pulse from $rose(lp_cfg_vld) to !lp_cfg_vld
  // must consist of one or more 2-cycle pairs: (lp_cfg_vld[*2])[+]
  property lp_cfg_vld_even_cycles_sva;
    @(posedge wr_control_sbtx_if_inst.CLK) disable iff(~wr_control_sbtx_if_inst.RST_n)
    $rose(wr_control_sbtx_if_inst.lp_cfg_vld) |-> (wr_control_sbtx_if_inst.lp_cfg_vld[*2])[+] ##1 !wr_control_sbtx_if_inst.lp_cfg_vld;
  endproperty
  assert property (lp_cfg_vld_even_cycles_sva);
  cover property (lp_cfg_vld_even_cycles_sva);

endmodule