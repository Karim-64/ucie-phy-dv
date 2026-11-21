`ifndef SERIALIZER_SBTX_SUBSCRIBER_SVH
`define SERIALIZER_SBTX_SUBSCRIBER_SVH

class serializer_sbtx_subscriber extends uvm_subscriber #(serializer_sbtx_sequence_item);

    `uvm_component_utils(serializer_sbtx_subscriber)

    serializer_sbtx_sequence_item item;

    // Monitor -> analysis FIFO -> subscriber coverage.
    uvm_tlm_analysis_fifo #(serializer_sbtx_sequence_item) sub_fifo;

    covergroup cg_serializer;
        option.per_instance = 1;

        // Reset and its transitions.
        cp_rst_n: coverpoint item.rst_n {
            bins asserted   = {0};
            bins deasserted = {1};
        }

        cp_reset_transitions: coverpoint item.rst_n {
            bins reset_asserted = (1 => 0);
            bins reset_released = (0 => 1);
        }

        // Control signals.
        cp_load: coverpoint item.load {
            bins low  = {0};
            bins high = {1};
        }

        cp_Enable: coverpoint item.Enable {
            bins low  = {0};
            bins high = {1};
        }

        // Transitions, kept separate from control cross coverage.
        cp_load_transitions: coverpoint item.load {
            bins start_load   = (0 => 1);
            bins finish_load  = (1 => 0);
            bins repeated_load = (1 => 1);
        }

        cp_Enable_transitions: coverpoint item.Enable {
            bins start_shift = (0 => 1);
            bins stop_shift  = (1 => 0);
        }

        // All 8 reset/load/Enable combinations.
        cx_controls: cross cp_rst_n, cp_load, cp_Enable;

        // Corner values of the loaded 64-bit word.
        cp_data_in: coverpoint item.data_in iff (item.rst_n && item.load) {
            bins all_zeros    = {64'h0000_0000_0000_0000};
            bins all_ones     = {64'hFFFF_FFFF_FFFF_FFFF};
            bins alternating_a = {64'hAAAA_AAAA_AAAA_AAAA};
            bins alternating_5 = {64'h5555_5555_5555_5555};
            bins others       = default;
        }

        // A walking-one word has exactly 1 set bit.
        // A walking-zero word has exactly 63 set bits.
        cp_data_pattern: coverpoint $countones(item.data_in)
            iff (item.rst_n && item.load) {
            bins all_zeros   = {0};
            bins walking_one = {1};
            bins other       = {[2:62]};
            bins walking_zero = {63};
            bins all_ones    = {64};
        }

        
        // Each of the 64 possible positions of a single 1 or a single 0.
        cp_walking_one_position: coverpoint $clog2(item.data_in)
            iff (item.rst_n && item.load &&
                 $countones(item.data_in) == 1) {
            bins positions[] = {[0:63]};
        }

        cp_walking_zero_position: coverpoint $clog2(~item.data_in)
            iff (item.rst_n && item.load &&
                 $countones(item.data_in) == 63) {
            bins positions[] = {[0:63]};
        }

        // Observed outputs (the scoreboard verifies correctness).
        cp_data_out: coverpoint item.data_out {
            bins zero = {0};
            bins one  = {1};
            bins zero_to_one = (0 => 1);
            bins one_to_zero = (1 => 0);
        }

        cp_start_64: coverpoint item.start_64 {
            bins low  = {0};
            bins high = {1};
            bins asserted = (0 => 1);
            bins cleared  = (1 => 0);
            bins held_high = (1 => 1);
        }

    endgroup : cg_serializer

    function new(string name = "serializer_sbtx_subscriber",
                 uvm_component parent = null);
        super.new(name, parent);
        cg_serializer = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sub_fifo = new("sub_fifo", this);
    endfunction

    task run_phase(uvm_phase phase);
        serializer_sbtx_sequence_item t;

        super.run_phase(phase);

        forever begin
            sub_fifo.get(t);
            write(t);
        end
    endtask

    virtual function void write(serializer_sbtx_sequence_item t);
        if (t == null) begin
            `uvm_error("SER_SBTX_COV", "Null monitor transaction")
            return;
        end

        item = t;
        cg_serializer.sample();
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV_REPORT",
                  $sformatf("Overall Functional Coverage: %0.2f%%",
                            cg_serializer.get_inst_coverage()),
                  UVM_LOW)
    endfunction

endclass

`endif // SERIALIZER_SBTX_SUBSCRIBER_SVH
