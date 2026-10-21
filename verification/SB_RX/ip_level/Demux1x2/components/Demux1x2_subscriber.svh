`ifndef DEMUX1X2_SUBSCRIBER_SVH
`define DEMUX1X2_SUBSCRIBER_SVH

class Demux1x2_subscriber extends uvm_subscriber #(Demux1x2_sequence_item);
    `uvm_component_utils(Demux1x2_subscriber)

    Demux1x2_sequence_item cov_tr;

    covergroup Demux1x2_cg;

    cp_data_in: coverpoint cov_tr.data_in {
        bins zero             = {'0};
        bins ones             = {'1};
        bins alternating_10   = {64'hAAAA_AAAA_AAAA_AAAA};
        bins alternating_01   = {64'h5555_5555_5555_5555};
        bins other = {[2:$]};
    }

        cp_sel: coverpoint cov_tr.sel {
            bins select_0 = {0};
            bins select_1 = {1};
        }

        cp_out0: coverpoint cov_tr.out0;
        cp_out1: coverpoint cov_tr.out1;

        sel_x_data: cross cp_sel, cp_data_in;
    endgroup : Demux1x2_cg

    function new(string name = "Demux1x2_subscriber",
                 uvm_component parent = null);
        super.new(name, parent);
        Demux1x2_cg = new();
    endfunction : new

    function void write(Demux1x2_sequence_item t);
        if (t == null) begin
            `uvm_error("DEMUX1X2_COV", "Received a null transaction")
            return;
        end

        cov_tr = t;
        Demux1x2_cg.sample();
    endfunction : write

endclass : Demux1x2_subscriber

`endif