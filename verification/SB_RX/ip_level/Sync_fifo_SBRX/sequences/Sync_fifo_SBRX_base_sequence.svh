`ifndef SYNC_FIFO_SBRX_BASE_SEQUENCE_SVH
`define SYNC_FIFO_SBRX_BASE_SEQUENCE_SVH

// =============================================================================
// Design Under Test: Sync_FIFO_SBRX (Single-Clock Synchronous FIFO)
// File Name        : Sync_fifo_SBRX_base_sequence.svh
// Description      : Complete verification sequence implementing all test cases
//                    from Sync_FIFO_SBRX_Verification_Plan.xlsx using existing
//                    helper methods only.
// =============================================================================

class Sync_fifo_SBRX_base_sequence extends uvm_sequence #(Sync_fifo_SBRX_sequence_item);
  `uvm_object_utils(Sync_fifo_SBRX_base_sequence)
  `uvm_declare_p_sequencer(Sync_fifo_SBRX_sequencer)

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------
  function new(string name = "Sync_fifo_SBRX_base_sequence");
    super.new(name);
  endfunction

  // ---------------------------------------------------------------------------
  // Sequence Body: Exhaustive Vplan Testflow (CAT_RST to CAT_RND)
  // ---------------------------------------------------------------------------
  virtual task body();
    logic [DATA_WIDTH:0] rand_data;
    int rand_burst_len;
    int rand_coin;

    `uvm_info(get_type_name(), "==================================================", UVM_LOW)
    `uvm_info(get_type_name(), "  STARTING COMPLETE SYNC_FIFO_SBRX VPLAN TESTFLOW ", UVM_LOW)
    `uvm_info(get_type_name(), "==================================================", UVM_LOW)

    // =========================================================================
    // CATEGORY 1: RESET & INITIALIZATION VERIFICATION (CAT_RST)
    // =========================================================================
    `uvm_info(get_type_name(), ">>> [CAT_RST] Starting Reset & Initialization Tests", UVM_LOW)

    // TC_RST_001: Power-On Asynchronous Reset Assertion & Deassertion
    reset_dut(5);
    idle(2);

    // TC_RST_002: Asynchronous Reset Assertion While Idle
    send_trans(.rst(1'b0), .wr(1'b0), .rd(1'b0), .data('0));
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b0), .data('0));
    idle(2);

    // TC_RST_003: Asynchronous Reset with Partially Occupied FIFO
    for (int i = 0; i < 16; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h100 + i));
    end
    reset_dut(3);
    idle(2);
    // Post-reset read attempt (should be rejected, FIFO empty)
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    idle(2);

    // TC_RST_004: Asynchronous Reset at Full Capacity
    for (int i = 0; i < FIFO_DEPTH; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h200 + i));
    end
    reset_dut(4);
    idle(2);

    // TC_RST_005: Asynchronous Reset During Active Write Request
    send_trans(.rst(1'b0), .wr(1'b1), .rd(1'b0), .data(65'hDEAD_BEEF));
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b0), .data('0));
    idle(2);

    // TC_RST_006: Asynchronous Reset During Active Read Request
    for (int i = 0; i < 8; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h300 + i));
    end
    send_trans(.rst(1'b0), .wr(1'b0), .rd(1'b1), .data('0));
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b0), .data('0));
    idle(2);

    // TC_RST_007: Narrow Asynchronous Reset Pulse Verification
    send_trans(.rst(1'b0), .wr(1'b0), .rd(1'b0), .data('0));
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b0), .data('0));
    idle(1);

    // TC_RST_008: Post-Reset Write and Read Recovery Cycle
    send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h400));
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    idle(3);

    // =========================================================================
    // CATEGORY 2: BASIC SINGLE & ALTERNATING ACCESS VERIFICATION (CAT_BAS)
    // =========================================================================
    `uvm_info(get_type_name(), ">>> [CAT_BAS] Starting Basic Single & Alternating Access Tests", UVM_LOW)

    // TC_BAS_001: Single Write Followed by Single Read
    send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h1_A5A5_5A5A_A5A5_5A5A));
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    idle(2);

    // TC_BAS_002: Read Data Output Hold During Subsequent Idle Cycles
    send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h1_1234_5678_9ABC_DEF0));
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    idle(20);

    // TC_BAS_003: Consecutive Back-to-Back Single Write-Read Pairs (Ping-Pong)
    for (int i = 0; i < 32; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'hA000 + i));
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    end
    idle(2);

    // TC_BAS_004: Short Burst Write Followed by Short Burst Read
    for (int i = 0; i < 4; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'hB000 + i));
    end
    for (int i = 0; i < 4; i++) begin
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    end
    idle(2);

    // TC_BAS_005: Zero-Operation Idle Cycles Verification
    idle(10);

    // =========================================================================
    // CATEGORY 3: FIFO ORDERING & DATA INTEGRITY VERIFICATION (CAT_ORD)
    // =========================================================================
    `uvm_info(get_type_name(), ">>> [CAT_ORD] Starting FIFO Ordering & Data Integrity Tests", UVM_LOW)

    // TC_ORD_001: Full Depth In-Order Sequencing Verification (64 unique entries)
    for (int i = 0; i < FIFO_DEPTH; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h1_0000_0000_0000_0000 | i));
    end
    for (int i = 0; i < FIFO_DEPTH; i++) begin
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    end
    idle(2);

    // TC_ORD_002: Random Payload Ordering Against Golden Queue
    for (int i = 0; i < FIFO_DEPTH; i++) begin
      void'(std::randomize(rand_data));
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(rand_data));
    end
    for (int i = 0; i < FIFO_DEPTH; i++) begin
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    end
    idle(2);

    // TC_ORD_003: Extended Idle Data Retention & Storage Stability (50 idle cycles)
    for (int i = 0; i < 32; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'hC000 + i));
    end
    idle(50);
    for (int i = 0; i < 32; i++) begin
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    end
    idle(2);

    // TC_ORD_004: 65-Bit Data Bus Full-Width Integrity ([DATA_WIDTH:0])
    send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h1_0000_0000_0000_0000));
    send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h0_FFFF_FFFF_FFFF_FFFF));
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    idle(2);

    // TC_ORD_005: Variable Latency Read Extraction
    for (int i = 0; i < 16; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'hC500 + i));
    end
    for (int i = 0; i < 16; i++) begin
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
      idle((i % 4) + 1);
    end
    idle(2);

    // =========================================================================
    // CATEGORY 4: FIFO FULL & OVERFLOW HANDLING VERIFICATION (CAT_FUL)
    // =========================================================================
    `uvm_info(get_type_name(), ">>> [CAT_FUL] Starting Full & Overflow Handling Tests", UVM_LOW)

    // TC_FUL_002: Almost Full to Full Boundary Transition (Occupancy 63 to 64)
    for (int i = 0; i < FIFO_DEPTH - 1; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'hD000 + i));
    end
    idle(1);
    // TC_FUL_001: Fill to Exact Maximum Capacity (64th entry)
    send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'hD03F));
    idle(1);

    // TC_FUL_003: Single Write Overflow Attempt While Full
    send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h1_DEAD_BEEF_DEAD_BEEF));
    idle(1);

    // TC_FUL_004: Sustained Multi-Cycle Overflow Stress (32 cycles)
    for (int i = 0; i < 32; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'hDEAD_0000 | i));
    end
    idle(2);

    // TC_FUL_006: Randomized Overflow Data Stress
    for (int i = 0; i < 16; i++) begin
      void'(std::randomize(rand_data));
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(rand_data));
    end
    idle(2);

    // TC_FUL_005: Post-Overflow Data Integrity & Drain Verification
    for (int i = 0; i < FIFO_DEPTH; i++) begin
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    end
    idle(3);

    // =========================================================================
    // CATEGORY 5: FIFO EMPTY & UNDERFLOW HANDLING VERIFICATION (CAT_EMP)
    // =========================================================================
    `uvm_info(get_type_name(), ">>> [CAT_EMP] Starting Empty & Underflow Handling Tests", UVM_LOW)

    // TC_EMP_001: Drain FIFO from Full to Empty (already executed, currently empty)
    // TC_EMP_003: Single Read Underflow Attempt from Reset/Empty State
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    idle(1);

    // TC_EMP_004: Read Underflow with Prior Valid Data (rd_data Holding Check)
    send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h0_CAFE_BABE_1234_5678));
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0)); // reads out known word
    // Underflow read attempt: rd_data must hold previous value
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    idle(3);

    // TC_EMP_005: Sustained Multi-Cycle Underflow Stress (32 cycles)
    for (int i = 0; i < 32; i++) begin
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    end
    idle(2);

    // TC_EMP_006: Immediate Write Recovery Following Underflow Stress
    send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'hE001));
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    idle(2);

    // TC_EMP_002: Almost Empty to Empty Boundary Transition (Occupancy 1 to 0)
    send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'hE002));
    idle(1);
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    idle(3);

    // =========================================================================
    // CATEGORY 6: SIMULTANEOUS READ & WRITE OPERATIONS (CAT_SRW)
    // =========================================================================
    `uvm_info(get_type_name(), ">>> [CAT_SRW] Starting Simultaneous Read & Write Tests", UVM_LOW)

    // Pre-fill FIFO to occupancy = 16
    for (int i = 0; i < 16; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'hF000 + i));
    end
    // TC_SRW_001: Simultaneous Read/Write at Mid-Occupancy (Single Cycle)
    write_read(65'hF010);
    write_read(65'hF011);

    // TC_SRW_002: Continuous Streaming Simultaneous Read/Write (64 cycles)
    for (int i = 0; i < 64; i++) begin
      write_read(65'hF100 + i);
    end
    // Drain remaining 16 entries
    for (int i = 0; i < 16; i++) begin
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    end
    idle(2);

    // TC_SRW_003: Simultaneous Read/Write at Occupancy = 1
    send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'hF200));
    write_read(65'hF201);
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    idle(2);

    // TC_SRW_004: Simultaneous Read/Write at Occupancy = FIFO_DEPTH - 1 (63)
    for (int i = 0; i < FIFO_DEPTH - 1; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'hF300 + i));
    end
    write_read(65'hF33F);
    for (int i = 0; i < FIFO_DEPTH - 1; i++) begin
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    end
    idle(2);

    // TC_SRW_005: Random Simultaneous Read/Write Across Arbitrary Occupancies
    for (int i = 0; i < 20; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'hF400 + i));
    end
    for (int i = 0; i < 30; i++) begin
      void'(std::randomize(rand_data));
      write_read(rand_data);
    end
    for (int i = 0; i < 20; i++) begin
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    end
    idle(3);

    // =========================================================================
    // CATEGORY 7: BOUNDARY TRANSITIONS & CORNER CASE VERIFICATION (CAT_BND)
    // =========================================================================
    `uvm_info(get_type_name(), ">>> [CAT_BND] Starting Boundary Corner Case Tests", UVM_LOW)

    // TC_BND_001: Simultaneous Read/Write on EMPTY Boundary (Read rejected, Write accepted)
    write_read(65'hB00D_0001);
    // TC_BND_005: Simultaneous Read/Write Boundary State Recovery
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    idle(2);

    // TC_BND_002: Simultaneous Read/Write on FULL Boundary (Write rejected, Read accepted)
    for (int i = 0; i < FIFO_DEPTH; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h5000 + i));
    end
    write_read(65'hBEEF_DEAD_0001);
    // TC_COV_SIM_RW_FULL: Explicit sim_rw_at_full coverage — wr=1,rd=1 while full=1.
    // The FIFO is still full after the first write_read (wr was rejected, rd accepted =>
    // occupancy = 63; fill back up then do more simultaneous RW while full).
    for (int i = 0; i < FIFO_DEPTH; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h5A00 + i));
    end
    // Now full=1; issue 5 simultaneous RW cycles: wr rejected, rd accepted each time
    repeat(5) write_read(65'hDEAD_C0DE);
    // TC_BND_006: Full Boundary Rejected Write Non-Pollution Verification
    for (int i = 0; i < FIFO_DEPTH - 5; i++) begin
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    end
    idle(2);

    // TC_BND_003: Empty Boundary Thrash (Rapid 0 <-> 1 Occupancy Oscillation)
    for (int i = 0; i < 30; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h6000 + i));
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    end
    idle(2);

    // TC_BND_004: Full Boundary Thrash (Rapid 63 <-> 64 Occupancy Oscillation)
    for (int i = 0; i < FIFO_DEPTH - 1; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h7000 + i));
    end
    for (int i = 0; i < 30; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h7100 + i));
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    end
    for (int i = 0; i < FIFO_DEPTH - 1; i++) begin
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    end
    idle(3);

    // =========================================================================
    // CATEGORY 8: DATA PATTERNS & WIDTH STRESS VERIFICATION (CAT_DAT)
    // =========================================================================
    `uvm_info(get_type_name(), ">>> [CAT_DAT] Starting Data Patterns & Width Stress Tests", UVM_LOW)

      send_trans(.rst(1'b0), .wr(1'b0), .rd(1'b1), .data('0));
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));

    // TC_DAT_001: All-Zeros Data Pattern Across Full 65-Bit Width
    send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h0));
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));

    // TC_DAT_002: All-Ones Data Pattern Across Full 65-Bit Width
    send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h1_FFFF_FFFF_FFFF_FFFF));
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));

    // TC_DAT_003: Alternating Bit Patterns (Checkerboard 0xAA / 0x55)
    // Write 4 copies of each pattern (8 entries) so FIFO has multiple items;
    // rd_data will cycle through 0xAAAA and 0x5555 while !empty is still true.
    repeat(4) send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h0_AAAA_AAAA_AAAA_AAAA));
    repeat(4) send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h1_5555_5555_5555_5555));
    // Read all 8 back out; at cycle 1..7 !empty is true so coverage fires
    repeat(8) send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    idle(2);

    // TC_DAT_004: Walking-Ones Pattern Across All 65 Bits
    for (int i = 0; i <= DATA_WIDTH; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(65'h1 << i));
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    end

    // TC_DAT_005: Walking-Zeros Pattern Across All 65 Bits
    for (int i = 0; i <= DATA_WIDTH; i++) begin
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(~(65'h1 << i)));
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    end

    // TC_DAT_006: Pseudo-Random Data Distribution Stress
    for (int i = 0; i < 64; i++) begin
      void'(std::randomize(rand_data));
      send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(rand_data));
    end
    for (int i = 0; i < 64; i++) begin
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    end
    idle(3);

    // =========================================================================
    // CATEGORY 9: RANDOMIZED TRAFFIC & EXTENDED STRESS VERIFICATION (CAT_RND)
    // =========================================================================
    `uvm_info(get_type_name(), ">>> [CAT_RND] Starting Randomized Traffic & Stress Tests", UVM_LOW)

    // TC_RND_001: Balanced Randomized Traffic (P(wr)=0.5, P(rd)=0.5)
    repeat (1000) begin
      send_rand_trans();
    end

    // TC_RND_002: Write-Heavy Randomized Traffic (85% write probability)
    repeat (150) begin
      rand_coin = $urandom_range(1, 100);
      void'(std::randomize(rand_data));
      if (rand_coin <= 85) begin
        send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(rand_data));
      end else begin
        send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
      end
    end

    // TC_RND_003: Read-Heavy Randomized Traffic (85% read probability)
    repeat (150) begin
      rand_coin = $urandom_range(1, 100);
      void'(std::randomize(rand_data));
      if (rand_coin <= 85) begin
        send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
      end else begin
        send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(rand_data));
      end
    end

    // TC_RND_004: Random Bursty Producer / Consumer Traffic
    for (int b = 0; b < 10; b++) begin
      rand_burst_len = $urandom_range(1, 32);
      for (int i = 0; i < rand_burst_len; i++) begin
        void'(std::randomize(rand_data));
        send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b0), .data(rand_data));
      end
      idle($urandom_range(1, 4));
      for (int i = 0; i < rand_burst_len; i++) begin
        send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
      end
      idle($urandom_range(1, 4));
    end

    // TC_RND_005: Long-Duration Extended Stress & Pointer Wraparound Test
    repeat (300) begin
      send_rand_trans();
    end

    // TC_RND_006: Randomized Traffic with Asynchronous Reset Injection
    repeat (40) begin
      send_rand_trans();
    end
    reset_dut(3);
    idle(2);
    // Resume traffic after reset injection
    repeat (40) begin
      send_rand_trans();
    end

    // Drain remaining entries and finish with clean idle
    for (int i = 0; i < FIFO_DEPTH; i++) begin
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b1), .data('0));
    end
    idle(10);

    `uvm_info(get_type_name(), "==================================================", UVM_LOW)
    `uvm_info(get_type_name(), "  COMPLETED ALL VPLAN TEST CASES SUCCESSFULLY!    ", UVM_LOW)
    `uvm_info(get_type_name(), "==================================================", UVM_LOW)
  endtask

  // ===========================================================================
  // Basic Transaction Helper Methods (Preserved Exactly)
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // Task: send_trans
  // ---------------------------------------------------------------------------
  task send_trans(input logic rst = 1'b1,
                  input logic wr  = 1'b0,
                  input logic rd  = 1'b0,
                  input logic [DATA_WIDTH:0] data = '0);
    req = Sync_fifo_SBRX_sequence_item::type_id::create("req");
    start_item(req);
    req.sys_rst = rst;
    req.wr_en   = wr;
    req.rd_en   = rd;
    req.wr_data = data;

    if (p_sequencer != null) begin
      p_sequencer.seqr_aport.write(req);
    end

    finish_item(req);
  endtask

  // ---------------------------------------------------------------------------
  // Task: send_rand_trans
  // ---------------------------------------------------------------------------
  task send_rand_trans();
    req = Sync_fifo_SBRX_sequence_item::type_id::create("req");
    start_item(req);
    if (!req.randomize()) begin
      `uvm_error("BASE_SEQ", "Randomization failed for sequence item")
    end

    if (p_sequencer != null) begin
      p_sequencer.seqr_aport.write(req);
    end

    finish_item(req);
  endtask

  // ---------------------------------------------------------------------------
  // Task: reset_dut
  // ---------------------------------------------------------------------------
  task reset_dut(input int unsigned cycles = 5);
    repeat (cycles) begin
      send_trans(.rst(1'b0), .wr(1'b0), .rd(1'b0), .data('0));
    end
    // Deassert reset to idle active state
    send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b0), .data('0));
  endtask

  // ---------------------------------------------------------------------------
  // Task: write_read
  // ---------------------------------------------------------------------------
  task write_read(input logic [DATA_WIDTH:0] data);
    send_trans(.rst(1'b1), .wr(1'b1), .rd(1'b1), .data(data));
  endtask

  // ---------------------------------------------------------------------------
  // Task: idle
  // ---------------------------------------------------------------------------
  task idle(input int unsigned cycles = 1);
    repeat (cycles) begin
      send_trans(.rst(1'b1), .wr(1'b0), .rd(1'b0), .data('0));
    end
  endtask

endclass

`endif // SYNC_FIFO_SBRX_BASE_SEQUENCE_SVH
