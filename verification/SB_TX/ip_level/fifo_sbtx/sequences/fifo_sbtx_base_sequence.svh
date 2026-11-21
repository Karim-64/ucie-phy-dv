`ifndef FIFO_SBTX_BASE_SEQUENCE_SVH
`define FIFO_SBTX_BASE_SEQUENCE_SVH

class fifo_sbtx_base_sequence extends uvm_sequence #(fifo_sbtx_sequence_item);
    `uvm_object_utils(fifo_sbtx_base_sequence)
    `uvm_declare_p_sequencer(fifo_sbtx_sequencer)

    // Matches the default FIFO_SBTX RTL parameter.
    // Change for tests compiled with another FIFO_DEPTH.
    localparam int FIFO_DEPTH = 64;

    function new(string name = "fifo_sbtx_base_sequence");
        super.new(name);
    endfunction

    // 1) Reset, including reset while the FIFO is in use.
    task automatic test_reset(int iterations = 12);
        for (int i = 0; i < iterations; i++) begin
            req = fifo_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                rst_n == 0;
                wr_en == (i % 4 == 1);
                rd_en == (i % 4 == 2);
                UIE == 0;
                Reg_Acc_Marker == 0;
                Req_Resp_Marker == 0;
            }) `uvm_fatal("SEQ", "Reset randomization failed")
            finish_item(req);
            p_sequencer.seqr_aport.write(req);
        end
    endtask

    // 2) Write repeatedly
    task automatic test_write(int iterations = 70);
        test_reset(1);
        for (int i = 0; i < iterations; i++) begin
            req = fifo_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                rst_n == 1;
                wr_en == 1;
                rd_en == 0;
                UIE == 0;
                Reg_Acc_Marker == 0;
                Req_Resp_Marker == 0;
            }) `uvm_fatal("SEQ", "Write/UIE randomization failed")
            finish_item(req);
            p_sequencer.seqr_aport.write(req);
        end
    endtask


    // 3) Empty reads, normal writes, valid reads, extra empty reads.
    task automatic test_read(int iterations =66);
       
        for (int i = 0; i <iterations; i++) begin
            req = fifo_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                rst_n == 1;
                wr_en == (i < iterations/2);
                rd_en == (i >= iterations/2);
                UIE == 0;
                Reg_Acc_Marker == 0;
                Req_Resp_Marker == 0;
            }) `uvm_fatal("SEQ", "Read randomization failed")
            finish_item(req);
            p_sequencer.seqr_aport.write(req);
        end
    endtask

    // 4) Full, overflow attempts, drain, and pointer wraparound. //=================== bug in RTL===================
    task automatic test_capacity_wraparound(int write_iterations = 66, int read_iterations = 66);
         for (int i = 0; i < write_iterations; i++) begin
            req = fifo_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                rst_n == 1;
                wr_en == 1;
                rd_en == 0;
                UIE == 0;
                Reg_Acc_Marker == 0;
                Req_Resp_Marker == 0;
            }) `uvm_fatal("SEQ", "Write/UIE randomization failed")
            finish_item(req);
            p_sequencer.seqr_aport.write(req);
        end
          for (int i = 0; i <read_iterations; i++) begin
            req = fifo_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                rst_n == 1;
                wr_en == 0;
                rd_en == 1;
                UIE == 0;
                Reg_Acc_Marker == 0;
                Req_Resp_Marker == 0;
            }) `uvm_fatal("SEQ", "Read randomization failed")
            finish_item(req);
            p_sequencer.seqr_aport.write(req);
        end

    endtask
    
task automatic test_write_overwrite();

    test_reset(1);

    // Phase 0: Write marker values = 1
    // Phase 1: Overwrite same addresses with marker values = 0

    for (int phase = 0; phase < 2; phase++) begin

        // Fill all 64 physical FIFO addresses
        for (int i = 0; i < FIFO_DEPTH; i++) begin

            req = fifo_sbtx_sequence_item::type_id::create("req");
            start_item(req);

            if (!req.randomize() with {

                rst_n == 1;
                wr_en == 1;
                rd_en == 0;
                UIE == 0;

                Data_Marker == (phase == 0);
                Reg_Acc_Marker == (phase == 0);
                Reg_Acc_Data_Marker == (phase == 0);
                Comp_Marker == (phase == 0);

                Req_Resp_Marker == 0;

            })
                `uvm_fatal("SEQ", "Toggle write randomization failed")

            finish_item(req);
            p_sequencer.seqr_aport.write(req);

        end

        // Drain all 64 entries to allow pointer wraparound
        for (int i = 0; i < FIFO_DEPTH; i++) begin

            req = fifo_sbtx_sequence_item::type_id::create("req");
            start_item(req);

            if (!req.randomize() with {

                rst_n == 1;
                wr_en == 0;
                rd_en == 1;
                UIE == 0;

                Reg_Acc_Marker == 0;
                Req_Resp_Marker == 0;

            })
                `uvm_fatal("SEQ", "Toggle read randomization failed")

            finish_item(req);
            p_sequencer.seqr_aport.write(req);

        end

    end

    test_reset(1);

endtask

    
    // 5) Simultaneous write/read
    task automatic test_simultaneous(int iterations =150);
        test_reset(1);
        for (int i = 0; i < iterations ; i++) begin
            req = fifo_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                rst_n dist{0:=10, 1:=90};
                wr_en == 1;
                rd_en == 1;
                UIE == 0;
                Reg_Acc_Marker == 0;
                Req_Resp_Marker == 0;
            }) `uvm_fatal("SEQ", "Simultaneous randomization failed")
            finish_item(req);
            p_sequencer.seqr_aport.write(req);
        end
    endtask
     // 6) Simultaneous write/read with UIE            //=================== bug in RTL===================
    task automatic test_simultaneous_UIE(int iterations =10);
        test_reset(1);
        for (int i = 0; i < iterations ; i++) begin
            req = fifo_sbtx_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                rst_n == 1;
                wr_en == 1;
                rd_en == 1;
                UIE == 1;
                Reg_Acc_Marker == 0;
                Req_Resp_Marker == 0;
            }) `uvm_fatal("SEQ", "Simultaneous randomization failed")
            finish_item(req);
            p_sequencer.seqr_aport.write(req);
        end
    endtask

    // 7) Write RAR, then 1-3 ordinary messages, then Req/Resp.
    // Read continuously to expose a duplicated priority message. // =================== bug in RTL===================
  task automatic test_priority(int iterations = 12);

    test_reset(1);

    for (int i = 0; i < iterations; i++) begin

        req = fifo_sbtx_sequence_item::type_id::create("req");

        start_item(req);

        if (!req.randomize() with {
            rst_n == 1;
            wr_en == (i < iterations/2);
            rd_en == (i >= iterations/2);
            UIE == 0;
            Reg_Acc_Marker == (i == 0);
            Req_Resp_Marker == (i == iterations/2 - 1);
        })
            `uvm_fatal("SEQ", "Priority randomization failed")

        finish_item(req);
        p_sequencer.seqr_aport.write(req);

    end

endtask
    
   
    // 10) Fully randomized traffic with periodic reset.
   
task automatic test_random_stress(int iterations = 1000);

    test_reset(1);

    for (int i = 0; i < iterations; i++) begin

        req = fifo_sbtx_sequence_item::type_id::create("req");

        start_item(req);

        if (!req.randomize() with {

            rst_n == ((i % 150 == 149) ? 0 : 1);

            // Temporarily disable priority behavior
            // Reg_Acc_Marker == 0;
             Req_Resp_Marker dist{0:=90, 1:=10};
            
        })
            `uvm_fatal("SEQ", "Stress randomization failed")

        finish_item(req);

        p_sequencer.seqr_aport.write(req);

    end

endtask
    




    task body();
         test_reset();
         test_write();
         test_capacity_wraparound();
         test_read();
        test_simultaneous();
        test_simultaneous_UIE();
         test_priority();
         test_write_overwrite();
      test_random_stress();
      

    endtask

endclass

`endif // FIFO_SBTX_BASE_SEQUENCE_SVH
