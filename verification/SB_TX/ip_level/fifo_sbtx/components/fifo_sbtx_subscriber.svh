
`ifndef FIFO_SBTX_SUBSCRIBER_SVH
`define FIFO_SBTX_SUBSCRIBER_SVH

class fifo_sbtx_subscriber extends uvm_subscriber #(fifo_sbtx_sequence_item);

    `uvm_component_utils(fifo_sbtx_subscriber)

    uvm_tlm_analysis_fifo #(fifo_sbtx_sequence_item) ap;

    fifo_sbtx_sequence_item cov_tr;

    // Coverage statistics
    int unsigned total_samples = 0;
    int unsigned reset_samples = 0;
    int unsigned write_attempts = 0;
    int unsigned read_requests = 0;
    int unsigned read_acks = 0;
    int unsigned simultaneous_operations = 0;
    int unsigned reg_acc_writes = 0;
    int unsigned req_resp_writes = 0;

    // ============================================================
    // FUNCTIONAL COVERAGE
    // ============================================================

    covergroup fifo_sbtx_cg;

        option.per_instance = 1;

        // --------------------------------------------------------
        // 1. RESET COVERAGE
        // --------------------------------------------------------

        cp_rst_n: coverpoint cov_tr.rst_n {
            bins reset_active   = {0};
            bins reset_inactive = {1};
        }

        // Reset transitions
        cp_reset_transition: coverpoint cov_tr.rst_n {
            bins reset_assert  = (1 => 0);
            bins reset_release = (0 => 1);
        }

        // --------------------------------------------------------
        // 2. READ / WRITE OPERATION COVERAGE
        // --------------------------------------------------------

        cp_operation: coverpoint
            {cov_tr.wr_en, cov_tr.rd_en}
            iff (cov_tr.rst_n === 1'b1) {

            bins idle          = {2'b00};
            bins read_only     = {2'b01};
            bins write_only    = {2'b10};
            bins simultaneous  = {2'b11};
        }

        // --------------------------------------------------------
        // 3. UIE COVERAGE
        // --------------------------------------------------------

        cp_UIE: coverpoint cov_tr.UIE
            iff (cov_tr.rst_n === 1'b1) {

            bins write_allowed = {0};
            bins write_blocked = {1};
        }

        // Exercise all combinations of read/write and UIE
        cross_operation_UIE: cross cp_operation, cp_UIE;

        // --------------------------------------------------------
        // 4. PRIORITY MARKER COVERAGE
        // --------------------------------------------------------

        // Sample marker values only when a write is requested
        // and UIE is not blocking it.
        // This does NOT prove the write was accepted when full.

        cp_Reg_Acc_Marker: coverpoint cov_tr.Reg_Acc_Marker
            iff (cov_tr.rst_n === 1'b1 &&
                 cov_tr.wr_en === 1'b1 &&
                 cov_tr.UIE === 1'b0) {

            bins normal = {0};
            bins rar    = {1};
        }

        cp_Req_Resp_Marker: coverpoint cov_tr.Req_Resp_Marker
            iff (cov_tr.rst_n === 1'b1 &&
                 cov_tr.wr_en === 1'b1 &&
                 cov_tr.UIE === 1'b0) {

            bins normal   = {0};
            bins req_resp = {1};
        }

        // --------------------------------------------------------
        // 5. PRIORITY + SIMULTANEOUS OPERATIONS
        // --------------------------------------------------------

        // Bits:
        // {rd_en, Reg_Acc_Marker, Req_Resp_Marker}

        cp_priority_scenario: coverpoint
            {cov_tr.rd_en,
             cov_tr.Reg_Acc_Marker,
             cov_tr.Req_Resp_Marker}

            iff (cov_tr.rst_n === 1'b1 &&
                 cov_tr.wr_en === 1'b1 &&
                 cov_tr.UIE === 1'b0) {

            bins write_normal      = {3'b000};
            bins write_req_resp    = {3'b001};
            bins write_rar         = {3'b010};
            bins write_both_marker = {3'b011};

            bins rw_normal         = {3'b100};
            bins rw_req_resp       = {3'b101};
            bins rw_rar            = {3'b110};
            bins rw_both_marker    = {3'b111};
        }

        // --------------------------------------------------------
        // 6. INPUT DATA MARKERS
        // --------------------------------------------------------

        cp_input_markers: coverpoint
            {cov_tr.Data_Marker,
             cov_tr.Reg_Acc_Marker,
             cov_tr.Reg_Acc_Data_Marker,
             cov_tr.Comp_Marker}

            iff (cov_tr.rst_n === 1'b1 &&
                 cov_tr.wr_en === 1'b1 &&
                 cov_tr.UIE === 1'b0) {

            bins marker_combinations[] = {[0:15]};
        }

        // --------------------------------------------------------
        // 7. INPUT DATA COVERAGE
        // --------------------------------------------------------

        cp_data_in_high: coverpoint cov_tr.data_in[63:60]
            iff (cov_tr.rst_n === 1'b1 &&
                 cov_tr.wr_en === 1'b1 &&
                 cov_tr.UIE === 1'b0) {

            bins values[] = {[0:15]};
        }

        cp_data_in_low: coverpoint cov_tr.data_in[3:0]
            iff (cov_tr.rst_n === 1'b1 &&
                 cov_tr.wr_en === 1'b1 &&
                 cov_tr.UIE === 1'b0) {

            bins values[] = {[0:15]};
        }

        // --------------------------------------------------------
        // 8. OUTPUT DATA COVERAGE
        // --------------------------------------------------------

        // Only meaningful when a read is acknowledged.

        cp_data_out_high: coverpoint cov_tr.data_out[63:60]
            iff (cov_tr.rst_n === 1'b1 &&
                 cov_tr.rd_ack === 1'b1) {

            bins values[] = {[0:15]};
        }

        cp_data_out_low: coverpoint cov_tr.data_out[3:0]
            iff (cov_tr.rst_n === 1'b1 &&
                 cov_tr.rd_ack === 1'b1) {

            bins values[] = {[0:15]};
        }

        // --------------------------------------------------------
        // 9. OUTPUT MARKER COVERAGE
        // --------------------------------------------------------

        cp_output_markers: coverpoint
            {cov_tr.Data_Marker_Out,
             cov_tr.Reg_Acc_Marker_Out,
             cov_tr.Reg_Acc_Data_Marker_Out,
             cov_tr.Comp_Marker_Out}

            iff (cov_tr.rst_n === 1'b1 &&
                 cov_tr.rd_ack === 1'b1) {

            bins marker_combinations[] = {[0:15]};
        }

        // --------------------------------------------------------
        // 10. EMPTY AND READ ACK COVERAGE
        // --------------------------------------------------------

        cp_empty: coverpoint cov_tr.empty
            iff (cov_tr.rst_n === 1'b1) {

            bins empty_state    = {1};
            bins nonempty_state = {0};
        }

        cp_rd_ack: coverpoint cov_tr.rd_ack
            iff (cov_tr.rst_n === 1'b1) {

            bins no_ack = {0};
            bins ack    = {1};
        }

        // Both signals are observed DUT outputs.
        cross_ack_empty: cross cp_rd_ack, cp_empty;

        // --------------------------------------------------------
        // 11. CONSECUTIVE PRIORITY MARKERS
        // --------------------------------------------------------

        cp_req_resp_transition:
            coverpoint cov_tr.Req_Resp_Marker
            iff (cov_tr.rst_n === 1'b1 &&
                 cov_tr.wr_en === 1'b1 &&
                 cov_tr.UIE === 1'b0) {

            bins normal_to_req  = (0 => 1);
            bins req_to_req     = (1 => 1);
            bins req_to_normal  = (1 => 0);
        }

        cp_rar_transition:
            coverpoint cov_tr.Reg_Acc_Marker
            iff (cov_tr.rst_n === 1'b1 &&
                 cov_tr.wr_en === 1'b1 &&
                 cov_tr.UIE === 1'b0) {

            bins normal_to_rar = (0 => 1);
            bins rar_to_rar    = (1 => 1);
            bins rar_to_normal = (1 => 0);
        }

    endgroup : fifo_sbtx_cg

    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    function new(
        string name = "fifo_sbtx_subscriber",
        uvm_component parent = null
    );

        super.new(name, parent);

        fifo_sbtx_cg = new();

    endfunction

    // ============================================================
    // BUILD PHASE
    // ============================================================

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        ap = new("ap", this);

    endfunction

    // ============================================================
    // RUN PHASE
    // ============================================================

    task run_phase(uvm_phase phase);

        fifo_sbtx_sequence_item t;

        super.run_phase(phase);

        forever begin

            ap.get(t);

            write(t);

        end

    endtask

    // ============================================================
    // WRITE FUNCTION
    // ============================================================

    virtual function void write(fifo_sbtx_sequence_item t);

        if (t == null) begin
            `uvm_error("FIFO_SBTX_COV", "Null transaction")
            return;
        end

        cov_tr = t;

        total_samples++;

        if (t.rst_n === 1'b0)
            reset_samples++;

        if (t.rst_n === 1'b1) begin

            if (t.wr_en === 1'b1 && t.UIE === 1'b0) begin

                write_attempts++;

                if (t.Reg_Acc_Marker === 1'b1)
                    reg_acc_writes++;

                if (t.Req_Resp_Marker === 1'b1)
                    req_resp_writes++;

            end

            if (t.rd_en === 1'b1)
                read_requests++;

            if (t.rd_ack === 1'b1)
                read_acks++;

            if (t.wr_en === 1'b1 && t.rd_en === 1'b1)
                simultaneous_operations++;

        end

        fifo_sbtx_cg.sample();

    endfunction

    // ============================================================
    // REPORT PHASE
    // ============================================================

    function void report_phase(uvm_phase phase);

        super.report_phase(phase);

        `uvm_info("FIFO_SBTX_COVERAGE",
            $sformatf({
                "\nTotal samples        = %0d",
                "\nReset samples        = %0d",
                "\nWrite attempts       = %0d",
                "\nRead requests        = %0d",
                "\nRead acknowledgments = %0d",
                "\nSimultaneous WR/RD   = %0d",
                "\nReg_Acc writes       = %0d",
                "\nReq/Resp writes      = %0d",
                "\nFunctional coverage  = %0.2f%%"
            },
                total_samples,
                reset_samples,
                write_attempts,
                read_requests,
                read_acks,
                simultaneous_operations,
                reg_acc_writes,
                req_resp_writes,
                fifo_sbtx_cg.get_inst_coverage()
            ),
            UVM_NONE
        )

    endfunction

endclass : fifo_sbtx_subscriber

`endif // FIFO_SBTX_SUBSCRIBER_SVH
