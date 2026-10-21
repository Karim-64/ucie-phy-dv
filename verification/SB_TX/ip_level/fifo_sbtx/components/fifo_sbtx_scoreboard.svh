`ifndef FIFO_SBTX_SCOREBOARD_SVH
`define FIFO_SBTX_SCOREBOARD_SVH

class fifo_sbtx_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(fifo_sbtx_scoreboard)

    localparam int FIFO_WIDTH = 64;
    localparam int FIFO_DEPTH = 64;

    // Monitor -> ap.analysis_export -> ap.get(t)
    uvm_tlm_analysis_fifo #(fifo_sbtx_sequence_item) ap;

    typedef struct packed {
        logic [FIFO_WIDTH-1:0] data;
        logic DM;
        logic RAM;
        logic RADM;
        logic CM;
        logic RRM;
    } fifo_entry_t;

    fifo_entry_t fifo_q[$];
    int rar_idx = -1;
    int req_idx = -1;
    bit reset_seen = 0;
    bit first_transaction = 1;

    // These registers hold the outputs predicted by the LAST evaluated
    // transaction. They are compared before evaluating the next transaction.
    logic [FIFO_WIDTH-1:0] expected_data_out;
    logic expected_Data_Marker_Out;
    logic expected_Reg_Acc_Marker_Out;
    logic expected_Reg_Acc_Data_Marker_Out;
    logic expected_Comp_Marker_Out;
    logic expected_empty;
    logic expected_rd_ack;

    int unsigned correct_count = 0;
    int unsigned error_count = 0;

    function new(string name = "fifo_sbtx_scoreboard",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);

        expected_data_out                = '0;
        expected_Data_Marker_Out         = 1'b0;
        expected_Reg_Acc_Marker_Out      = 1'b0;
        expected_Reg_Acc_Data_Marker_Out = 1'b0;
        expected_Comp_Marker_Out         = 1'b0;
        expected_empty                   = 1'b1;
        expected_rd_ack                  = 1'b0;
    endfunction

    task run_phase(uvm_phase phase);
        fifo_sbtx_sequence_item t;
        super.run_phase(phase);
        forever begin
            ap.get(t);
            check_(t);
        end
    endtask

    // ------------------------------------------------------------
    // 1. CHECK: Compare previous-cycle outputs, THEN predict next.
    // ------------------------------------------------------------
    
