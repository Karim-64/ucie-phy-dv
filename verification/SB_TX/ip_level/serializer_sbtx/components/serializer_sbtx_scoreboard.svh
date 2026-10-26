`ifndef SERIALIZER_SBTX_SCOREBOARD_SVH
`define SERIALIZER_SBTX_SCOREBOARD_SVH

class serializer_sbtx_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(serializer_sbtx_scoreboard)

    localparam int DATA_WIDTH = 64;

    // Monitor transaction FIFO
    uvm_tlm_analysis_fifo #(serializer_sbtx_sequence_item) sb_fifo;

    // Reference model: the RTL drives data_out from shift_reg[0].
    logic [DATA_WIDTH-1:0] model_shift_reg;
    logic expected_data_out;
    logic expected_start_64;

    bit first_transaction = 1;
    int unsigned correct_count = 0;
    int unsigned error_count   = 0;

    function new(string name = "serializer_sbtx_scoreboard",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sb_fifo = new("sb_fifo", this);

        model_shift_reg  = '0;
        expected_data_out = 1'b0;
        expected_start_64 = 1'b0;
    endfunction

    task run_phase(uvm_phase phase);
        serializer_sbtx_sequence_item t;
        super.run_phase(phase);
        forever begin
            sb_fifo.get(t);
            check_(t);
        end
    endtask

    // The monitor must sample outputs before the current edge's NBA updates.
    // Compare the previous prediction, then process the current inputs.
    function void check_(serializer_sbtx_sequence_item t);
        if (t == null) begin
            `uvm_error("SBTX_SER_SCB", "Null monitor transaction")
            return;
        end

        if (first_transaction) begin
            first_transaction = 0;
            evaluate_(t);
            `uvm_info("SBTX_SER_INIT",
                      "First transaction: comparison skipped",
                      UVM_MEDIUM)
            return;
        end

        // Reset is asynchronous: outputs clear without waiting for a clock.
        if (t.rst_n === 1'b0) begin
            model_shift_reg   = '0;
            expected_data_out = 1'b0;
            expected_start_64 = 1'b0;
        end

        compare_(t);
        evaluate_(t);
    endfunction

    function void compare_(serializer_sbtx_sequence_item t);
        bit pass;

        pass = (expected_data_out === t.data_out) &&
               (expected_start_64 === t.start_64);

        if (pass) begin
            correct_count++;
            `uvm_info("SBTX_SER_PASS",
                      $sformatf("PASS previous: data_out=%b start_64=%b",
                                expected_data_out, expected_start_64),
                      UVM_MEDIUM)
        end
        else begin
            error_count++;
            `uvm_error("SBTX_SER_MISMATCH",
                       $sformatf({
                           "Previous expected: data_out=%b start_64=%b\n",
                           "Monitor actual:    data_out=%b start_64=%b\n",
                           "Current inputs: rst_n=%b load=%b Enable=%b data_in=%h"
                       },
                       expected_data_out, expected_start_64,
                       t.data_out, t.start_64,
                       t.rst_n, t.load, t.Enable, t.data_in))
        end
    endfunction

    // RTL model: asynchronous reset; load has priority over Enable;
    // shift right on Enable; idle clears data but RETAINS start_64.
    function void evaluate_(serializer_sbtx_sequence_item t);
        if (t.rst_n === 1'b0) begin
            model_shift_reg   = '0;
            expected_start_64 = 1'b0;
        end
        else if (t.load === 1'b1) begin
            model_shift_reg   = t.data_in;
            expected_start_64 = 1'b1;
        end
        else if (t.Enable === 1'b1) begin
            model_shift_reg   = model_shift_reg >> 1;
            expected_start_64 = 1'b0;
        end
        else begin
            model_shift_reg = '0;
            
        end

        expected_data_out = model_shift_reg[0];
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SBTX_SER_SUMMARY",
                  $sformatf("Pass=%0d Fail=%0d",
                            correct_count, error_count), UVM_NONE)
    endfunction

endclass

`endif // SERIALIZER_SBTX_SCOREBOARD_SVH
