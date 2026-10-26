`ifndef SERIALIZER_SBTX_BASE_SEQUENCE_SVH
`define SERIALIZER_SBTX_BASE_SEQUENCE_SVH

class serializer_sbtx_base_sequence extends uvm_sequence #(serializer_sbtx_sequence_item);

    `uvm_object_utils(serializer_sbtx_base_sequence)
    `uvm_declare_p_sequencer(serializer_sbtx_sequencer)

    localparam int DATA_WIDTH = 64;

    function new(string name = "serializer_sbtx_base_sequence");
        super.new(name);
    endfunction

    // 1) Reset during idle, load, and serialization.
    task automatic test_reset(int iterations = 32);
        for (int i = 0; i < iterations; i++) begin
            req = serializer_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                rst_n  == ((i % 4 == 0 || i % 4 == 3) ? 0 : 1);
                load   == (i % 4 == 1 || i % 4 == 3);
                Enable == (i % 4 == 2 || i % 4 == 3);
            }) `uvm_fatal("SEQ", "Reset randomization failed")
            finish_item(req);
            p_sequencer.seqr_aport.write(req);
        end
    endtask

    // 2) Back-to-back loads, Enable=0 and Enable=1, various data patterns.
    task automatic test_load(int iterations = 40);
        bit [DATA_WIDTH-1:0] data_pattern;
        test_reset(1);
        for (int i = 0; i < iterations; i++) begin
            case (i % 5)
                0: data_pattern = 64'h0000_0000_0000_0000;
                1: data_pattern = 64'hFFFF_FFFF_FFFF_FFFF;
                2: data_pattern = 64'hAAAA_AAAA_AAAA_AAAA;
                3: data_pattern = 64'h5555_5555_5555_5555;
                4: data_pattern = 64'h0123_4567_89AB_CDEF;
            endcase
            req = serializer_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                rst_n   == 1;
                load    == 1;
                Enable  == (i % 2 == 1);
                data_in == data_pattern;
            }) `uvm_fatal("SEQ", "Load randomization failed")
            finish_item(req);
            p_sequencer.seqr_aport.write(req);
        end
    endtask

    // 3) Load a word and serialize all 64 bits; also check extra shifts.
    //    Every 67 transactions: reset, load, then 65 shifts.
    task automatic test_full_serialization(int frames = 12);
        for (int i = 0; i < frames * (DATA_WIDTH + 3); i++) begin
            req = serializer_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                rst_n   == ((i % (DATA_WIDTH + 3)) != 0);
                load    == ((i % (DATA_WIDTH + 3)) == 1);
                Enable  == ((i % (DATA_WIDTH + 3)) >= 2);
                data_in == (64'h0123_4567_89AB_CDEF ^
                            (i / (DATA_WIDTH + 3)));
            }) `uvm_fatal("SEQ", "Full serialization randomization failed")
            finish_item(req);
            p_sequencer.seqr_aport.write(req);
        end
    endtask

    // 4) Walking-one: every bit position gets loaded and shifted.
    
    task automatic test_walking_one();
        for (int i = 0; i < DATA_WIDTH * (DATA_WIDTH + 1); i++) begin
            req = serializer_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                rst_n   == 1;
                load    == ((i % (DATA_WIDTH + 1)) == 0);
                Enable  == ((i % (DATA_WIDTH + 1)) != 0);
                data_in == (64'h1 << (i / (DATA_WIDTH + 1)));
            }) `uvm_fatal("SEQ", "Walking-one randomization failed")
            finish_item(req);
            p_sequencer.seqr_aport.write(req);
        end
    endtask

    // 5) Walking-zero: every bit position gets loaded and shifted.
    //    A load with Enable=0 covers <load_only, walking_zero>.
    task automatic test_walking_zero();
        for (int i = 0; i < DATA_WIDTH * (DATA_WIDTH + 1); i++) begin
            req = serializer_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                rst_n   == 1;
                load    == ((i % (DATA_WIDTH + 1)) == 0);
                Enable  == ((i % (DATA_WIDTH + 1)) != 0);
                data_in == ~(64'h1 << (i / (DATA_WIDTH + 1)));
            }) `uvm_fatal("SEQ", "Walking-zero randomization failed")
            finish_item(req);
            p_sequencer.seqr_aport.write(req);
        end
    endtask

    // 6) Idle after load, interrupt a word, and resume shifting.
    task automatic test_idle(int iterations = 16);
        for (int i = 0; i < iterations * 7; i++) begin
            req = serializer_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                rst_n   == 1;
                load    == (i % 7 == 0);
                Enable  == (i % 7 == 3 || i % 7 == 5);
                data_in == 64'h8000_0000_0000_0001;
            }) `uvm_fatal("SEQ", "Idle randomization failed")
            finish_item(req);
            p_sequencer.seqr_aport.write(req);
        end
    endtask

    // 7) All 8 reset/load/Enable combinations.
    task automatic test_control_combinations(int iterations = 32);
        for (int i = 0; i < iterations; i++) begin
            req = serializer_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                rst_n  == ((i / 4) % 2);
                load   == ((i / 2) % 2);
                Enable == (i % 2);
            }) `uvm_fatal("SEQ", "Control combinations randomization failed")
            finish_item(req);
            p_sequencer.seqr_aport.write(req);
        end
    endtask

    // 8) Reload mid-stream to interrupt an incomplete serialization.
    //    First cycle loads A; cycle 6 loads B; remaining cycles shift B.
    task automatic test_reload_mid_stream(int iterations = 20);
        for (int i = 0; i < iterations * (DATA_WIDTH + 6); i++) begin
            req = serializer_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                rst_n   == 1;
                load    == (i % (DATA_WIDTH + 6) == 0 ||
                            i % (DATA_WIDTH + 6) == 5);
                Enable  == (i % (DATA_WIDTH + 6) != 0);
                data_in == ((i % (DATA_WIDTH + 6) == 5) ?
                            64'hAAAA_AAAA_AAAA_AAAA :
                            64'h0123_4567_89AB_CDEF);
            }) `uvm_fatal("SEQ", "Reload randomization failed")
            finish_item(req);
            p_sequencer.seqr_aport.write(req);
        end
    endtask

    // 9) Shift beyond 64 bits and verify the output is zero.
    task automatic test_extra_shifts(int iterations = 5);
        for (int i = 0; i < iterations * (2 * DATA_WIDTH + 1); i++) begin
            req = serializer_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                rst_n   == 1;
                load    == (i % (2 * DATA_WIDTH + 1) == 0);
                Enable  == (i % (2 * DATA_WIDTH + 1) != 0);
                data_in == 64'hFFFF_FFFF_FFFF_FFFF;
            }) `uvm_fatal("SEQ", "Extra shifts randomization failed")
            finish_item(req);
            p_sequencer.seqr_aport.write(req);
        end
    endtask

    // 10) Randomized traffic with periodic reset.
    task automatic test_random_stress(int iterations = 1500);
        for (int i = 0; i < iterations; i++) begin
            req = serializer_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                rst_n == ((i % 151 == 150) ? 0 : 1);
                load dist   {0 := 70, 1 := 30};
                Enable dist {0 := 30, 1 := 70};
            }) `uvm_fatal("SEQ", "Random stress randomization failed")
            finish_item(req);
            p_sequencer.seqr_aport.write(req);
        end
    endtask
    
    task automatic test_load_enable_walking_patterns();

        for (int i = 0; i < 2; i++) begin

            req = serializer_sbtx_sequence_item::type_id::create("req");

            start_item(req);

            if (!req.randomize() with {
                rst_n  == 1;
                load   == 1;
                Enable == 1;
                data_in == ((i == 0) ?
                            64'h0000_0000_0000_0001 :
                            64'hFFFF_FFFF_FFFF_FFFE);
            })
                `uvm_fatal("SEQ", "Walking pattern randomization failed")

            finish_item(req);
            p_sequencer.seqr_aport.write(req);

        end

    endtask


    task body();
        test_reset();
        test_load();
        test_full_serialization();
        test_walking_one();
        test_walking_zero();
        test_idle();
        test_control_combinations();
        test_reload_mid_stream();
        test_extra_shifts();
        test_random_stress();
        test_load_enable_walking_patterns();

    endtask

endclass

`endif // SERIALIZER_SBTX_BASE_SEQUENCE_SVH
