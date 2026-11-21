module Credits_Handler_SBTX #(
  parameter int CNT_WIDTH = 4
)(
    input  logic CLK, RST_n,
    input  logic UIE,
    input  logic Credit, Comp_Sent, 
    input  logic D2D_PHY_Marker, Data_Marker, Comp_Marker, 
    output logic pl_cfg_crd
);
  logic fifo_crd; // From Async FIFO
  logic dec_crd;  // From Decoder (local RAR completion OR UR credit)
  logic uie_crd;  // From D2D_Data_Integrity
  
  logic prev_comp_sent;
  logic[CNT_WIDTH-1 : 0] saved_credit;
  logic[CNT_WIDTH:0] total_credits;
  
  assign fifo_crd = D2D_PHY_Marker & ~Data_Marker & ~Comp_Marker;
  assign dec_crd = (Comp_Sent & ~prev_comp_sent) | Credit;
  assign uie_crd = UIE;
  
  assign total_credits = saved_credit + fifo_crd + dec_crd + uie_crd;
  
  always_ff @(posedge CLK or negedge RST_n) begin
    if (!RST_n) begin
      pl_cfg_crd <= 1'b0;
      saved_credit <= '0;
      prev_comp_sent <= 1'b0;
    end
    else begin
      prev_comp_sent <= Comp_Sent;
      
      if (total_credits > 0) begin
        pl_cfg_crd <= 1'b1;
        saved_credit <= total_credits - 1'b1;
      end
      else begin
        pl_cfg_crd <= 1'b0;
        saved_credit <= '0;
      end
    end
  end
endmodule