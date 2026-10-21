class Demux1x2_rst_seq extends uvm_sequence #(Demux1x2_sequence_item);
    `uvm_object_utils(Demux1x2_rst_seq)
    `uvm_declare_p_sequencer(Demux1x2_sequencer)

    Demux1x2_sequence_item seq_item;

    function new(string name = "Demux1x2_rst_seq");
        super.new(name);
    endfunction

    task body();
        seq_item = Demux1x2_sequence_item::type_id::create("seq_item");
        seq_item.constraint_mode(0);
        repeat(10) begin
            start_item(seq_item);
            if (!seq_item.randomize() with { seq_item.data_in == {DATA_WIDTH{1'b0}}; seq_item.sel == 0; })
                `uvm_fatal("Demux1x2_rst_seq", "Randomization failed")
            finish_item(seq_item);
            p_sequencer.seqr_aport.write(seq_item);
        end
    endtask
endclass

class Demux1x2_directed_seq extends uvm_sequence #(Demux1x2_sequence_item);
    `uvm_object_utils(Demux1x2_directed_seq)
    `uvm_declare_p_sequencer(Demux1x2_sequencer)

    Demux1x2_sequence_item seq_item;
    logic [DATA_WIDTH-1:0] arr[5] = '{'0,'1,64'hAAAA_AAAA_AAAA_AAAA,64'h5555_5555_5555_5555,64'h0000_0000_0000_0001};
    bit force_sel =0;

    function new(string name = "Demux1x2_directed_seq");
        super.new(name);
    endfunction

    task body();
        seq_item = Demux1x2_sequence_item::type_id::create("seq_item");
        seq_item.constraint_mode(0);      
                for(int i=0;i<5;i++)begin
                    start_item(seq_item);
                    seq_item.data_in = arr[i];
                    seq_item.sel = force_sel;
                    force_sel = ~ force_sel;
                    finish_item(seq_item);
                    p_sequencer.seqr_aport.write(seq_item);
                end     
    endtask
endclass

class Demux1x2_zero_seq extends uvm_sequence #(Demux1x2_sequence_item);
    `uvm_object_utils(Demux1x2_zero_seq)
    `uvm_declare_p_sequencer(Demux1x2_sequencer)

    Demux1x2_sequence_item seq_item;

    function new(string name = "Demux1x2_zero_seq");
        super.new(name);
    endfunction

    task body();
        seq_item = Demux1x2_sequence_item::type_id::create("seq_item");
        seq_item.sel_c.constraint_mode(1);
        seq_item.c_data.constraint_mode(0);
        repeat(10) begin
            start_item(seq_item);
            if (!seq_item.randomize() with { data_in == {DATA_WIDTH{1'b0}}; })
                `uvm_fatal("Demux1x2_zero_seq", "Randomization failed")
            finish_item(seq_item);
            p_sequencer.seqr_aport.write(seq_item);
        end
    endtask
endclass


class Demux1x2_one_seq extends uvm_sequence #(Demux1x2_sequence_item);
    `uvm_object_utils(Demux1x2_one_seq)
    `uvm_declare_p_sequencer(Demux1x2_sequencer)

    Demux1x2_sequence_item seq_item;

    function new(string name = "Demux1x2_one_seq");
        super.new(name);
    endfunction

    task body();
        seq_item = Demux1x2_sequence_item::type_id::create("seq_item");
        seq_item.sel_c.constraint_mode(1);
        seq_item.c_data.constraint_mode(0);
        repeat(10) begin
            start_item(seq_item);
            if (!seq_item.randomize() with { data_in == {DATA_WIDTH{1'b1}}; })
                `uvm_fatal("Demux1x2_one_seq", "Randomization failed")
            finish_item(seq_item);
            p_sequencer.seqr_aport.write(seq_item);
        end
    endtask
endclass


class Demux1x2_select_1_seq extends uvm_sequence #(Demux1x2_sequence_item);
    `uvm_object_utils(Demux1x2_select_1_seq)
    `uvm_declare_p_sequencer(Demux1x2_sequencer)

    Demux1x2_sequence_item seq_item;

    function new(string name = "Demux1x2_select_1_seq");
        super.new(name);
    endfunction

    task body();
        seq_item = Demux1x2_sequence_item::type_id::create("seq_item");
        seq_item.sel_c.constraint_mode(0);
        seq_item.c_data.constraint_mode(1);

        repeat(10) begin
            start_item(seq_item);
            if (!seq_item.randomize() with { sel == 1'b1; })
                `uvm_fatal("Demux1x2_select_1_seq", "Randomization failed")
            finish_item(seq_item);
            p_sequencer.seqr_aport.write(seq_item);
        end
    endtask
endclass


class Demux1x2_select_0_seq extends uvm_sequence #(Demux1x2_sequence_item);
    `uvm_object_utils(Demux1x2_select_0_seq)
    `uvm_declare_p_sequencer(Demux1x2_sequencer)

    Demux1x2_sequence_item seq_item;

    function new(string name = "Demux1x2_select_0_seq");
        super.new(name);
    endfunction

    task body();
        seq_item = Demux1x2_sequence_item::type_id::create("seq_item");
        seq_item.sel_c.constraint_mode(0);
        seq_item.c_data.constraint_mode(1);

        repeat(10) begin
            start_item(seq_item);
            if (!seq_item.randomize() with { sel == 1'b0; })
                `uvm_fatal("Demux1x2_select_0_seq", "Randomization failed")
            finish_item(seq_item);
            p_sequencer.seqr_aport.write(seq_item);
        end
    endtask
endclass


class Demux1x2_random_seq extends uvm_sequence #(Demux1x2_sequence_item);
    `uvm_object_utils(Demux1x2_random_seq)
    `uvm_declare_p_sequencer(Demux1x2_sequencer)

    Demux1x2_sequence_item seq_item;

    function new(string name = "Demux1x2_random_seq");
        super.new(name);
    endfunction

    task body();
        seq_item = Demux1x2_sequence_item::type_id::create("seq_item");
        seq_item.sel_c.constraint_mode(1);
        seq_item.c_data.constraint_mode(1);
        repeat(1000) begin
            start_item(seq_item);
            if (!seq_item.randomize())
                `uvm_fatal("Demux1x2_random_seq", "Randomization failed")
            finish_item(seq_item);
            p_sequencer.seqr_aport.write(seq_item);
        end
    endtask
endclass

class Demux1x2_alternating_seq extends uvm_sequence #(Demux1x2_sequence_item);
    `uvm_object_utils(Demux1x2_alternating_seq)
    `uvm_declare_p_sequencer(Demux1x2_sequencer)

    Demux1x2_sequence_item seq_item;

    function new(string name = "Demux1x2_alternating_seq");
        super.new(name);
    endfunction

    task body();
        seq_item = Demux1x2_sequence_item::type_id::create("seq_item");

        repeat (10) begin
            // Alternating 10, sel = 0
            start_item(seq_item);
            if (!seq_item.randomize() with {
                data_in == 64'hAAAA_AAAA_AAAA_AAAA;
                sel == 1'b0;
            })`uvm_fatal("Demux1x2_alternating_seq", "Randomization failed")
            finish_item(seq_item);
            p_sequencer.seqr_aport.write(seq_item);

            // Alternating 10, sel = 1
            start_item(seq_item);
            if (!seq_item.randomize() with {
                data_in == 64'hAAAA_AAAA_AAAA_AAAA;
                sel == 1'b1;
            })`uvm_fatal("Demux1x2_alternating_seq", "Randomization failed")
            finish_item(seq_item);
            p_sequencer.seqr_aport.write(seq_item);

            // Alternating 01, sel = 0
            start_item(seq_item);
            if (!seq_item.randomize() with {
                data_in == 64'h5555_5555_5555_5555;
                sel == 1'b0;
            })`uvm_fatal("Demux1x2_alternating_seq", "Randomization failed")
            finish_item(seq_item);
            p_sequencer.seqr_aport.write(seq_item);

            // Alternating 01, sel = 1
            start_item(seq_item);
            if (!seq_item.randomize() with {
                data_in == 64'h5555_5555_5555_5555;
                sel == 1'b1;
            })`uvm_fatal("Demux1x2_alternating_seq", "Randomization failed")
            finish_item(seq_item);
            p_sequencer.seqr_aport.write(seq_item);
        end
    endtask
endclass