function void check_(fifo_sbtx_sequence_item t);

    if (t == null) begin
        `uvm_error("SBTX_SCB", "Null monitor transaction")
        return;
    end

    // Skip comparison for the FIRST transaction only
    if (first_transaction) begin

        first_transaction = 0;

        // Still update the reference model
        evaluate_(t);

        `uvm_info("SBTX_INIT",
                  "First transaction: comparison skipped",
                  UVM_MEDIUM)

        return;
    end

    // Handle random asynchronous reset
    if (t.rst_n === 1'b0) begin
        expected_data_out                = '0;
        expected_Data_Marker_Out         = 1'b0;
        expected_Reg_Acc_Marker_Out      = 1'b0;
        expected_Reg_Acc_Data_Marker_Out = 1'b0;
        expected_Comp_Marker_Out         = 1'b0;
        expected_empty                   = 1'b1;
        expected_rd_ack                  = 1'b0;
    end

    // Compare previous expected outputs with current DUT outputs
    compare_(t);

    // Evaluate current inputs for next cycle
    evaluate_(t);

endfunction

    // ------------------------------------------------------------
    // 2. COMPARE: DO NOT modify the reference queue or predictions.
    // ------------------------------------------------------------
    function void compare_(fifo_sbtx_sequence_item t);
        bit pass;

        // Reset overrides pending data/ack asynchronously. A pre-edge
        // monitor sample may straddle the assertion of reset, so the
        // previous read prediction is not meaningful during reset.
       

        pass = (expected_data_out                === t.data_out) &&
               (expected_Data_Marker_Out         === t.Data_Marker_Out) &&
               (expected_Reg_Acc_Marker_Out      === t.Reg_Acc_Marker_Out) &&
               (expected_Reg_Acc_Data_Marker_Out === t.Reg_Acc_Data_Marker_Out) &&
               (expected_Comp_Marker_Out         === t.Comp_Marker_Out) &&
               (expected_empty                   === t.empty) &&
               (expected_rd_ack                  === t.rd_ack);

        if (pass) begin
            correct_count++;
            `uvm_info("SBTX_PASS",
                      $sformatf("PASS previous: data=%h empty=%b ack=%b; qsize_before_eval=%0d",
                                expected_data_out, expected_empty,
                                expected_rd_ack, fifo_q.size()),
                      UVM_MEDIUM)
        end
        else begin
            error_count++;
            `uvm_error("SBTX_MISMATCH",
                       $sformatf({
                         "Previous expected: data=%h DM=%b RAM=%b RADM=%b CM=%b empty=%b ack=%b\n",
                         "Monitor actual:    data=%h DM=%b RAM=%b RADM=%b CM=%b empty=%b ack=%b"
                       },
                       expected_data_out,
                       expected_Data_Marker_Out,
                       expected_Reg_Acc_Marker_Out,
                       expected_Reg_Acc_Data_Marker_Out,
                       expected_Comp_Marker_Out,
                       expected_empty, expected_rd_ack,
                       t.data_out, t.Data_Marker_Out,
                       t.Reg_Acc_Marker_Out,
                       t.Reg_Acc_Data_Marker_Out,
                       t.Comp_Marker_Out, t.empty, t.rd_ack))
        end
    endfunction

    // ------------------------------------------------------------
    // 3. EVALUATE: Compute the outputs expected on the NEXT sample.
    // ------------------------------------------------------------
    function void evaluate_(fifo_sbtx_sequence_item t);
        int old_size;
        int old_rar_idx;
        int old_req_idx;
        int read_idx;
        bit WR_Cond;
        bit RD_Cond;
        fifo_entry_t wr_entry;
        fifo_entry_t rd_entry;

        if (t.rst_n === 1'b0) begin
            fifo_q.delete();
            rar_idx = -1;
            req_idx = -1;
            reset_seen = 1;

            expected_data_out                = '0;
            expected_Data_Marker_Out         = 1'b0;
            expected_Reg_Acc_Marker_Out      = 1'b0;
            expected_Reg_Acc_Data_Marker_Out = 1'b0;
            expected_Comp_Marker_Out         = 1'b0;
            expected_empty                   = 1'b1;
            expected_rd_ack                  = 1'b0;
            
        end
       else begin
        old_size    = fifo_q.size();
        old_rar_idx = rar_idx;
        old_req_idx = req_idx;

        // Accepted operations depend on occupancy BEFORE this transaction.
        WR_Cond = (t.wr_en === 1'b1) &&
                  (t.UIE   === 1'b0) &&
                  (old_size < FIFO_DEPTH);
        RD_Cond = (t.rd_en === 1'b1) && (old_size > 0);

       
        read_idx = 0;

        if (RD_Cond &&
            old_req_idx >= 0 &&
            old_req_idx < old_size &&
            (old_rar_idx == 0 || old_rar_idx == -1)) begin

            read_idx = old_req_idx;

        end


        if (WR_Cond) begin
            wr_entry.data = t.data_in;
            wr_entry.DM   = t.Data_Marker;
            wr_entry.RAM  = t.Reg_Acc_Marker;
            wr_entry.RADM = t.Reg_Acc_Data_Marker;
            wr_entry.CM   = t.Comp_Marker;
            wr_entry.RRM  = t.Req_Resp_Marker;
            fifo_q.push_back(wr_entry);

            // Preserve the original priority-tracking policy.
            if (t.Req_Resp_Marker === 1'b1 &&
            old_rar_idx >= 0) begin

            // Match RTL: newest eligible Req/Resp replaces previous
            req_idx = old_size;

end
            else if (t.Reg_Acc_Marker === 1'b1 && old_rar_idx == -1) begin
                rar_idx = old_size;
            end
        end

        expected_rd_ack = RD_Cond;
        if (RD_Cond) begin
            
            rd_entry = fifo_q[read_idx];
            fifo_q.delete(read_idx);

            expected_data_out                = rd_entry.data;
            expected_Data_Marker_Out         = rd_entry.DM;
            expected_Reg_Acc_Marker_Out      = rd_entry.RAM;
            expected_Reg_Acc_Data_Marker_Out = rd_entry.RADM;
            expected_Comp_Marker_Out         = rd_entry.CM;

            if (rar_idx == read_idx)
                rar_idx = -1;
            else if (rar_idx > read_idx)
                rar_idx--;

            if (req_idx == read_idx)
                req_idx = -1;
            else if (req_idx > read_idx)
                req_idx--;

           
        end

        expected_empty = (fifo_q.size() == 0);
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SBTX_SUMMARY",
                  $sformatf("Pass=%0d Fail=%0d", correct_count, error_count),
                  UVM_NONE)
    endfunction
endclass

`endif // FIFO_SBTX_SCOREBOARD_SVH
